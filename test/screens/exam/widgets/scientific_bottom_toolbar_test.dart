import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/scientific_shortcut.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/screens/exam/widgets/scientific_bottom_toolbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
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

  testWidgets(
    'chemistry tab supports search, collapse, and settings for every symbol',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ScientificBottomToolbar(
              initialCategory: ScientificCategory.chemistry,
              onInsertSnippet: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('scientific-symbol-search')),
        'Amoni',
      );
      await tester.pump();
      expect(find.byTooltip('Ion Amoni'), findsOneWidget);

      final collapse = find.byTooltip('Thu gọn thanh ký hiệu');
      await tester.ensureVisible(collapse);
      await tester.tap(collapse);
      await tester.pump();
      expect(find.byTooltip('Ion Amoni'), findsNothing);

      final expand = find.byTooltip('Mở thanh ký hiệu');
      await tester.ensureVisible(expand);
      await tester.tap(expand);
      await tester.pump();
      final settings = find.byKey(const Key('scientific-shortcut-settings'));
      await tester.ensureVisible(settings);
      await tester.tap(settings);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shortcut-command-27')), findsOneWidget);
    },
  );
}
