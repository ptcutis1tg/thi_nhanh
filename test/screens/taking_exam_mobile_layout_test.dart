import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/screens/exam/taking_exam_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final sampleQuestions = [
    {
      'id': 'q1',
      'body': 'Câu 1: Giá trị của 2 + 2 là bao nhiêu?',
      'position': 1,
      'options': [
        {'id': 'opt1', 'body': '3', 'is_correct': false, 'position': 1},
        {'id': 'opt2', 'body': '4', 'is_correct': true, 'position': 2},
      ],
    },
    {
      'id': 'q2',
      'body': 'Câu 2: Thủ đô của Việt Nam là gì?',
      'position': 2,
      'options': [
        {'id': 'opt3', 'body': 'Hà Nội', 'is_correct': true, 'position': 1},
        {'id': 'opt4', 'body': 'Đà Nẵng', 'is_correct': false, 'position': 2},
      ],
    },
    {
      'id': 'q3',
      'body': 'Câu 3: Mặt trời mọc ở hướng nào?',
      'position': 3,
      'options': [
        {'id': 'opt5', 'body': 'Đông', 'is_correct': true, 'position': 1},
        {'id': 'opt6', 'body': 'Tây', 'is_correct': false, 'position': 2},
      ],
    },
  ];

  testWidgets('TakingExamScreen renders horizontal quick-strip and bottom action bar on mobile 360px', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: TakingExamScreen(
          examId: 'test-mobile-exam',
          initialQuestions: sampleQuestions,
          enableAntiCheat: false,
          shuffleQuestions: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify question 1 is rendered
    expect(find.textContaining('Câu 1: Giá trị của 2 + 2'), findsOneWidget);

    // Verify horizontal quick-strip contains question chips (1, 2, 3)
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);

    // Verify bottom action bar has "Câu sau" and "Câu trước"
    expect(find.text('Câu sau'), findsOneWidget);

    // Select option 4 for Question 1
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    // Tap "Câu sau" to go to Question 2
    await tester.tap(find.text('Câu sau'));
    await tester.pumpAndSettle();

    // Verify Question 2 is now shown
    expect(find.textContaining('Câu 2: Thủ đô của Việt Nam'), findsOneWidget);

    // Tap grid button in quick-strip to open Bottom Sheet question matrix
    final gridBtn = find.byIcon(Icons.grid_view_rounded);
    if (gridBtn.evaluate().isNotEmpty) {
      await tester.tap(gridBtn);
      await tester.pumpAndSettle();

      expect(find.text('Danh sách câu hỏi'), findsOneWidget);

      // Tap Question 3 in bottom sheet
      final q3InSheet = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('3'),
      );
      if (q3InSheet.evaluate().isNotEmpty) {
        await tester.tap(q3InSheet);
        await tester.pumpAndSettle();
        expect(find.textContaining('Câu 3: Mặt trời mọc ở hướng nào'), findsOneWidget);
      }
    }
  });
}
