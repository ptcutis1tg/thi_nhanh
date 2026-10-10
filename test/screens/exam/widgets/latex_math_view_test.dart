import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/widgets/latex_math_view.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/core/utils/visual_math_compiler.dart';

void main() {
  testWidgets('LatexMathView renders plain text without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LatexMathView(text: 'Câu hỏi kiểm tra đơn giản')),
      ),
    );
    expect(find.text('Câu hỏi kiểm tra đơn giản'), findsOneWidget);
  });

  testWidgets('LatexMathView splits and renders inline latex formula', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LatexMathView(text: r'Cho phương trình $x^2 + 1 = 0$'),
        ),
      ),
    );
    expect(find.byType(LatexMathView), findsOneWidget);
  });

  testWidgets('renders compiled visual math instead of exposing raw latex', (
    tester,
  ) async {
    final text = VisualMathCompiler.compile([
      MathBlockSegment(id: 'fraction', type: MathBlockType.fraction),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LatexMathView(text: text)),
      ),
    );

    expect(find.textContaining(r'\frac'), findsNothing);
  });

  testWidgets('renders reversible chemistry arrow without command text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LatexMathView(text: r'$\rightleftharpoons$')),
      ),
    );
    await tester.pump();

    expect(find.textContaining('rightleftharpoons'), findsNothing);
  });
}
