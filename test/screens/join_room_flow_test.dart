import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/home/home_screen.dart';
import 'package:onthi_community/screens/room/widgets/join_room_guest_dialog.dart';

class FakeRoomRepo implements RoomRepository {
  final String? hostedRoomId;

  FakeRoomRepo({this.hostedRoomId});

  @override
  Future<String?> findHostedRoomId(String code) async => hostedRoomId;

  @override
  Future<StudentJoinResult> joinRoom({required String code, String? password, String? guestName}) async {
    return StudentJoinResult(
      roomId: 'room-student-123',
      participantId: 'part-456',
      code: code,
      name: 'Test Room',
      status: 'waiting',
      examId: 'exam-789',
      examTitle: 'Test Exam',
      subject: 'Toán',
      durationMinutes: 45,
      teacherName: 'Thầy Nam',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders JoinRoomGuestDialog and validates empty name', (tester) async {
    bool joined = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JoinRoomGuestDialog(
            roomCode: 'PT123456',
            onJoin: (name, password) async {
              joined = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Vào phòng thi'), findsOneWidget);
    expect(find.text('Mã phòng: PT123456'), findsOneWidget);
    expect(find.text('Tham gia'), findsOneWidget);

    // Tap submit without typing name
    await tester.tap(find.text('Tham gia'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(joined, isFalse);

    // Enter name
    await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn Minh');
    await tester.tap(find.text('Tham gia'));
    await tester.pump();

    expect(joined, isTrue);
  });

  testWidgets('Room creator entering own room code routes to teacher_waiting_room', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = AuthProvider(isSupabaseInitialized: false);
    await auth.init();
    final fakeRepo = FakeRoomRepo(hostedRoomId: 'hosted-room-uuid-999');

    String? navigatedRoute;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/teacher_waiting_room',
          builder: (ctx, state) {
            navigatedRoute = '/teacher_waiting_room?roomId=${state.uri.queryParameters['roomId']}';
            return const Scaffold(body: Text('Teacher Waiting Room'));
          },
        ),
        GoRoute(
          path: '/student_waiting_room',
          builder: (ctx, state) {
            navigatedRoute = '/student_waiting_room';
            return const Scaffold(body: Text('Student Waiting Room'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          Provider<RoomRepository>.value(value: fakeRepo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Find quick room input TextField
    final inputField = find.widgetWithText(TextField, 'Nhập mã phòng PTxxxxxx...');
    expect(inputField, findsOneWidget);

    await tester.enterText(inputField, 'PT888999');
    await tester.tap(find.text('Vào ngay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(navigatedRoute, equals('/teacher_waiting_room?roomId=hosted-room-uuid-999'));
  });
}
