import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lockify/services/lockify_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('calculates earned minutes using the 30-to-5 ratio', () async {
    final prefs = await SharedPreferences.getInstance();
    final controller = LockifyController(prefs: prefs);

    expect(controller.calculateUnlockMinutes(0), 0);
    expect(controller.calculateUnlockMinutes(1), 0);
    expect(controller.calculateUnlockMinutes(30), 5);
    expect(controller.calculateUnlockMinutes(40), 6);
    expect(controller.calculateUnlockMinutes(60), 10);
    expect(controller.calculateUnlockMinutes(999), 166);
  });

  test('quality score does not change the current earnings formula', () async {
    final prefs = await SharedPreferences.getInstance();
    final controller = LockifyController(prefs: prefs);

    expect(controller.calculateUnlockMinutes(40, qualityScore: 50), 6);
    expect(controller.calculateUnlockMinutes(40, qualityScore: 100), 6);
  });

  test('starts and cancels work sessions', () async {
    final prefs = await SharedPreferences.getInstance();
    final controller = LockifyController(prefs: prefs);

    await controller.initialize();
    await controller.startWorkSession(goalMinutes: 45);

    expect(controller.isWorking, isTrue);
    expect(controller.activeWorkSession?.goalMinutes, 45);

    await controller.cancelWorkSession();

    expect(controller.isWorking, isFalse);
  });
}
