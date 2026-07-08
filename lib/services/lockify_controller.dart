import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/unlock_session.dart';
import 'restriction_bridge.dart';

class LockifyController extends ChangeNotifier {
  LockifyController({
    required SharedPreferences prefs,
    RestrictionBridge? restrictionBridge,
  })  : _prefs = prefs,
        _restrictionBridge = restrictionBridge ?? NoopRestrictionBridge();

  static const _historyKey = 'lockify.unlock.history';
  static const _activeSessionKey = 'lockify.active.session';
  static const _lastResetDayKey = 'lockify.last.reset.day';

  final SharedPreferences _prefs;
  final RestrictionBridge _restrictionBridge;

  UnlockSession? _activeSession;
  final List<UnlockSession> _history = <UnlockSession>[];

  UnlockSession? get activeSession => _activeSession;
  List<UnlockSession> get history => List.unmodifiable(_history);
  bool get isLocked => _activeSession == null;

  int get remainingSeconds {
    final session = _activeSession;
    if (session == null) return 0;
    return max(0, session.endsAt.difference(DateTime.now()).inSeconds);
  }

  Future<void> initialize() async {
    _loadState();
    await _performDailyResetIfNeeded();
    await _refreshActiveSessionState();
    notifyListeners();
  }

  int calculateUnlockMinutes(int estimatedWorkMinutes) {
    final safeEstimate = max(1, estimatedWorkMinutes);
    final baseGrant = (safeEstimate * 0.75).floor();
    return baseGrant.clamp(5, 120);
  }

  Future<void> submitProof({
    required String proofType,
    required String details,
    required int estimatedWorkMinutes,
  }) async {
    await _performDailyResetIfNeeded();

    final unlockMinutes = calculateUnlockMinutes(estimatedWorkMinutes);
    final now = DateTime.now();
    final summary = details.trim().isEmpty ? 'No details' : details.trim();

    final session = UnlockSession(
      id: now.microsecondsSinceEpoch.toString(),
      startedAt: now,
      endsAt: now.add(Duration(minutes: unlockMinutes)),
      unlockedMinutes: unlockMinutes,
      proofSummary: '$proofType: $summary',
    );

    _activeSession = session;
    _history.insert(0, session);
    await _saveState();
    await _restrictionBridge.beginUnlockSession(session.endsAt);
    notifyListeners();
  }

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

  void _loadState() {
    final historyJson = _prefs.getString(_historyKey);
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      _history
        ..clear()
        ..addAll(decoded
            .map((entry) => UnlockSession.fromJson(entry as Map<String, dynamic>))
            .toList());
    }

    final sessionJson = _prefs.getString(_activeSessionKey);
    if (sessionJson != null) {
      _activeSession = UnlockSession.fromJson(
        jsonDecode(sessionJson) as Map<String, dynamic>,
      );
    }
  }

  Future<void> _refreshActiveSessionState() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    if (!session.isActive) {
      _activeSession = null;
      await _saveState();
      await _restrictionBridge.endUnlockSession();
    }
  }

  Future<void> _performDailyResetIfNeeded() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final lastReset = _prefs.getString(_lastResetDayKey);

    if (lastReset == today) {
      return;
    }

    await _prefs.setString(_lastResetDayKey, today);
    if (_activeSession != null) {
      _activeSession = null;
      await _restrictionBridge.endUnlockSession();
    }

    await _saveState();
  }

  Future<void> _saveState() async {
    await _prefs.setString(
      _historyKey,
      jsonEncode(_history.map((entry) => entry.toJson()).toList()),
    );

    final active = _activeSession;
    if (active == null) {
      await _prefs.remove(_activeSessionKey);
      return;
    }

    await _prefs.setString(_activeSessionKey, jsonEncode(active.toJson()));
  }
}
