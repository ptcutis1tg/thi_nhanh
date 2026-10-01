import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/room/teacher_waiting_room_screen.dart';

class FakeTeacherRoomRepo implements RoomRepository {
  int dashboardCallCount = 0;
  final List<RoomParticipant> participants;

  FakeTeacherRoomRepo({this.participants = const []});

  @override
  Future<TeacherRoomDashboard> dashboard(String roomId) async {
    dashboardCallCount++;
    return TeacherRoomDashboard(
      id: roomId,
      code: 'PT999888',
      name: 'Phòng kiểm tra 15 phút',
      status: 'waiting',
      examTitle: 'Đề thi Toán học kỳ 1',
      subject: 'Toán học',
      durationMinutes: 45,
      maxParticipants: 40,
      participants: participants,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TeacherWaitingRoomScreen renders room info and auto-polls participants', (tester) async {
    final repo = FakeTeacherRoomRepo(
      participants: [
        const RoomParticipant(id: 'p-1', name: 'Nguyễn Văn An', status: 'waiting'),
      ],
    );

    final authProvider = AuthProvider(isSupabaseInitialized: false);

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          Provider<RoomRepository>.value(value: repo),
        ],
        child: const MaterialApp(
          home: TeacherWaitingRoomScreen(roomId: 'room-test-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Phòng kiểm tra 15 phút'), findsOneWidget);
    expect(find.text('PT999888'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(repo.dashboardCallCount, 1);

    // Tiến thời gian 3.5 giây để kích hoạt auto-polling
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pumpAndSettle();

    // Xác nhận auto-polling đã tự động kích hoạt gọi lại dashboard
    expect(repo.dashboardCallCount, greaterThanOrEqualTo(2));
  });
}
