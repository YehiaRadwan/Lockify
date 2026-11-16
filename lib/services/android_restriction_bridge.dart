import 'package:flutter/services.dart';

import 'restriction_bridge.dart';

/// Implements [RestrictionBridge] by communicating with the native
/// [AppBlockerService] via a [MethodChannel].
///
/// When an unlock session begins we stop the blocking service so the user
/// can freely use their phone. When the session ends (or the user locks
/// manually) we start it again.
class AndroidRestrictionBridge implements RestrictionBridge {
  static const _channel = MethodChannel('com.example.lockify/blocker');

  @override
  Future<void> beginUnlockSession(DateTime endsAt) async {
    // The phone is now unlocked — stop the blocker so apps are accessible.
    await _channel.invokeMethod<void>('stopBlocking');
  }

  @override
  Future<void> endUnlockSession() async {
    // The unlock window is over — resume blocking.
    await _channel.invokeMethod<void>('startBlocking');
  }

  // ── Permission helpers ────────────────────────────────────────────────────

  static Future<bool> hasUsageStatsPermission() async {
    return await _channel.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
  }

  static Future<void> requestUsageStatsPermission() async {
    await _channel.invokeMethod<void>('requestUsageStatsPermission');
  }

  static Future<bool> hasOverlayPermission() async {
    return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
  }

  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod<void>('requestOverlayPermission');
  }

  /// Returns true only if both required permissions are granted.
  static Future<bool> hasAllPermissions() async {
    final results = await Future.wait([
      hasUsageStatsPermission(),
      hasOverlayPermission(),
    ]);
    return results.every((granted) => granted);
  }
}
