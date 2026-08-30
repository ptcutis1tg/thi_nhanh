import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';

class FakeTeacherExamRepository implements TeacherExamRepository {
  @override
  Future<List<TeacherExamSummary>> summaries() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows an empty state until the teacher has created an exam', (tester) async {
    await tester.pumpWidget(
      Provider<TeacherExamRepository>(
        create: (_) => FakeTeacherExamRepository(),
        child: const MaterialApp(home: CreateRoomScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có đề nào để mở phòng.'), findsOneWidget);
    expect(find.text('Tạo đề mới'), findsOneWidget);
  });
}
