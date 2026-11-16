import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/android_restriction_bridge.dart';
import 'services/lockify_controller.dart';
import 'views/history_view.dart';
import 'views/locked_home_view.dart';
import 'views/permission_gate_view.dart';
import 'views/proof_submission_view.dart';
import 'views/unlock_session_view.dart';
import 'views/work_session_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LockifyBootstrap());
}

class LockifyBootstrap extends StatelessWidget {
  const LockifyBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lockify',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: FutureBuilder<LockifyController>(
        future: _createController(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Lockify could not start. Please restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final controller = snapshot.data;
          if (controller == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return _PermissionWrapper(controller: controller);
        },
      ),
    );
  }

  Future<LockifyController> _createController() async {
    final prefs = await SharedPreferences.getInstance();

    // Use the real Android bridge on Android, no-op everywhere else.
    final bridge =
        Platform.isAndroid ? AndroidRestrictionBridge() : null;

    final controller = LockifyController(
      prefs: prefs,
      restrictionBridge: bridge,
    );
    await controller.initialize();
    return controller;
  }
}

/// Checks permissions before showing the main app.
/// On non-Android platforms it skips straight to the app.
class _PermissionWrapper extends StatefulWidget {
  const _PermissionWrapper({required this.controller});

  final LockifyController controller;

  @override
  State<_PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<_PermissionWrapper> {
  // null = still checking, true = granted, false = needs granting
  bool? _permissionsGranted;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) {
      setState(() => _permissionsGranted = true);
      return;
    }

    final granted = await AndroidRestrictionBridge.hasAllPermissions();
    if (mounted) setState(() => _permissionsGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final granted = _permissionsGranted;

    if (granted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!granted) {
      return PermissionGateView(
        onPermissionsGranted: () {
          if (mounted) setState(() => _permissionsGranted = true);
        },
      );
    }

    return LockifyHome(controller: widget.controller);
  }
}

class LockifyHome extends StatefulWidget {
  const LockifyHome({required this.controller, super.key});

  final LockifyController controller;

  @override
  State<LockifyHome> createState() => _LockifyHomeState();
}

class _LockifyHomeState extends State<LockifyHome> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      widget.controller.tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openProofSubmission() async {
    final workSession = widget.controller.activeWorkSession;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProofSubmissionView(
          initialEstimateMinutes: workSession?.elapsedMinutes ?? 30,
          predictedUnlockFor: widget.controller.calculateUnlockMinutes,
          onSubmit: (data) => widget.controller.submitProof(
            proofType: data.proofType,
            details: data.proofDetails,
            estimatedWorkMinutes: data.estimatedWorkMinutes,
          ),
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryView(sessions: widget.controller.history),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = widget.controller.activeSession;
    final activeWorkSession = widget.controller.activeWorkSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lockify'),
        actions: <Widget>[
          // Running balance chip in the app bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Chip(
              avatar: const Icon(Icons.savings_outlined, size: 16),
              label: Text(
                '${widget.controller.bankedMinutes} min',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
        ],
      ),
      body: activeSession != null
          ? UnlockSessionView(
              remainingSeconds: widget.controller.remainingSeconds,
              session: activeSession,
              bankedMinutes: widget.controller.bankedMinutes,
              onLockNow: () {
                widget.controller.lockNow();
              },
            )
          : activeWorkSession != null
              ? WorkSessionView(
                  elapsedSeconds: widget.controller.workElapsedSeconds,
                  goalMinutes: activeWorkSession.goalMinutes,
                  onSubmitProof: _openProofSubmission,
                  onCancel: () {
                    widget.controller.cancelWorkSession();
                  },
                )
              : LockedHomeView(
                  bankedMinutes: widget.controller.bankedMinutes,
                  onSpendMinutes: widget.controller.spendMinutes,
                  onStartWork: widget.controller.startWorkSession,
                ),
    );
  }
}
