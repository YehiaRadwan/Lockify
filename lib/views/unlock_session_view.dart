import 'package:flutter/material.dart';

import '../models/unlock_session.dart';

class UnlockSessionView extends StatelessWidget {
  const UnlockSessionView({
    required this.remainingSeconds,
    required this.session,
    required this.onLockNow,
    super.key,
  });

  final int remainingSeconds;
  final UnlockSession session;
  final VoidCallback onLockNow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.lock_open, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Unlocked',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(remainingSeconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Unlock granted for ${session.unlockedMinutes} minutes'),
            const SizedBox(height: 10),
            Text(
              session.proofSummary,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onLockNow, child: const Text('Lock Now')),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = remaining.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
