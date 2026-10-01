import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/room/room_password_screen.dart';

class FakePasswordRoomRepo implements RoomRepository {
  String? submittedPassword;
  String? submittedCode;

  @override
  Future<StudentJoinResult> joinRoom({
    required String code,
    String? password,
    String? guestName,
  }) async {
    submittedCode = code;
    submittedPassword = password;
    if (password != 'secret123') {
      throw Exception('Invalid room password');
    }
    return StudentJoinResult(
      roomId: 'room-verified-1',
      participantId: 'p-1',
      code: code,
      name: 'Phòng thi thử',
      status: 'waiting',
      examId: 'exam-1',
      examTitle: 'Đề thi thử',
      subject: 'Toán',
      durationMinutes: 45,
      teacherName: 'Giáo viên',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('RoomPasswordScreen verifies password against RoomRepository', (tester) async {
    final repo = FakePasswordRoomRepo();

    await tester.pumpWidget(
      Provider<RoomRepository>.value(
        value: repo,
        child: const MaterialApp(
          home: RoomPasswordScreen(roomCode: 'PT112233'),
        ),
      ),
    );

    // Nhập sai mật khẩu
    await tester.enterText(find.byType(TextField), 'wrongpass');
    await tester.tap(find.text('Xác nhận vào phòng'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu phòng thi không chính xác.'), findsOneWidget);
    expect(repo.submittedCode, 'PT112233');
    expect(repo.submittedPassword, 'wrongpass');
  });
}
