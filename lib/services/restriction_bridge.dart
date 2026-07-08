abstract class RestrictionBridge {
  Future<void> beginUnlockSession(DateTime endsAt);
  Future<void> endUnlockSession();
}

class NoopRestrictionBridge implements RestrictionBridge {
  @override
  Future<void> beginUnlockSession(DateTime endsAt) async {}

  @override
  Future<void> endUnlockSession() async {}
}
