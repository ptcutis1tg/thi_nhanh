import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('TeacherRoomData & Service Tests', () {
    test('TeacherRoomData parses extended fields correctly', () {
      final room = TeacherRoomData(
        id: 'r1',
        title: 'Phòng kiểm tra 15 phút Toán',
        roomCode: 'PT123456',
        date: '04/10/2026',
        studentsCount: 25,
        statusLabel: 'Đang diễn ra',
        statusType: 'live',
        examTitle: 'Đề Toán Giải Tích 12',
        examSubject: 'Toán',
        durationMinutes: 15,
      );

      expect(room.id, 'r1');
      expect(room.roomCode, 'PT123456');
      expect(room.examTitle, 'Đề Toán Giải Tích 12');
      expect(room.examSubject, 'Toán');
      expect(room.durationMinutes, 15);
      expect(room.statusType, 'live');
    });
  });
}
