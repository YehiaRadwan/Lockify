import 'package:flutter/material.dart';

import '../models/unlock_session.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({required this.sessions, super.key});

  final List<UnlockSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: sessions.isEmpty
          ? const Center(child: Text('No sessions yet'))
          : ListView.separated(
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return ListTile(
                  title: Text('Unlocked ${session.unlockedMinutes} min'),
                  subtitle: Text(
                    '${session.startedAt} \n${session.proofSummary}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
