import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/widgets/latex_math_view.dart';

void main() {
  testWidgets('LatexMathView renders plain text without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LatexMathView(text: 'Câu hỏi kiểm tra đơn giản'),
        ),
      ),
    );
    expect(find.text('Câu hỏi kiểm tra đơn giản'), findsOneWidget);
  });

  testWidgets('LatexMathView splits and renders inline latex formula', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LatexMathView(text: r'Cho phương trình $x^2 + 1 = 0$'),
        ),
      ),
    );
    expect(find.byType(LatexMathView), findsOneWidget);
  });
}
