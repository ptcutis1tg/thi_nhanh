import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/room/widgets/countdown_overlay_widget.dart';

void main() {
  testWidgets('CountdownOverlayWidget counts down 3, 2, 1, and triggers callback', (tester) async {
    bool isCompleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountdownOverlayWidget(
            initialSeconds: 3,
            onCountdownComplete: () => isCompleted = true,
          ),
        ),
      ),
    );

    // Initial value: 3
    expect(find.text('3'), findsOneWidget);

    // Advance 1 second -> 2
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    // Advance 1 second -> 1
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    // Advance 1 second -> BẮT ĐẦU!
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BẮT ĐẦU!'), findsOneWidget);

    // Advance animation completion -> callback triggered
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(isCompleted, isTrue);
  });

  testWidgets('CountdownOverlayWidget renders without RenderFlex overflow on small mobile (360x640)', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountdownOverlayWidget(
            initialSeconds: 3,
            onCountdownComplete: () {},
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
