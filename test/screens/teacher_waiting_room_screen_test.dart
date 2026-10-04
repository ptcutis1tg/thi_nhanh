import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/room/teacher_waiting_room_screen.dart';

class FakeTeacherRoomRepo implements RoomRepository {
  int dashboardCallCount = 0;
  int closeCallCount = 0;
  String status;
  final List<RoomParticipant> participants;
  final Exception? closeError;

  FakeTeacherRoomRepo({
    this.status = 'waiting',
    this.participants = const [],
    this.closeError,
  });

  @override
  Future<TeacherRoomDashboard> dashboard(String roomId) async {
    dashboardCallCount++;
    return TeacherRoomDashboard(
      id: roomId,
      code: 'PT999888',
      name: 'Phòng kiểm tra 15 phút',
      status: status,
      examTitle: 'Đề thi Toán học kỳ 1',
      subject: 'Toán học',
      durationMinutes: 45,
      maxParticipants: 40,
      participants: participants,
    );
  }

  @override
  Future<TeacherRoomDashboard> close(String roomId) async {
    closeCallCount++;
    if (closeError != null) throw closeError!;
    status = 'closed';
    return TeacherRoomDashboard(
      id: roomId,
      code: 'PT999888',
      name: 'Phòng kiểm tra 15 phút',
      status: 'closed',
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

  testWidgets('TeacherWaitingRoomScreen ends live room successfully', (tester) async {
    final repo = FakeTeacherRoomRepo(status: 'live');
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
          home: TeacherWaitingRoomScreen(roomId: 'room-test-live'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final endButton = find.text('Kết thúc và công bố kết quả');
    expect(endButton, findsOneWidget);

    await tester.tap(endButton);
    await tester.pumpAndSettle();

    expect(find.text('Kết thúc phòng thi?'), findsOneWidget);

    // Click confirm in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kết thúc và công bố'));
    await tester.pumpAndSettle();

    expect(repo.closeCallCount, 1);
    expect(find.text('Đã kết thúc phòng và công bố kết quả.'), findsOneWidget);
  });

  testWidgets('TeacherWaitingRoomScreen displays clean error message when ending room fails', (tester) async {
    final repo = FakeTeacherRoomRepo(
      status: 'live',
      closeError: Exception(
        'Hàm SQL `close_teacher_room` chưa được cài đặt trên cơ sở dữ liệu Supabase.',
      ),
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
          home: TeacherWaitingRoomScreen(roomId: 'room-test-error'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final endButton = find.text('Kết thúc và công bố kết quả');
    await tester.tap(endButton);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Kết thúc và công bố'));
    await tester.pumpAndSettle();

    expect(repo.closeCallCount, 1);
    expect(
      find.text('Không thể kết thúc phòng: Hàm SQL `close_teacher_room` chưa được cài đặt trên cơ sở dữ liệu Supabase.'),
      findsOneWidget,
    );
  });
}
