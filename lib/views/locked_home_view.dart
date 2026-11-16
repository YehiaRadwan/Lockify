import 'package:flutter/material.dart';

class LockedHomeView extends StatefulWidget {
  const LockedHomeView({
    required this.onStartWork,
    required this.bankedMinutes,
    required this.onSpendMinutes,
    super.key,
  });

  final Future<void> Function({int goalMinutes}) onStartWork;
  final int bankedMinutes;

  /// Called with the chosen number of minutes to spend.
  /// Returns false if the balance is insufficient.
  final Future<bool> Function(int minutes) onSpendMinutes;

  @override
  State<LockedHomeView> createState() => _LockedHomeViewState();
}

class _LockedHomeViewState extends State<LockedHomeView> {
  // Spend-time slider value (in minutes).
  late int _spendMinutes = _clampSpend(5);
  bool _spending = false;

  int _clampSpend(int value) =>
      value.clamp(5, widget.bankedMinutes.clamp(5, 120));

  @override
  void didUpdateWidget(covariant LockedHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bankedMinutes != oldWidget.bankedMinutes) {
      // Re-clamp if the bank changed while this widget was on screen.
      setState(() => _spendMinutes = _clampSpend(_spendMinutes));
    }
  }

  Future<void> _spend() async {
    setState(() => _spending = true);
    final ok = await widget.onSpendMinutes(_spendMinutes);
    if (!mounted) return;
    setState(() => _spending = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough banked time.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBank = widget.bankedMinutes > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 32),

          // ── Lock icon + title ───────────────────────────────────────────────
          const Icon(Icons.lock, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text(
            'Locked for Focus',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete a focused work session to earn screen time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 32),

          // ── Bank balance card ───────────────────────────────────────────────
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: <Widget>[
                  Icon(Icons.savings_outlined,
                      size: 36, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Screen time balance',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.bankedMinutes} min',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '30 min work  →  +5 min balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Spend section ───────────────────────────────────────────────────
          if (hasBank) ...<Widget>[
            Text(
              'Use balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Unlock for: $_spendMinutes min'),
                Text(
                  'Max: ${widget.bankedMinutes} min',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            Slider(
              value: _spendMinutes.toDouble(),
              min: 5,
              max: widget.bankedMinutes.clamp(5, 120).toDouble(),
              divisions: ((widget.bankedMinutes.clamp(5, 120) - 5) ~/ 5)
                  .clamp(1, 23),
              label: '$_spendMinutes min',
              onChanged: (v) => setState(() => _spendMinutes = v.round()),
            ),
            FilledButton.icon(
              onPressed: _spending ? null : _spend,
              icon: const Icon(Icons.lock_open),
              label: Text(
                _spending
                    ? 'Unlocking…'
                    : 'Unlock for $_spendMinutes min',
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
          ],

          // ── Work session ────────────────────────────────────────────────────
          Text(
            hasBank ? 'Or earn more time' : 'Earn screen time',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => widget.onStartWork(),
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Start Work Session'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
