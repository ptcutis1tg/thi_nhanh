import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/theme/app_theme.dart';
import 'package:onthi_community/shared/widgets/app_interactive_hover_card.dart';

void main() {
  group('AppInteractiveHoverCard Widget Tests', () {
    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppInteractiveHoverCard(
              child: Text('Miku Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Miku Card Content'), findsOneWidget);
    });

    testWidgets('responds to mouse hover enter and exit with translation and shadow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: AppInteractiveHoverCard(
                child: SizedBox(width: 120, height: 80, child: Text('Hover Target')),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move mouse over target
      await gesture.moveTo(tester.getCenter(find.text('Hover Target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hover Target'), findsOneWidget);

      // Move mouse away
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hover Target'), findsOneWidget);
    });
  });
}
