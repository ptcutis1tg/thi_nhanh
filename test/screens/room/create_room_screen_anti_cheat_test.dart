import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';

class _FakeTeacherExamRepo implements TeacherExamRepository {
  @override
  Future<List<TeacherExamSummary>> summaries() async => [
        const TeacherExamSummary(
          id: 'exam-1',
          title: 'Đề thi Khảo sát',
          subject: 'Toán',
          status: 'published',
          durationMinutes: 45,
          questionCount: 20,
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders anti-cheat and shuffle toggles with default true and can toggle', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      Provider<TeacherExamRepository>.value(
        value: _FakeTeacherExamRepo(),
        child: const MaterialApp(home: CreateRoomScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of toggles
    final shuffleFinder = find.widgetWithText(SwitchListTile, 'Trộn ngẫu nhiên câu hỏi & đáp án');
    final antiCheatFinder = find.widgetWithText(SwitchListTile, 'Giám sát chống gian lận');

    expect(shuffleFinder, findsOneWidget);
    expect(antiCheatFinder, findsOneWidget);

    // Verify default value is true
    SwitchListTile shuffleSwitch = tester.widget(shuffleFinder);
    SwitchListTile antiCheatSwitch = tester.widget(antiCheatFinder);
    expect(shuffleSwitch.value, isTrue);
    expect(antiCheatSwitch.value, isTrue);

    // Tap anti-cheat switch to toggle
    await tester.tap(antiCheatFinder);
    await tester.pumpAndSettle();

    antiCheatSwitch = tester.widget(antiCheatFinder);
    expect(antiCheatSwitch.value, isFalse);

    // Tap shuffle switch to toggle
    await tester.tap(shuffleFinder);
    await tester.pumpAndSettle();

    shuffleSwitch = tester.widget(shuffleFinder);
    expect(shuffleSwitch.value, isFalse);
  });
}
