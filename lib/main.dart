import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/lockify_controller.dart';
import 'views/history_view.dart';
import 'views/locked_home_view.dart';
import 'views/proof_submission_view.dart';
import 'views/unlock_session_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final controller = LockifyController(prefs: prefs);
  await controller.initialize();
  runApp(LockifyApp(controller: controller));
}

class LockifyApp extends StatelessWidget {
  const LockifyApp({required this.controller, super.key});

  final LockifyController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lockify',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: LockifyHome(controller: controller),
    );
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProofSubmissionView(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lockify'),
        actions: <Widget>[
          IconButton(
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
        ],
      ),
      body: activeSession == null
          ? LockedHomeView(onSubmitProofTapped: _openProofSubmission)
          : UnlockSessionView(
              remainingSeconds: widget.controller.remainingSeconds,
              session: activeSession,
              onLockNow: widget.controller.lockNow,
            ),
    );
  }
}
