import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/screens/exam/widgets/inline_visual_math_editor.dart';

void main() {
  testWidgets('InlineVisualMathEditor toggles between visual blocks and raw latex', (tester) async {
    String currentLatex = r'Cho hàm số \frac{1}{2}';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InlineVisualMathEditor(
            initialLatex: currentLatex,
            onChanged: (val) => currentLatex = val,
          ),
        ),
      ),
    );

    // Initial mode is Visual Blocks: shows fraction slots '1' and '2'
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Tap raw latex mode button
    await tester.tap(find.text('Mã nguồn LaTeX'));
    await tester.pumpAndSettle();

    // Now raw LaTeX field is visible
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('InlineVisualMathEditor insertMathBlock adds new visual block', (tester) async {
    final controller = InlineVisualMathEditorController();
    String currentLatex = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InlineVisualMathEditor(
            initialLatex: currentLatex,
            controller: controller,
            onChanged: (val) => currentLatex = val,
          ),
        ),
      ),
    );

    // Insert fraction
    controller.insertMathBlock(MathBlockType.fraction);
    await tester.pumpAndSettle();

    expect(find.text('tử số'), findsOneWidget);
    expect(find.text('mẫu số'), findsOneWidget);
  });
}
