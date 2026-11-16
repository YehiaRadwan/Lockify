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
                final s = sessions[index];
                final isSpend = s.workMinutes == 0;
                return ListTile(
                  leading: Icon(
                    isSpend ? Icons.lock_open : Icons.work_outline,
                    color: isSpend ? Colors.green : Colors.indigo,
                  ),
                  title: Text(
                    isSpend
                        ? 'Used ${s.unlockedMinutes} min of screen time'
                        : '${s.workMinutes} min work  →  +${s.qualityScore} min earned',
                  ),
                  subtitle: Text(
                    s.proofSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(_formatDate(s.startedAt)),
                  isThreeLine: true,
                );
              },
            ),
    );
  }

  String _formatDate(DateTime v) {
    final d  = v.day.toString().padLeft(2, '0');
    final mo = v.month.toString().padLeft(2, '0');
    final h  = v.hour.toString().padLeft(2, '0');
    final mi = v.minute.toString().padLeft(2, '0');
    return '$d/$mo $h:$mi';
  }
}
