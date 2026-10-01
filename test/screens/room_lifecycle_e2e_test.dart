import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';
import 'package:onthi_community/screens/room/teacher_waiting_room_screen.dart';
import 'package:onthi_community/screens/room/student_waiting_room_screen.dart';
import 'package:onthi_community/screens/room/widgets/room_qr_dialog.dart';

class E2EExamRepository implements TeacherExamRepository {
  @override
  Future<List<TeacherExamSummary>> summaries() async {
    return [
      const TeacherExamSummary(
        id: 'exam-e2e-1',
        title: 'Đề thi Khảo sát Chất lượng 2026',
        subject: 'Toán học',
        status: 'published',
        durationMinutes: 45,
        questionCount: 40,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class E2ERoomRepository implements RoomRepository {
  String? createdExamId;
  String? createdName;
  int? createdMaxParticipants;

  @override
  Future<TeacherRoomDashboard> create({
    required String examId,
    required String name,
    String? password,
    int maxParticipants = 50,
  }) async {
    createdExamId = examId;
    createdName = name;
    createdMaxParticipants = maxParticipants;
    return TeacherRoomDashboard(
      id: 'room-e2e-100',
      code: 'PT888999',
      name: name,
      status: 'waiting',
      examTitle: 'Đề thi Khảo sát Chất lượng 2026',
      subject: 'Toán học',
      durationMinutes: 45,
      maxParticipants: maxParticipants,
      participants: const [
        RoomParticipant(id: 'p-1', name: 'Thí sinh A', status: 'waiting'),
      ],
    );
  }

  @override
  Future<TeacherRoomDashboard> dashboard(String roomId) async {
    return TeacherRoomDashboard(
      id: roomId,
      code: 'PT888999',
      name: createdName ?? 'Phòng thi E2E',
      status: 'waiting',
      examTitle: 'Đề thi Khảo sát Chất lượng 2026',
      subject: 'Toán học',
      durationMinutes: 45,
      maxParticipants: createdMaxParticipants ?? 40,
      participants: const [
        RoomParticipant(id: 'p-1', name: 'Thí sinh A', status: 'waiting'),
        RoomParticipant(id: 'p-2', name: 'Thí sinh B', status: 'waiting'),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('E2E Live Exam Room Lifecycle: Creation, Waiting Room, QR Presentation, and Student Waiting', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final examRepo = E2EExamRepository();
    final roomRepo = E2ERoomRepository();
    final authProvider = AuthProvider(isSupabaseInitialized: false);

    // 1. Giáo viên mở màn hình tạo phòng thi
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          Provider<TeacherExamRepository>.value(value: examRepo),
          Provider<RoomRepository>.value(value: roomRepo),
        ],
        child: const MaterialApp(
          home: CreateRoomScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tạo phòng thi'), findsOneWidget);
    expect(find.text('Sĩ số tối đa'), findsOneWidget);

    // Điền tên phòng thi
    await tester.enterText(find.byType(TextField).first, 'Kiểm tra Khảo sát 12A1');

    // Chọn sĩ số 50 thí sinh
    await tester.tap(find.text('50 thí sinh'));
    await tester.pumpAndSettle();

    // Chọn đề thi
    await tester.tap(find.text('Đề thi Khảo sát Chất lượng 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Đã chọn'), findsOneWidget);

    // 2. Giáo viên xem phòng chờ và trình chiếu QR
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          Provider<RoomRepository>.value(value: roomRepo),
        ],
        child: const MaterialApp(
          home: TeacherWaitingRoomScreen(roomId: 'room-e2e-100'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MÃ PHÒNG THI'), findsOneWidget);
    expect(find.text('PT888999'), findsOneWidget);
    expect(find.text('Chiếu QR'), findsOneWidget);

    // Bấm Chiếu QR để mở Dialog trình chiếu toàn màn hình
    await tester.tap(find.text('Chiếu QR'));
    await tester.pumpAndSettle();

    expect(find.byType(RoomQrDialog), findsOneWidget);
    expect(find.text('Quét mã QR để vào phòng thi'), findsOneWidget);
    expect(find.text('Sao chép link vào phòng'), findsOneWidget);

    // Đóng dialog QR
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    // 3. Học sinh vào phòng chờ
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: StudentWaitingRoomScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Xác nhận không còn nút debug mô phỏng và không có avatar giả
    expect(find.text('Mô phỏng: Bắt đầu thi'), findsNothing);
    expect(find.text('Minh Anh'), findsNothing);
    expect(find.text('Bạn đã vào phòng thi thành công!'), findsOneWidget);
  });
}
