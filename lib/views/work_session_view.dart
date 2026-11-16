import 'package:flutter/material.dart';

class WorkSessionView extends StatelessWidget {
  const WorkSessionView({
    required this.elapsedSeconds,
    required this.goalMinutes,
    required this.onSubmitProof,
    required this.onCancel,
    super.key,
  });

  final int elapsedSeconds;
  final int goalMinutes;
  final VoidCallback onSubmitProof;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedSeconds / (goalMinutes * 60)).clamp(0.0, 1.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.timer, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'Focus Session',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(elapsedSeconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('Goal: $goalMinutes minutes'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSubmitProof,
              icon: const Icon(Icons.upload_file),
              label: const Text('Finish and Submit Proof'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel Session'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remaining = seconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = remaining.toString().padLeft(2, '0');

    if (hours == 0) {
      return '$mm:$ss';
    }

    return '$hours:$mm:$ss';
  }
}
