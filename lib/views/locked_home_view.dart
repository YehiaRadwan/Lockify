import 'package:flutter/material.dart';

class LockedHomeView extends StatelessWidget {
  const LockedHomeView({required this.onSubmitProofTapped, super.key});

  final VoidCallback onSubmitProofTapped;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.lock, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Locked for Focus',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submit proof of work to unlock for a limited time.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onSubmitProofTapped,
              child: const Text('Submit Proof of Work'),
            ),
          ],
        ),
      ),
    );
  }
}
