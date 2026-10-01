import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('ProfileService Resilience and Fallbacks', () {
    test('StudentProfileData.empty returns default valid state', () {
      final data = StudentProfileData.empty();
      expect(data.completedTestsCount, 0);
      expect(data.averageScore, 0.0);
      expect(data.streakDays, 0);
      expect(data.chartValues, isEmpty);
      expect(data.chartLabels, isEmpty);
      expect(data.highestScore, 0.0);
      expect(data.totalTimeSpent, Duration.zero);
      expect(data.achievements, hasLength(4));
      expect(data.recentTests, isEmpty);
    });

    test('TeacherProfileData.empty returns default valid state', () {
      final data = TeacherProfileData.empty();
      expect(data.createdExamsCount, 0);
      expect(data.createdRoomsCount, 0);
      expect(data.totalParticipants, 0);
      expect(data.studentAverageScore, 0.0);
      expect(data.recentRooms, isEmpty);
      expect(data.recentExams, isEmpty);
      expect(data.teachingInsights, isEmpty);
    });

    test('getSubjectIcon returns appropriate emoji for each subject', () {
      expect(ProfileService.getSubjectIcon('Toán 12'), '📐');
      expect(ProfileService.getSubjectIcon('Tiếng Anh'), '🔤');
      expect(ProfileService.getSubjectIcon('Vật Lý'), '⚡');
      expect(ProfileService.getSubjectIcon('Hóa học'), '🧪');
      expect(ProfileService.getSubjectIcon('Sinh học'), '🧬');
      expect(ProfileService.getSubjectIcon('Lịch sử'), '📜');
      expect(ProfileService.getSubjectIcon('Địa lý'), '🌍');
      expect(ProfileService.getSubjectIcon('Tin học'), '💻');
      expect(ProfileService.getSubjectIcon('Khác'), '📝');
    });

    test('fetchStudentData returns empty if userId and email are null', () async {
      final data = await ProfileService.fetchStudentData(
        userId: null,
        userEmail: null,
        userName: null,
      );
      expect(data.completedTestsCount, 0);
    });

    test('fetchTeacherDataSecure returns empty if no client or user', () async {
      final data = await ProfileService.fetchTeacherDataSecure(
        userId: null,
        userEmail: null,
        userName: null,
      );
      expect(data.createdExamsCount, 0);
    });
  });
}
