import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/assessment_repository.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/room/student_waiting_room_screen.dart';
import 'package:onthi_community/screens/room/widgets/countdown_overlay_widget.dart';

class _FakeRoomRepository implements RoomRepository {
  _FakeRoomRepository(this._state);
  final StudentRoomState _state;

  @override
  Future<StudentRoomState> getStudentRoomState({
    required String roomId,
    required String participantId,
    String? guestToken,
  }) async =>
      _state;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAssessmentRepository implements AssessmentRepository {
  @override
  Future<void> rememberGuestToken(String attemptId, String guestToken) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('displays CountdownOverlayWidget when room state transitions to live', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const liveState = StudentRoomState(
      roomId: 'room-123',
      code: 'ABC888',
      name: 'Phòng Thi Đố Vui',
      status: 'live',
      examId: 'exam-1',
      examTitle: 'Đề Toán Kỳ 1',
      subject: 'Toán',
      durationMinutes: 45,
      teacherName: 'Thầy Bình',
      participantStatus: 'ready',
      participantCount: 1,
      participants: [],
      attemptId: 'attempt-456',
    );

    final fakeRoomRepo = _FakeRoomRepository(liveState);
    final fakeAssessmentRepo = _FakeAssessmentRepository();
    final authProvider = AuthProvider(isSupabaseInitialized: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RoomRepository?>.value(value: fakeRoomRepo),
          Provider<AssessmentRepository>.value(value: fakeAssessmentRepo),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: StudentWaitingRoomScreen(
            roomId: 'room-123',
            participantId: 'part-1',
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify CountdownOverlayWidget is rendered and shows countdown
    expect(find.byType(CountdownOverlayWidget), findsOneWidget);
    expect(find.text('PHÒNG THI CHÍNH THỨC MỞ'), findsOneWidget);
  });
}
