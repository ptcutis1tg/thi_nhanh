import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('StudentTestHistoryData Model & Logic Tests', () {
    test('parses extended fields including roomCode, duration and resultReleased', () {
      final item = StudentTestHistoryData(
        id: 'att-123',
        subjectIcon: '📐',
        title: 'Kiểm tra 15 phút Toán',
        date: '04/10/2026',
        score: '8.5 điểm',
        scoreValue: 8.5,
        subject: 'Toán',
        roomId: 'room-uuid-1',
        roomCode: 'PT123456',
        durationSeconds: 1110, // 18 phút 30 giây
        isLiveRoom: true,
        resultReleased: true,
      );

      expect(item.id, 'att-123');
      expect(item.roomCode, 'PT123456');
      expect(item.isLiveRoom, isTrue);
      expect(item.resultReleased, isTrue);
      expect(item.durationFormatted, '18:30');
    });

    test('durationFormatted formats seconds into mm:ss or hh:mm:ss correctly', () {
      final shortTest = StudentTestHistoryData(
        id: '1',
        subjectIcon: '📐',
        title: 'T',
        date: 'D',
        score: '10',
        scoreValue: 10,
        subject: 'Toán',
        durationSeconds: 75,
      );
      expect(shortTest.durationFormatted, '01:15');

      final zeroTest = StudentTestHistoryData(
        id: '2',
        subjectIcon: '📐',
        title: 'T',
        date: 'D',
        score: '10',
        scoreValue: 10,
        subject: 'Toán',
        durationSeconds: null,
      );
      expect(zeroTest.durationFormatted, '--:--');
    });
  });
}
