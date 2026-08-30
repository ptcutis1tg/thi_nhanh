import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';

void main() {
  test('parses the real teacher room dashboard payload', () {
    final dashboard = TeacherRoomDashboard.fromJson({
      'id': 'room-1',
      'code': 'PT123456',
      'name': 'Kiểm tra chương 1',
      'status': 'waiting',
      'examTitle': 'Toán 10',
      'subject': 'Toán',
      'durationMinutes': 45,
      'maxParticipants': 50,
      'participants': [
        {'id': 'p-1', 'name': 'Minh Anh', 'status': 'waiting'},
      ],
    });

    expect(dashboard.code, 'PT123456');
    expect(dashboard.participants.single.name, 'Minh Anh');
    expect(dashboard.isWaiting, isTrue);
  });
}
