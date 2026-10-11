import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
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

  testWidgets('renders raw LaTeX environments without dollar delimiters', (
    tester,
  ) async {
    const source = r'''A=\begin{pmatrix}
1 & 2 & 3\\
4 & 5 & 6
\end{pmatrix}

\begin{cases}
2x+3y=7\\
x-y=1
\end{cases}''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LatexMathView(text: source)),
      ),
    );
    await tester.pump();

    expect(find.byType(Math), findsOneWidget);
    expect(find.textContaining(r'\begin{pmatrix}'), findsNothing);
  });

  testWidgets('keeps an inline formula on the same logical content line', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LatexMathView(
            text: 'Dòng một\n\n\nDòng bốn \$\\lim_{x \\to a} f(x)\$',
          ),
        ),
      ),
    );

    final fourthLine = find.text('Dòng bốn ');
    expect(fourthLine, findsOneWidget);

    final fourthLinePosition = tester.getTopLeft(fourthLine);
    final formula = tester.getTopLeft(find.byType(Math));

    expect((formula.dy - fourthLinePosition.dy).abs(), lessThan(3));
  });
}
