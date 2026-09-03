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

  test('parses student room join result payload', () {
    final joinResult = StudentJoinResult.fromJson({
      'roomId': 'room-1',
      'participantId': 'part-1',
      'code': 'PT892341',
      'name': 'Kiểm tra giữa kỳ',
      'status': 'waiting',
      'examId': 'exam-1',
      'examTitle': 'Vật lý 12',
      'subject': 'Vật lý',
      'durationMinutes': 45,
      'teacherName': 'Thầy Hưng',
      'guestToken': 'token123',
      'attemptId': null,
    });

    expect(joinResult.roomId, 'room-1');
    expect(joinResult.code, 'PT892341');
    expect(joinResult.examTitle, 'Vật lý 12');
    expect(joinResult.teacherName, 'Thầy Hưng');
    expect(joinResult.isWaiting, isTrue);
  });

  test('parses student room state with peers and attempt', () {
    final state = StudentRoomState.fromJson({
      'roomId': 'room-1',
      'code': 'PT892341',
      'name': 'Kiểm tra giữa kỳ',
      'status': 'live',
      'examId': 'exam-1',
      'examTitle': 'Vật lý 12',
      'subject': 'Vật lý',
      'durationMinutes': 45,
      'teacherName': 'Thầy Hưng',
      'participantStatus': 'approved',
      'attemptId': 'att-123',
      'participantCount': 3,
      'participants': [
        {'id': 'p-1', 'name': 'Bạn', 'status': 'approved', 'isSelf': true},
        {'id': 'p-2', 'name': 'Hải Nam', 'status': 'approved', 'isSelf': false},
      ],
    });

    expect(state.isLive, isTrue);
    expect(state.attemptId, 'att-123');
    expect(state.participants.length, 2);
    expect(state.participants.first.isSelf, isTrue);
  });

  test('parses room leaderboard entries', () {
    final entry = RoomLeaderboardEntry.fromJson({
      'rank': 1,
      'participantId': 'part-1',
      'name': 'Nguyễn Văn A',
      'status': 'submitted',
      'score': 9.5,
      'correctCount': 38,
      'totalQuestions': 40,
      'durationSeconds': 1200,
      'submittedAt': '2026-09-03T20:00:00Z',
    });

    expect(entry.rank, 1);
    expect(entry.name, 'Nguyễn Văn A');
    expect(entry.score, 9.5);
    expect(entry.isSubmitted, isTrue);
    expect(entry.durationFormatted, '20:00');
  });
}
