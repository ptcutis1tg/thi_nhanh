import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';

class _FakeTeacherExamRepo implements TeacherExamRepository {
  _FakeTeacherExamRepo([this._exams = const []]);
  final List<TeacherExamSummary> _exams;

  @override
  Future<List<TeacherExamSummary>> summaries() async => _exams;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSavedExamRepo implements SavedExamRepository {
  _FakeSavedExamRepo(this._savedExams);
  final List<TeacherExamSummary> _savedExams;

  @override
  Future<List<TeacherExamSummary>> getSavedExams() async => _savedExams;

  @override
  Future<Set<String>> getSavedExamIds() async => _savedExams.map((e) => e.id).toSet();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('CreateRoomScreen renders saved exams and allows selecting them to create a room', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final teacherRepo = _FakeTeacherExamRepo([
      const TeacherExamSummary(
        id: 'my-exam-1',
        title: 'Đề Toán do tôi tạo',
        subject: 'Toán học',
        status: 'published',
        durationMinutes: 45,
        questionCount: 25,
      ),
    ]);

    final savedRepo = _FakeSavedExamRepo([
      const TeacherExamSummary(
        id: 'saved-exam-1',
        title: 'Đề Lý lưu từ cộng đồng',
        subject: 'Vật lý',
        status: 'published',
        durationMinutes: 60,
        questionCount: 40,
      ),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>.value(value: teacherRepo),
          Provider<SavedExamRepository?>.value(value: savedRepo),
        ],
        child: const MaterialApp(home: CreateRoomScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify filter tabs exist: 'Tất cả', 'Đề của tôi', 'Đề đã lưu'
    expect(find.text('Tất cả'), findsWidgets);
    expect(find.text('Đề của tôi'), findsOneWidget);
    expect(find.text('Đề đã lưu'), findsOneWidget);

    // Verify both exams are shown in 'Tất cả'
    expect(find.text('Đề Toán do tôi tạo'), findsOneWidget);
    expect(find.text('Đề Lý lưu từ cộng đồng'), findsOneWidget);
    expect(find.text('Đề lưu từ cộng đồng'), findsOneWidget);

    // Select the saved exam
    await tester.tap(find.text('Đề Lý lưu từ cộng đồng'));
    await tester.pumpAndSettle();

    expect(find.text('Đã chọn'), findsOneWidget);

    // Enter room name
    final roomNameInput = find.widgetWithText(TextField, 'Tên phòng thi *');
    expect(roomNameInput, findsOneWidget);
    await tester.enterText(roomNameInput, 'Phòng thi đề cộng đồng 12A1');
    await tester.pumpAndSettle();

    // Verify "Khởi tạo phòng thi" button is enabled
    final createBtnFinder = find.widgetWithText(ElevatedButton, 'Khởi tạo phòng thi');
    expect(createBtnFinder, findsOneWidget);
    final buttonWidget = tester.widget<ElevatedButton>(createBtnFinder);
    expect(buttonWidget.onPressed, isNotNull);
  });
}
