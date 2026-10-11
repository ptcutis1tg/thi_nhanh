import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/widgets/edit_exam_info_dialog.dart';

void main() {
  testWidgets('EditExamInfoDialog submits updated values with validation', (tester) async {
    String? updatedTitle;
    String? updatedSubject;
    int? updatedDuration;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditExamInfoDialog(
            initialTitle: 'Đề cũ',
            initialSubject: 'Toán',
            initialDurationMinutes: 45,
            onSave: (t, s, d) {
              updatedTitle = t;
              updatedSubject = s;
              updatedDuration = d;
            },
          ),
        ),
      ),
    );

    expect(find.text('Chỉnh sửa thông tin đề thi'), findsOneWidget);

    // Update title
    await tester.enterText(find.byKey(const Key('edit-exam-title')), 'Đề mới đã sửa');
    // Update duration
    await tester.enterText(find.byKey(const Key('edit-exam-duration')), '60');
    // Tap save
    await tester.tap(find.byKey(const Key('edit-exam-save')));
    await tester.pumpAndSettle();

    expect(updatedTitle, 'Đề mới đã sửa');
    expect(updatedDuration, 60);
    expect(updatedSubject, 'Toán');
  });

  testWidgets('EditExamInfoDialog validates required title and duration constraints', (tester) async {
    String? updatedTitle;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditExamInfoDialog(
            initialTitle: 'Đề chuẩn',
            initialSubject: 'Vật lý',
            initialDurationMinutes: 45,
            onSave: (t, s, d) => updatedTitle = t,
          ),
        ),
      ),
    );

    // Enter short title < 3 chars
    await tester.enterText(find.byKey(const Key('edit-exam-title')), 'AB');
    await tester.tap(find.byKey(const Key('edit-exam-save')));
    await tester.pumpAndSettle();

    expect(find.text('Tên đề thi phải có ít nhất 3 ký tự'), findsOneWidget);
    expect(updatedTitle, isNull);
  });
}
