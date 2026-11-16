import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lockify/main.dart';
import 'package:lockify/services/lockify_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows the locked home screen by default', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = LockifyController(prefs: prefs);
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(home: LockifyHome(controller: controller)),
    );

    expect(find.text('Locked for Focus'), findsOneWidget);
    expect(find.text('Start Work Session'), findsOneWidget);

    // Dispose LockifyHome so its periodic timer is cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
