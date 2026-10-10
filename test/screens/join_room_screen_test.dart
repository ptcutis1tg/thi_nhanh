import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/screens/room/join_room_screen.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';

class FakeRoomRepository extends Fake implements RoomRepository {
  @override
  Future<StudentJoinResult> joinRoom({
    required String code,
    String? password,
    String? guestName,
  }) async {
    if (code == 'PT999999') {
      throw Exception('Mã phòng không tồn tại');
    }
    return const StudentJoinResult(
      roomId: 'room-123',
      participantId: 'participant-456',
      code: 'PT123456',
      name: 'Nguyen Van A',
      status: 'waiting',
      examId: 'exam-123',
      examTitle: 'Kiem tra',
      subject: 'Toan',
      durationMinutes: 15,
      teacherName: 'Thay B',
      guestToken: 'token-789',
    );
  }
}

void main() {
  testWidgets('JoinRoomScreen renders pre-filled code and form fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<RoomRepository>.value(
          value: FakeRoomRepository(),
          child: const JoinRoomScreen(initialRoomCode: 'PT123456'),
        ),
      ),
    );

    expect(find.text('PT123456'), findsOneWidget);
    expect(find.text('Họ và tên thí sinh'), findsOneWidget);
    expect(find.text('Mật khẩu phòng (nếu có)'), findsOneWidget);
    expect(find.text('Tham gia phòng thi ngay'), findsOneWidget);
  });

  testWidgets('JoinRoomScreen validates empty fields on submit', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<RoomRepository>.value(
          value: FakeRoomRepository(),
          child: const JoinRoomScreen(initialRoomCode: ''),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Tham gia phòng thi ngay'));
    await tester.tap(find.text('Tham gia phòng thi ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập mã phòng thi'), findsOneWidget);
    expect(find.text('Vui lòng nhập họ và tên của bạn'), findsOneWidget);
  });
}
