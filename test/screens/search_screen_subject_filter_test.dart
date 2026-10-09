import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/home/search_screen.dart';

void main() {
  testWidgets('SearchScreen pre-selects initialSubject and filters items', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testItems = [
      const SearchExamItem(
        id: 'exam_math',
        code: 'DT1001',
        title: 'Đề thi Toán học 12',
        teacher: 'Thầy A',
        subject: 'Toán học',
        questions: 10,
        duration: 45,
      ),
      const SearchExamItem(
        id: 'exam_physics',
        code: 'DT1002',
        title: 'Đề thi Vật lý 12',
        teacher: 'Cô B',
        subject: 'Vật lý',
        questions: 10,
        duration: 45,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            initialItems: testItems,
            initialSubject: 'Toán học',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Toán học item is shown
    expect(find.text('Đề thi Toán học 12'), findsOneWidget);
    // Verify Vật lý item is NOT shown
    expect(find.text('Đề thi Vật lý 12'), findsNothing);

    // Verify CheckboxListTile for Toán học is checked
    final mathCheckbox = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Toán học'),
    );
    expect(mathCheckbox.value, isTrue);

    // Verify CheckboxListTile for Vật lý is NOT checked
    final physicsCheckbox = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Vật lý'),
    );
    expect(physicsCheckbox.value, isFalse);
  });

  testWidgets('SearchScreen resiliently matches item with subject "Toán" when initialSubject is "Toán học"', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testItems = [
      const SearchExamItem(
        id: 'exam_math_short',
        code: 'DT1003',
        title: 'Đề thi Toán THPT QG',
        teacher: 'Thầy X',
        subject: 'Toán',
        questions: 50,
        duration: 90,
      ),
      const SearchExamItem(
        id: 'exam_lit',
        code: 'DT1004',
        title: 'Đề thi Ngữ văn',
        teacher: 'Cô Y',
        subject: 'Ngữ văn',
        questions: 5,
        duration: 120,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            initialItems: testItems,
            initialSubject: 'Toán học',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 'Toán' item is matched when initialSubject is 'Toán học'
    expect(find.text('Đề thi Toán THPT QG'), findsOneWidget);
    expect(find.text('Đề thi Ngữ văn'), findsNothing);

    // Now tap checkbox for 'Ngữ văn'
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Ngữ văn'));
    await tester.pump();

    // Both should now be shown
    expect(find.text('Đề thi Toán THPT QG'), findsOneWidget);
    expect(find.text('Đề thi Ngữ văn'), findsOneWidget);
  });
}
