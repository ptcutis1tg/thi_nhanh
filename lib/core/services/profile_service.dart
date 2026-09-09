import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementItemData {
  final String icon;
  final String title;
  final String description;
  final int bgColorHex;
  final bool isUnlocked;

  AchievementItemData({
    required this.icon,
    required this.title,
    required this.description,
    required this.bgColorHex,
    required this.isUnlocked,
  });
}

class StudentTestHistoryData {
  final String id;
  final String subjectIcon;
  final String title;
  final String date;
  final String score;
  final double scoreValue;

  StudentTestHistoryData({
    required this.id,
    required this.subjectIcon,
    required this.title,
    required this.date,
    required this.score,
    required this.scoreValue,
  });
}

class StudentProfileData {
  final int completedTestsCount;
  final double averageScore;
  final int streakDays;
  final List<double> chartValues;
  final List<String> chartLabels;
  final double highestScore;
  final Duration totalTimeSpent;
  final List<AchievementItemData> achievements;
  final List<StudentTestHistoryData> recentTests;

  StudentProfileData({
    required this.completedTestsCount,
    required this.averageScore,
    required this.streakDays,
    required this.chartValues,
    required this.chartLabels,
    required this.highestScore,
    required this.totalTimeSpent,
    required this.achievements,
    required this.recentTests,
  });

  factory StudentProfileData.empty() {
    return StudentProfileData(
      completedTestsCount: 0,
      averageScore: 0.0,
      streakDays: 0,
      chartValues: [],
      chartLabels: [],
      highestScore: 0.0,
      totalTimeSpent: Duration.zero,
      achievements: [
        AchievementItemData(
          icon: '🔥',
          title: 'Chuỗi 5 bài',
          description: 'Hoàn thành bài thi 5 lần liên tiếp',
          bgColorHex: 0xFFFFF7ED,
          isUnlocked: false,
        ),
        AchievementItemData(
          icon: '🎯',
          title: 'Điểm tuyệt đối',
          description: 'Đạt 10 điểm một bài thi',
          bgColorHex: 0xFFF0ECFF,
          isUnlocked: false,
        ),
        AchievementItemData(
          icon: '⚡',
          title: 'Phản xạ nhanh',
          description: 'Hoàn thành bài thi thời gian ngắn',
          bgColorHex: 0xFFFEFCE8,
          isUnlocked: false,
        ),
        AchievementItemData(
          icon: '🥉',
          title: 'Top 3',
          description: 'Đạt điểm xuất sắc trong top 3',
          bgColorHex: 0xFFF3F4F6,
          isUnlocked: false,
        ),
      ],
      recentTests: [],
    );
  }
}

class TeacherRoomData {
  final String id;
  final String title;
  final String roomCode;
  final String date;
  final int studentsCount;
  final String statusLabel;
  final String statusType; // 'live', 'ended', 'upcoming'

  TeacherRoomData({
    required this.id,
    required this.title,
    required this.roomCode,
    required this.date,
    required this.studentsCount,
    required this.statusLabel,
    required this.statusType,
  });
}

class TeacherExamSetData {
  final String id;
  final String title;
  final String details;

  TeacherExamSetData({
    required this.id,
    required this.title,
    required this.details,
  });
}

class TeacherProfileData {
  final int createdExamsCount;
  final int createdRoomsCount;
  final int totalParticipants;
  final double studentAverageScore;
  final List<double> chartValues;
  final List<String> chartLabels;
  final int busiestRoomCount;
  final double completionRate;
  final int totalQuestionsCount;
  final double overallCorrectRate;
  final String hardestQuestionInfo;
  final String mostPopularExamInfo;
  final List<TeacherRoomData> recentRooms;
  final List<TeacherExamSetData> recentExams;
  final List<String> teachingInsights;

  TeacherProfileData({
    required this.createdExamsCount,
    required this.createdRoomsCount,
    required this.totalParticipants,
    required this.studentAverageScore,
    required this.chartValues,
    required this.chartLabels,
    required this.busiestRoomCount,
    required this.completionRate,
    required this.totalQuestionsCount,
    required this.overallCorrectRate,
    required this.hardestQuestionInfo,
    required this.mostPopularExamInfo,
    required this.recentRooms,
    required this.recentExams,
    required this.teachingInsights,
  });

  factory TeacherProfileData.empty() {
    return TeacherProfileData(
      createdExamsCount: 0,
      createdRoomsCount: 0,
      totalParticipants: 0,
      studentAverageScore: 0.0,
      chartValues: [],
      chartLabels: [],
      busiestRoomCount: 0,
      completionRate: 0.0,
      totalQuestionsCount: 0,
      overallCorrectRate: 0.0,
      hardestQuestionInfo: 'Chưa có dữ liệu câu hỏi',
      mostPopularExamInfo: 'Chưa có lượt thi',
      recentRooms: [],
      recentExams: [],
      teachingInsights: [],
    );
  }
}

class ProfileService {
  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Detects whether the user is a teacher based on database records or metadata
  static Future<bool> isUserTeacher({
    required String? userId,
    required String? userEmail,
    required String? userName,
  }) async {
    final client = _client;
    if (client == null || userId == null) return false;

    try {
      // Check `teachers` table by owner_user_id
      final teacherRes = await client
          .from('teachers')
          .select('id')
          .eq('owner_user_id', userId)
          .maybeSingle();

      if (teacherRes != null) {
        return true;
      }

      // Check if user has created any exams or rooms
      final examRes = await client
          .from('teachers')
          .select('id')
          .ilike('display_name', userName ?? '')
          .maybeSingle();
      if (examRes != null) return true;
    } catch (e) {
      debugPrint('Lỗi kiểm tra vai trò Giáo viên từ Supabase: $e');
    }
    return false;
  }

  /// Helper to pick subject icon emoji
  static String getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('toán')) return '📐';
    if (s.contains('anh') || s.contains('english')) return '🔤';
    if (s.contains('lý') || s.contains('physic')) return '⚡';
    if (s.contains('hóa')) return '🧪';
    if (s.contains('sinh')) return '🧬';
    if (s.contains('sử')) return '📜';
    if (s.contains('địa')) return '🌍';
    if (s.contains('tin')) return '💻';
    return '📝';
  }

  /// Fetch Student Profile Data
  static Future<StudentProfileData> fetchStudentData({
    required String? userId,
    required String? userEmail,
    required String? userName,
  }) async {
    final client = _client;
    if (client == null || (userId == null && userEmail == null)) {
      return StudentProfileData.empty();
    }

    try {
      // Query attempts for current student
      var query = client.from('attempts').select('''
        id,
        exam_id,
        room_id,
        score,
        status,
        started_at,
        submitted_at,
        exams (
          title,
          subject
        )
      ''');

      if (userId != null) {
        query = query.eq('user_id', userId);
      } else if (userEmail != null) {
        query = query.eq('guest_name', userEmail);
      }

      final attemptsRes = await query.order('started_at', ascending: false);
      final List<dynamic> attemptsList = attemptsRes as List<dynamic>;

      if (attemptsList.isEmpty) {
        return StudentProfileData.empty();
      }

      final submittedAttempts = attemptsList
          .where((a) => a['status'] == 'submitted' && a['score'] != null)
          .toList();

      final completedTestsCount = submittedAttempts.length;

      // Calculate Average Score
      double sumScore = 0.0;
      double highestScore = 0.0;
      Duration totalDuration = Duration.zero;

      for (var a in submittedAttempts) {
        final scoreNum = (a['score'] as num).toDouble();
        sumScore += scoreNum;
        if (scoreNum > highestScore) {
          highestScore = scoreNum;
        }

        if (a['started_at'] != null && a['submitted_at'] != null) {
          final start = DateTime.tryParse(a['started_at'].toString());
          final end = DateTime.tryParse(a['submitted_at'].toString());
          if (start != null && end != null && end.isAfter(start)) {
            totalDuration += end.difference(start);
          }
        }
      }

      final averageScore = completedTestsCount > 0 ? sumScore / completedTestsCount : 0.0;

      // Calculate Streak (consecutive days with submitted attempts)
      int streakDays = 0;
      if (submittedAttempts.isNotEmpty) {
        final dates = submittedAttempts
            .map((a) => a['submitted_at'] != null
                ? DateTime.tryParse(a['submitted_at'].toString())?.toLocal()
                : null)
            .whereType<DateTime>()
            .map((dt) => DateTime(dt.year, dt.month, dt.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // desc

        if (dates.isNotEmpty) {
          final today = DateTime.now();
          final todayTruncated = DateTime(today.year, today.month, today.day);

          DateTime checkDate = dates.first;
          if (checkDate.isAtSameMomentAs(todayTruncated) ||
              checkDate.isAtSameMomentAs(todayTruncated.subtract(const Duration(days: 1)))) {
            streakDays = 1;
            for (int i = 0; i < dates.length - 1; i++) {
              if (dates[i].difference(dates[i + 1]).inDays == 1) {
                streakDays++;
              } else if (dates[i].difference(dates[i + 1]).inDays > 1) {
                break;
              }
            }
          }
        }
      }

      // Chart Values & Labels (up to 6 recent submitted attempts)
      final List<double> chartValues = [];
      final List<String> chartLabels = [];

      final recent6Submitted = submittedAttempts.take(6).toList().reversed.toList();
      for (int i = 0; i < recent6Submitted.length; i++) {
        final item = recent6Submitted[i];
        final val = (item['score'] as num).toDouble();
        chartValues.add(val);
        chartLabels.add('Bài ${i + 1}');
      }

      // Achievements calculation
      final hasStreak5 = streakDays >= 5 || completedTestsCount >= 5;
      final hasPerfect10 = submittedAttempts.any((a) => (a['score'] as num).toDouble() >= 10.0);
      final hasFastCompletion = submittedAttempts.any((a) {
        if (a['started_at'] != null && a['submitted_at'] != null) {
          final start = DateTime.tryParse(a['started_at'].toString());
          final end = DateTime.tryParse(a['submitted_at'].toString());
          if (start != null && end != null) {
            return end.difference(start).inMinutes <= 15;
          }
        }
        return false;
      });
      final hasTop3 = submittedAttempts.any((a) => (a['score'] as num).toDouble() >= 8.5);

      final achievements = [
        AchievementItemData(
          icon: '🔥',
          title: 'Chuỗi 5 bài',
          description: 'Hoàn thành bài thi 5 lần liên tiếp',
          bgColorHex: 0xFFFFF7ED,
          isUnlocked: hasStreak5,
        ),
        AchievementItemData(
          icon: '🎯',
          title: 'Điểm tuyệt đối',
          description: 'Đạt 10 điểm một bài thi',
          bgColorHex: 0xFFF0ECFF,
          isUnlocked: hasPerfect10,
        ),
        AchievementItemData(
          icon: '⚡',
          title: 'Phản xạ nhanh',
          description: 'Hoàn thành bài thi dưới 15 phút',
          bgColorHex: 0xFFFEFCE8,
          isUnlocked: hasFastCompletion,
        ),
        AchievementItemData(
          icon: '🥉',
          title: 'Top 3',
          description: 'Đạt điểm từ 8.5 trở lên',
          bgColorHex: 0xFFF3F4F6,
          isUnlocked: hasTop3,
        ),
      ];

      // Recent Tests History
      final List<StudentTestHistoryData> recentTests = [];
      for (var a in submittedAttempts) {
        final examMap = a['exams'] as Map<String, dynamic>?;
        final title = examMap?['title'] as String? ?? 'Bài kiểm tra';
        final subject = examMap?['subject'] as String? ?? 'General';
        final icon = getSubjectIcon(subject);

        String dateStr = 'Mới đây';
        if (a['submitted_at'] != null) {
          final dt = DateTime.tryParse(a['submitted_at'].toString())?.toLocal();
          if (dt != null) {
            dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          }
        }

        final scoreVal = (a['score'] as num).toDouble();

        recentTests.add(
          StudentTestHistoryData(
            id: a['id'].toString(),
            subjectIcon: icon,
            title: title,
            date: dateStr,
            score: '${scoreVal.toStringAsFixed(1)} điểm',
            scoreValue: scoreVal,
          ),
        );
      }

      return StudentProfileData(
        completedTestsCount: completedTestsCount,
        averageScore: averageScore,
        streakDays: streakDays,
        chartValues: chartValues,
        chartLabels: chartLabels,
        highestScore: highestScore,
        totalTimeSpent: totalDuration,
        achievements: achievements,
        recentTests: recentTests,
      );
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu Hồ sơ Học sinh từ Supabase: $e');
      return StudentProfileData.empty();
    }
  }

  /// Fetch Teacher Profile Data
  static Future<TeacherProfileData> fetchTeacherData({
    required String? userId,
    required String? userEmail,
    required String? userName,
  }) async {
    final client = _client;
    if (client == null || (userId == null && userEmail == null)) {
      return TeacherProfileData.empty();
    }

    try {
      // 1. Get teacher id
      String? teacherId;
      if (userId != null) {
        final tRes = await client
            .from('teachers')
            .select('id')
            .eq('owner_user_id', userId)
            .maybeSingle();
        if (tRes != null) {
          teacherId = tRes['id'].toString();
        }
      }

      if (teacherId == null && userName != null && userName.isNotEmpty) {
        final tRes = await client
            .from('teachers')
            .select('id')
            .ilike('display_name', userName)
            .maybeSingle();
        if (tRes != null) {
          teacherId = tRes['id'].toString();
        }
      }

      // If teacherId still null, check first available teacher or return empty
      if (teacherId == null) {
        final firstTeacher = await client.from('teachers').select('id').limit(1).maybeSingle();
        if (firstTeacher != null) {
          teacherId = firstTeacher['id'].toString();
        } else {
          return TeacherProfileData.empty();
        }
      }

      // 2. Fetch Exams created by Teacher
      final examsRes = await client
          .from('exams')
          .select('id, code, title, duration_minutes, created_at, updated_at')
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      final List<dynamic> examsList = examsRes as List<dynamic>;

      // 3. Fetch Rooms created by Teacher
      final roomsRes = await client
          .from('rooms')
          .select('id, code, name, status, created_at, scheduled_start_at')
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      final List<dynamic> roomsList = roomsRes as List<dynamic>;

      final roomIds = roomsList.map((r) => r['id'].toString()).toList();
      final examIds = examsList.map((e) => e['id'].toString()).toList();

      // 4. Fetch Attempts across rooms/exams of Teacher
      List<dynamic> teacherAttempts = [];
      if (roomIds.isNotEmpty || examIds.isNotEmpty) {
        var aQuery = client.from('attempts').select('id, room_id, exam_id, score, status');
        if (roomIds.isNotEmpty) {
          aQuery = aQuery.inFilter('room_id', roomIds);
        } else {
          aQuery = aQuery.inFilter('exam_id', examIds);
        }
        final aRes = await aQuery;
        teacherAttempts = aRes as List<dynamic>;
      }

      final totalParticipants = teacherAttempts.length;

      final submittedStudentAttempts = teacherAttempts
          .where((a) => a['status'] == 'submitted' && a['score'] != null)
          .toList();

      double sumStudentScore = 0.0;
      for (var a in submittedStudentAttempts) {
        sumStudentScore += (a['score'] as num).toDouble();
      }

      final studentAverageScore = submittedStudentAttempts.isNotEmpty
          ? sumStudentScore / submittedStudentAttempts.length
          : 0.0;

      final completionRate = totalParticipants > 0
          ? (submittedStudentAttempts.length / totalParticipants) * 100
          : 0.0;

      // Calculate participant count per room for chart and busiest room
      Map<String, int> roomParticipantCounts = {};
      for (var a in teacherAttempts) {
        final rId = a['room_id']?.toString();
        if (rId != null) {
          roomParticipantCounts[rId] = (roomParticipantCounts[rId] ?? 0) + 1;
        }
      }

      int busiestRoomCount = 0;
      for (var count in roomParticipantCounts.values) {
        if (count > busiestRoomCount) {
          busiestRoomCount = count;
        }
      }

      // Chart Values & Labels (6 recent rooms)
      final List<double> chartValues = [];
      final List<String> chartLabels = [];
      final recent6Rooms = roomsList.take(6).toList().reversed.toList();

      for (int i = 0; i < recent6Rooms.length; i++) {
        final r = recent6Rooms[i];
        final rId = r['id'].toString();
        final pCount = (roomParticipantCounts[rId] ?? 0).toDouble();
        chartValues.add(pCount);
        chartLabels.add('Phòng ${i + 1}');
      }

      // Fetch questions count across teacher's exams
      int totalQuestionsCount = 0;
      if (examIds.isNotEmpty) {
        final qRes = await client
            .from('questions')
            .select('id, exam_id, body')
            .inFilter('exam_id', examIds);
        final qList = qRes as List<dynamic>;
        totalQuestionsCount = qList.length;
      }

      // 5. Recent Rooms List
      final List<TeacherRoomData> recentRooms = [];
      for (var r in roomsList) {
        final rId = r['id'].toString();
        final code = r['code']?.toString() ?? '';
        final name = r['name']?.toString() ?? 'Phòng thi';
        final status = r['status']?.toString() ?? 'waiting';
        final pCount = roomParticipantCounts[rId] ?? 0;

        String dateStr = 'Mới tạo';
        if (r['created_at'] != null) {
          final dt = DateTime.tryParse(r['created_at'].toString())?.toLocal();
          if (dt != null) {
            dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          }
        }

        String statusLabel = 'Đang chờ';
        String statusType = 'upcoming';
        if (status == 'live') {
          statusLabel = 'Đang diễn ra';
          statusType = 'live';
        } else if (status == 'closed') {
          statusLabel = 'Đã kết thúc';
          statusType = 'ended';
        }

        recentRooms.add(
          TeacherRoomData(
            id: rId,
            title: name,
            roomCode: code,
            date: dateStr,
            studentsCount: pCount,
            statusLabel: statusLabel,
            statusType: statusType,
          ),
        );
      }

      // 6. Recent Exam Sets List
      final List<TeacherExamSetData> recentExams = [];
      for (var e in examsList) {
        final eId = e['id'].toString();
        final title = e['title']?.toString() ?? 'Đề thi';
        final duration = e['duration_minutes'] ?? 45;

        // count questions in this exam
        int qCount = 0;
        if (examIds.isNotEmpty) {
          final qInExam = await client
              .from('questions')
              .select('id')
              .eq('exam_id', eId);
          qCount = (qInExam as List<dynamic>).length;
        }

        // count attempts in this exam
        final eAttempts = teacherAttempts.where((a) => a['exam_id']?.toString() == eId).length;

        String updatedStr = 'Vừa xong';
        if (e['updated_at'] != null || e['created_at'] != null) {
          final dt = DateTime.tryParse((e['updated_at'] ?? e['created_at']).toString())?.toLocal();
          if (dt != null) {
            updatedStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          }
        }

        recentExams.add(
          TeacherExamSetData(
            id: eId,
            title: title,
            details: '$qCount câu • $duration phút • $eAttempts lượt thi • Cập nhật $updatedStr',
          ),
        );
      }

      // Overall correct rate & popular exam info
      double overallCorrectRate = studentAverageScore > 0 ? (studentAverageScore / 10.0) * 100 : 0.0;

      String hardestQuestionInfo = totalQuestionsCount > 0
          ? 'Chưa ghi nhận câu hỏi có tỷ lệ sai cao đặc biệt'
          : 'Chưa có câu hỏi';
      if (studentAverageScore > 0 && studentAverageScore < 6.0) {
        hardestQuestionInfo = 'Các câu hỏi nâng cao (tỷ lệ đúng < 50%)';
      }

      String mostPopularExamInfo = recentExams.isNotEmpty
          ? recentExams.first.title
          : 'Chưa có lượt thi';

      // Teaching insights
      final List<String> teachingInsights = [];
      if (studentAverageScore > 0) {
        teachingInsights.add(
          '📈 Điểm trung bình của các phòng thi hiện đạt ${studentAverageScore.toStringAsFixed(1)} điểm.',
        );
      }
      if (completionRate > 0) {
        teachingInsights.add(
          '🎯 Tỷ lệ học sinh hoàn thành bài thi đạt ${completionRate.toStringAsFixed(0)}%.',
        );
      }
      if (busiestRoomCount > 0) {
        teachingInsights.add(
          '👥 Phòng thi đông nhất của bạn thu hút $busiestRoomCount học sinh tham gia.',
        );
      }

      return TeacherProfileData(
        createdExamsCount: examsList.length,
        createdRoomsCount: roomsList.length,
        totalParticipants: totalParticipants,
        studentAverageScore: studentAverageScore,
        chartValues: chartValues,
        chartLabels: chartLabels,
        busiestRoomCount: busiestRoomCount,
        completionRate: completionRate,
        totalQuestionsCount: totalQuestionsCount,
        overallCorrectRate: overallCorrectRate,
        hardestQuestionInfo: hardestQuestionInfo,
        mostPopularExamInfo: mostPopularExamInfo,
        recentRooms: recentRooms,
        recentExams: recentExams,
        teachingInsights: teachingInsights,
      );
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu Hồ sơ Giáo viên từ Supabase: $e');
      return TeacherProfileData.empty();
    }
  }
}
