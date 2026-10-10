import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/screens/exam/widgets/scientific_bottom_toolbar.dart';

void main() {
  testWidgets(
    'ScientificBottomToolbar displays categories and inserts fraction snippet',
    (tester) async {
      String? inserted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ScientificBottomToolbar(
              onInsertSnippet: (snippet, offset, length) {
                inserted = snippet;
              },
            ),
          ),
        ),
      );

      expect(find.text('Toán học'), findsOneWidget);
      expect(find.text('Vật lý'), findsOneWidget);
      expect(find.text('Hóa học'), findsOneWidget);
      expect(find.text('Hy Lạp'), findsOneWidget);
      expect(find.text('Ngoại ngữ / IPA'), findsOneWidget);

      final fractionBtn = find.byTooltip('Phân số');
      expect(fractionBtn, findsOneWidget);
      await tester.tap(fractionBtn);
      await tester.pump();

      expect(inserted, contains(r'\frac{'));
    },
  );

  testWidgets(
    'chemistry reaction arrow inserts chemistry latex, not a vector block',
    (tester) async {
      String? inserted;
      MathBlockType? insertedBlock;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ScientificBottomToolbar(
              onInsertSnippet: (snippet, offset, length) => inserted = snippet,
              onInsertMathBlock: (type) => insertedBlock = type,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Hóa học'));
      await tester.pump();
      await tester.tap(find.byTooltip('Mũi tên phản ứng một chiều'));
      await tester.pump();

      expect(insertedBlock, isNull);
      expect(inserted, contains(r'\rightarrow'));
    },
  );
}
