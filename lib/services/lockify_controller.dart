import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/unlock_session.dart';
import '../models/work_session.dart';
import 'restriction_bridge.dart';

class LockifyController extends ChangeNotifier {
  LockifyController({
    required SharedPreferences prefs,
    RestrictionBridge? restrictionBridge,
  })  : _prefs = prefs,
        _restrictionBridge = restrictionBridge ?? NoopRestrictionBridge();

  // ── Storage keys ────────────────────────────────────────────────────────────
  static const _historyKey          = 'lockify.unlock.history';
  static const _activeSessionKey    = 'lockify.active.session';
  static const _activeWorkSessionKey= 'lockify.active.work.session';
  static const _lastResetDayKey     = 'lockify.last.reset.day';
  static const _bankedMinutesKey    = 'lockify.banked.minutes';

  /// How many minutes of rest are earned per 30 minutes of work.
  static const int restMinutesPerHalfHour = 5;

  final SharedPreferences _prefs;
  final RestrictionBridge _restrictionBridge;

  UnlockSession? _activeSession;
  WorkSession?   _activeWorkSession;
  final List<UnlockSession> _history = <UnlockSession>[];

  /// Accumulated rest minutes the user has earned but not yet spent.
  int _bankedMinutes = 0;

  // ── Public getters ──────────────────────────────────────────────────────────

  UnlockSession?       get activeSession     => _activeSession;
  WorkSession?         get activeWorkSession => _activeWorkSession;
  List<UnlockSession>  get history           => List.unmodifiable(_history);
  bool                 get isLocked          => _activeSession == null;
  bool                 get isWorking         => _activeWorkSession != null;

  /// Minutes currently banked (earned but not yet spent).
  int get bankedMinutes => _bankedMinutes;

  int get remainingSeconds {
    final session = _activeSession;
    if (session == null) return 0;
    return max(0, session.endsAt.difference(DateTime.now()).inSeconds);
  }

  int get workElapsedSeconds {
    final session = _activeWorkSession;
    if (session == null) return 0;
    return session.elapsedSeconds;
  }

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _loadState();
    await _performDailyResetIfNeeded();
    await _refreshActiveSessionState();
    if (_activeSession == null) {
      await _restrictionBridge.endUnlockSession(); // starts blocking
    }
    notifyListeners();
  }

  // ── Time currency ────────────────────────────────────────────────────────────

  /// Converts raw work minutes into earnable rest minutes.
  /// Formula: 30 min work → 5 min rest (linear, no quality multiplier).
  int earnedMinutesFor(int workMinutes) {
    if (workMinutes <= 0) return 0;
    // Scale: each 30-minute block earns restMinutesPerHalfHour rest minutes.
    return ((workMinutes / 30) * restMinutesPerHalfHour).floor();
  }

  /// Preview how many minutes would be added to the bank for [workMinutes].
  int previewEarnings(int workMinutes) => earnedMinutesFor(workMinutes);

  /// Spend [minutes] from the bank to start an unlock session.
  /// Returns false if there aren't enough banked minutes.
  Future<bool> spendMinutes(int minutes) async {
    if (minutes <= 0 || minutes > _bankedMinutes) return false;

    final now = DateTime.now();
    final session = UnlockSession(
      id: now.microsecondsSinceEpoch.toString(),
      startedAt: now,
      endsAt: now.add(Duration(minutes: minutes)),
      unlockedMinutes: minutes,
      proofSummary: 'Spent from bank',
      workMinutes: 0,
      qualityScore: 100,
    );

    _bankedMinutes -= minutes;
    _activeSession = session;
    _history.insert(0, session);
    await _saveState();
    await _restrictionBridge.beginUnlockSession(session.endsAt);
    notifyListeners();
    return true;
  }

  // ── Work session ─────────────────────────────────────────────────────────────

  Future<void> startWorkSession({int goalMinutes = 30}) async {
    await _performDailyResetIfNeeded();
    _activeWorkSession = WorkSession(
      startedAt: DateTime.now(),
      goalMinutes: goalMinutes.clamp(5, 240).toInt(),
    );
    await _saveState();
    notifyListeners();
  }

  Future<void> cancelWorkSession() async {
    _activeWorkSession = null;
    await _saveState();
    notifyListeners();
  }

  Future<void> submitProof({
    required String proofType,
    required String details,
    required int estimatedWorkMinutes,
  }) async {
    await _performDailyResetIfNeeded();

    final workMinutes = max(
      _activeWorkSession?.elapsedMinutes ?? 1,
      estimatedWorkMinutes,
    );

    // Bank the earned minutes — don't auto-unlock.
    final earned = earnedMinutesFor(workMinutes);
    _bankedMinutes += earned;

    final now = DateTime.now();
    final summary = details.trim().isEmpty ? 'No details' : details.trim();

    // Record in history (unlockedMinutes = 0 because no session started yet).
    final record = UnlockSession(
      id: now.microsecondsSinceEpoch.toString(),
      startedAt: now,
      endsAt: now, // no unlock window — just a record
      unlockedMinutes: 0,
      proofSummary: '$proofType: $summary',
      workMinutes: workMinutes,
      qualityScore: earned,
    );

    _activeWorkSession = null;
    _history.insert(0, record);
    await _saveState();
    notifyListeners();
  }

  // ── Tick / lock ───────────────────────────────────────────────────────────────

  Future<void> tick() async {
    await _performDailyResetIfNeeded();
    await _refreshActiveSessionState();
    notifyListeners();
  }

  Future<void> lockNow() async {
    _activeSession = null;
    await _saveState();
    await _restrictionBridge.endUnlockSession();
    notifyListeners();
  }

  // ── Backwards-compat helper used by ProofSubmissionView preview ──────────────

  /// Still exposed so ProofSubmissionView can show a preview label.
  /// Now returns earned minutes rather than an unlock grant.
  int calculateUnlockMinutes(int workMinutes, {int qualityScore = 75}) {
    return earnedMinutesFor(workMinutes);
  }

  // ── Private ───────────────────────────────────────────────────────────────────

  void _loadState() {
    final historyJson = _prefs.getString(_historyKey);
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      _history
        ..clear()
        ..addAll(
          decoded.map((e) => UnlockSession.fromJson(e as Map<String, dynamic>)),
        );
    }

    final sessionJson = _prefs.getString(_activeSessionKey);
    if (sessionJson != null) {
      _activeSession = UnlockSession.fromJson(
        jsonDecode(sessionJson) as Map<String, dynamic>,
      );
    }

    final workSessionJson = _prefs.getString(_activeWorkSessionKey);
    if (workSessionJson != null) {
      _activeWorkSession = WorkSession.fromJson(
        jsonDecode(workSessionJson) as Map<String, dynamic>,
      );
    }

    _bankedMinutes = _prefs.getInt(_bankedMinutesKey) ?? 0;
  }

  Future<void> _refreshActiveSessionState() async {
    final session = _activeSession;
    if (session == null) return;
    if (!session.isActive) {
      _activeSession = null;
      await _saveState();
      await _restrictionBridge.endUnlockSession();
    }
  }

  Future<void> _performDailyResetIfNeeded() async {
    final now   = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final last  = _prefs.getString(_lastResetDayKey);
    if (last == today) return;

    await _prefs.setString(_lastResetDayKey, today);
    _activeWorkSession = null;
    // Banked minutes carry over — they don't reset daily.
    if (_activeSession != null) {
      _activeSession = null;
      await _restrictionBridge.endUnlockSession();
    }
    await _saveState();
  }

  Future<void> _saveState() async {
    await _prefs.setString(
      _historyKey,
      jsonEncode(_history.map((e) => e.toJson()).toList()),
    );
    await _prefs.setInt(_bankedMinutesKey, _bankedMinutes);

    final active = _activeSession;
    if (active == null) {
      await _prefs.remove(_activeSessionKey);
    } else {
      await _prefs.setString(_activeSessionKey, jsonEncode(active.toJson()));
    }

    final work = _activeWorkSession;
    if (work == null) {
      await _prefs.remove(_activeWorkSessionKey);
    } else {
      await _prefs.setString(_activeWorkSessionKey, jsonEncode(work.toJson()));
    }
  }
}
