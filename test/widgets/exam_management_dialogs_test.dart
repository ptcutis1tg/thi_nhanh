import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/teacher/widgets/publish_confirm_dialog.dart';
import 'package:onthi_community/screens/teacher/widgets/delete_draft_confirm_dialog.dart';

void main() {
  const summary = TeacherExamSummary(
    id: 'exam-1',
    code: 'DT123456',
    title: 'Kiểm tra 15 phút Vật Lý 12',
    subject: 'Vật lý',
    durationMinutes: 15,
    questionCount: 10,
    status: 'draft',
  );

  testWidgets('PublishConfirmDialog renders exam details and checklist', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool confirmed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PublishConfirmDialog(
          summary: summary,
          onConfirmed: () async {
            confirmed = true;
          },
        ),
      ),
    ));

    expect(find.text('Xuất bản đề thi'), findsOneWidget);
    expect(find.textContaining('Kiểm tra 15 phút Vật Lý 12'), findsOneWidget);
    expect(find.text('Xác nhận Xuất bản'), findsOneWidget);

    await tester.tap(find.text('Xác nhận Xuất bản'));
    await tester.pumpAndSettle();
    expect(confirmed, true);
  });

  testWidgets('DeleteDraftConfirmDialog renders delete warning', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool deleted = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeleteDraftConfirmDialog(
          summary: summary,
          onConfirmed: () async {
            deleted = true;
          },
        ),
      ),
    ));

    expect(find.text('Xóa bản nháp'), findsOneWidget);
    expect(find.textContaining('không thể khôi phục'), findsOneWidget);

    await tester.tap(find.text('Xóa vĩnh viễn'));
    await tester.pumpAndSettle();
    expect(deleted, true);
  });
}
