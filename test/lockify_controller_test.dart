import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lockify/services/lockify_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('calculates bounded unlock minutes', () async {
    final prefs = await SharedPreferences.getInstance();
    final controller = LockifyController(prefs: prefs);

    expect(controller.calculateUnlockMinutes(1), 5);
    expect(controller.calculateUnlockMinutes(40), 30);
    expect(controller.calculateUnlockMinutes(999), 120);
  });
}
