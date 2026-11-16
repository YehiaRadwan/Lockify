import 'package:flutter/material.dart';

import '../models/unlock_session.dart';

class UnlockSessionView extends StatelessWidget {
  const UnlockSessionView({
    required this.remainingSeconds,
    required this.session,
    required this.bankedMinutes,
    required this.onLockNow,
    super.key,
  });

  final int remainingSeconds;
  final UnlockSession session;
  final int bankedMinutes;
  final VoidCallback onLockNow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              style: const TextStyle(
                  fontSize: 56, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('remaining', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Balance chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.savings_outlined,
                      size: 18,
                      color: colorScheme.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    '$bankedMinutes min remaining in balance',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              session.proofSummary,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onLockNow,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Lock Now'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes  = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }
}
