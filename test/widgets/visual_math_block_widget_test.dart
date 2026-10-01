import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/screens/exam/widgets/visual_math_block_widget.dart';

void main() {
  testWidgets('VisualMathBlockWidget renders fraction with clickable num and den slots', (tester) async {
    final block = MathBlockSegment(
      id: 'f1',
      type: MathBlockType.fraction,
      slots: {'num': '3', 'den': '5'},
    );

    String? updatedSlot;
    String? updatedVal;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VisualMathBlockWidget(
              block: block,
              onSlotChanged: (key, val) {
                updatedSlot = key;
                updatedVal = val;
              },
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    // Verify slots rendered
    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // Type into numerator slot
    await tester.enterText(find.text('3'), '7');
    expect(updatedSlot, 'num');
    expect(updatedVal, '7');
  });

  testWidgets('VisualMathBlockWidget renders sqrt with radicand slot', (tester) async {
    final block = MathBlockSegment(
      id: 's1',
      type: MathBlockType.sqrt,
      slots: {'radicand': 'x + 1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VisualMathBlockWidget(
              block: block,
              onSlotChanged: (_, __) {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('x + 1'), findsOneWidget);
    expect(find.text('√'), findsOneWidget);
  });
}
