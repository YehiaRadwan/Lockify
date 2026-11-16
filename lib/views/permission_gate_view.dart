import 'package:flutter/material.dart';

import '../services/android_restriction_bridge.dart';

/// Shown on first launch (or whenever a required permission is missing).
/// Walks the user through granting Usage Stats and Overlay permissions,
/// then calls [onPermissionsGranted] when both are in order.
class PermissionGateView extends StatefulWidget {
  const PermissionGateView({required this.onPermissionsGranted, super.key});

  final VoidCallback onPermissionsGranted;

  @override
  State<PermissionGateView> createState() => _PermissionGateViewState();
}

class _PermissionGateViewState extends State<PermissionGateView>
    with WidgetsBindingObserver {
  bool _hasUsage = false;
  bool _hasOverlay = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check whenever the app is resumed (user may have just granted a
  /// permission in system settings and switched back).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (_checking) return;
    setState(() => _checking = true);

    final usage = await AndroidRestrictionBridge.hasUsageStatsPermission();
    final overlay = await AndroidRestrictionBridge.hasOverlayPermission();

    if (!mounted) return;
    setState(() {
      _hasUsage = usage;
      _hasOverlay = overlay;
      _checking = false;
    });

    if (_hasUsage && _hasOverlay) {
      widget.onPermissionsGranted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 24),
              const Icon(Icons.lock_outline, size: 56, color: Colors.indigo),
              const SizedBox(height: 20),
              Text(
                'Lockify needs two permissions to block other apps.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'These are used only to enforce the locked state. '
                'Lockify never reads your personal data.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),

              _PermissionTile(
                icon: Icons.bar_chart,
                title: 'Usage access',
                subtitle:
                    'Lets Lockify detect when you open another app while locked.',
                granted: _hasUsage,
                onGrant: AndroidRestrictionBridge.requestUsageStatsPermission,
              ),
              const SizedBox(height: 16),

              _PermissionTile(
                icon: Icons.layers,
                title: 'Display over other apps',
                subtitle:
                    'Lets Lockify bring itself to the foreground to block access.',
                granted: _hasOverlay,
                onGrant: AndroidRestrictionBridge.requestOverlayPermission,
              ),

              const Spacer(),

              if (_checking)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (_hasUsage && _hasOverlay) ? null : _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check again'),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onGrant,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: granted ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: granted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton(
                onPressed: onGrant,
                child: const Text('Grant'),
              ),
      ),
    );
  }
}
