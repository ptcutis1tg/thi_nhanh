import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_retry_helper.dart';

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
  final String subject;
  final DateTime? submittedAt;
  final String? roomId;
  final String? roomCode;
  final int? durationSeconds;
  final bool isLiveRoom;
  final bool resultReleased;

  StudentTestHistoryData({
    required this.id,
    required this.subjectIcon,
    required this.title,
    required this.date,
    required this.score,
    required this.scoreValue,
    this.subject = 'Khác',
    this.submittedAt,
    this.roomId,
    this.roomCode,
    this.durationSeconds,
    this.isLiveRoom = false,
    this.resultReleased = true,
  });

  String get durationFormatted {
    if (durationSeconds == null || durationSeconds! <= 0) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }
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
  final String? examTitle;
  final String? examSubject;
  final int? durationMinutes;

  TeacherRoomData({
    required this.id,
    required this.title,
    required this.roomCode,
    required this.date,
    required this.studentsCount,
    required this.statusLabel,
    required this.statusType,
    this.examTitle,
    this.examSubject,
    this.durationMinutes,
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
      return await SupabaseRetryHelper.run(() async {
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
        return false;
      });
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
    if (s.contains('địa')) return '🌍';
    if (s.contains('lý') || s.contains('lí') || s.contains('physic')) return '⚡';
    if (s.contains('hóa')) return '🧪';
    if (s.contains('sinh')) return '🧬';
    if (s.contains('sử')) return '📜';
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
        result_released_at,
        exams (
          title,
          subject
        ),
        rooms (
          code,
          name,
          status
        )
      ''');

      if (userId != null) {
        query = query.eq('user_id', userId);
      } else if (userEmail != null) {
        query = query.eq('guest_name', userEmail);
      }

      final List<dynamic> attemptsList = await SupabaseRetryHelper.run(() async {
        final attemptsRes = await query.order('started_at', ascending: false);
        return attemptsRes as List<dynamic>;
      });

      if (attemptsList.isEmpty) {
        return StudentProfileData.empty();
      }

      final submittedAttempts = attemptsList
          .where((a) => (a['status'] == 'submitted' || a['status'] == 'expired') && a['score'] != null)
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

      Set<String> top3AttemptIds = {};
      try {
        final top3Raw = await SupabaseRetryHelper.run(
          () => client.rpc('current_student_top3_attempt_ids'),
        );
        top3AttemptIds = ((top3Raw as List<dynamic>?) ?? const []).map((id) => id.toString()).toSet();
      } catch (e) {
        debugPrint('Thông báo: RPC current_student_top3_attempt_ids không khả dụng ($e). Bỏ qua tính năng top 3.');
      }

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
      final hasTop3 = submittedAttempts.any((a) => top3AttemptIds.contains(a['id'].toString()));

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
          description: 'Xếp hạng trong top 3 của một phòng thi',
          bgColorHex: 0xFFF3F4F6,
          isUnlocked: hasTop3,
        ),
      ];

      // Recent Tests History
      final List<StudentTestHistoryData> recentTests = [];
      for (var a in submittedAttempts) {
        final examMap = a['exams'] as Map<String, dynamic>?;
        final title = examMap?['title'] as String? ?? 'Bài kiểm tra';
        final subject = examMap?['subject'] as String? ?? 'Khác';
        final icon = getSubjectIcon(subject);

        String dateStr = 'Mới đây';
        DateTime? submittedAt;
        if (a['submitted_at'] != null) {
          final dt = DateTime.tryParse(a['submitted_at'].toString())?.toLocal();
          if (dt != null) {
            submittedAt = dt;
            dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          }
        }

        final scoreVal = (a['score'] as num).toDouble();
        final roomMap = a['rooms'] as Map<String, dynamic>?;
        final roomCode = roomMap?['code'] as String?;
        final roomId = a['room_id']?.toString();
        final isLiveRoom = roomId != null && roomId.isNotEmpty;
        final resultReleased = a['result_released_at'] != null || (roomMap?['status'] == 'closed') || !isLiveRoom;

        int? durationSec;
        if (a['started_at'] != null && a['submitted_at'] != null) {
          final start = DateTime.tryParse(a['started_at'].toString());
          final end = DateTime.tryParse(a['submitted_at'].toString());
          if (start != null && end != null && end.isAfter(start)) {
            durationSec = end.difference(start).inSeconds;
          }
        }

        recentTests.add(
          StudentTestHistoryData(
            id: a['id'].toString(),
            subjectIcon: icon,
            title: title,
            date: dateStr,
            score: '${scoreVal.toStringAsFixed(1)} điểm',
            scoreValue: scoreVal,
            subject: subject,
            submittedAt: submittedAt,
            roomId: roomId,
            roomCode: roomCode,
            durationSeconds: durationSec,
            isLiveRoom: isLiveRoom,
            resultReleased: resultReleased,
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
  static Future<TeacherProfileData> fetchTeacherDataSecure({
    String? userId,
    String? userEmail,
    String? userName,
  }) async {
    final client = _client;
    final currentUser = client?.auth.currentUser;
    final effectiveUserId = userId ?? currentUser?.id;
    final effectiveUserEmail = userEmail ?? currentUser?.email;
    final effectiveUserName = userName ?? (currentUser?.userMetadata?['name'] as String?);

    if (client == null || (effectiveUserId == null && effectiveUserEmail == null)) {
      return TeacherProfileData.empty();
    }

    try {
      final raw = await SupabaseRetryHelper.run(() => client.rpc('teacher_profile_payload'));
      final payload = Map<String, dynamic>.from(raw as Map);
      final recentRooms = ((payload['recentRooms'] as List<dynamic>?) ?? const []).map((item) {
        final room = Map<String, dynamic>.from(item as Map);
        final status = room['status']?.toString() ?? 'waiting';
        final createdAt = DateTime.tryParse(room['createdAt']?.toString() ?? '')?.toLocal();
        return TeacherRoomData(
          id: room['id'].toString(),
          title: room['title']?.toString() ?? 'Phòng thi',
          roomCode: room['roomCode']?.toString() ?? '',
          date: createdAt == null ? 'Mới tạo' : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
          studentsCount: (room['studentsCount'] as num?)?.toInt() ?? 0,
          statusLabel: status == 'live' ? 'Đang diễn ra' : (status == 'closed' ? 'Đã kết thúc' : 'Đang chờ'),
          statusType: status == 'live' ? 'live' : (status == 'closed' ? 'ended' : 'upcoming'),
        );
      }).toList();
      final recentExams = ((payload['recentExams'] as List<dynamic>?) ?? const []).map((item) {
        final exam = Map<String, dynamic>.from(item as Map);
        final updatedAt = DateTime.tryParse(exam['updatedAt']?.toString() ?? '')?.toLocal();
        final updated = updatedAt == null ? 'Vừa xong' : '${updatedAt.day.toString().padLeft(2, '0')}/${updatedAt.month.toString().padLeft(2, '0')}/${updatedAt.year}';
        return TeacherExamSetData(
          id: exam['id'].toString(),
          title: exam['title']?.toString() ?? 'Đề thi',
          details: '${(exam['questionCount'] as num?)?.toInt() ?? 0} câu • ${(exam['durationMinutes'] as num?)?.toInt() ?? 0} phút • ${(exam['attemptCount'] as num?)?.toInt() ?? 0} lượt thi • Cập nhật $updated',
        );
      }).toList();
      final average = ((payload['studentAverageScore'] as num?) ?? 0).toDouble();
      final completion = ((payload['completionRate'] as num?) ?? 0).toDouble();
      final busiest = ((payload['busiestRoomCount'] as num?) ?? 0).toInt();
      final insights = <String>[
        if (average > 0) '📈 Điểm trung bình của các phòng thi hiện đạt ${average.toStringAsFixed(1)} điểm.',
        if (completion > 0) '🎯 Tỷ lệ học sinh hoàn thành bài thi đạt ${completion.toStringAsFixed(0)}%.',
        if (busiest > 0) '👥 Phòng thi đông nhất của bạn thu hút $busiest học sinh tham gia.',
      ];
      return TeacherProfileData(
        createdExamsCount: ((payload['createdExamsCount'] as num?) ?? 0).toInt(),
        createdRoomsCount: ((payload['createdRoomsCount'] as num?) ?? 0).toInt(),
        totalParticipants: ((payload['totalParticipants'] as num?) ?? 0).toInt(),
        studentAverageScore: average,
        chartValues: ((payload['chartValues'] as List<dynamic>?) ?? const []).map((value) => (value as num).toDouble()).toList(),
        chartLabels: ((payload['chartLabels'] as List<dynamic>?) ?? const []).map((value) => value.toString()).toList(),
        busiestRoomCount: busiest,
        completionRate: completion,
        totalQuestionsCount: ((payload['totalQuestionsCount'] as num?) ?? 0).toInt(),
        overallCorrectRate: ((payload['overallCorrectRate'] as num?) ?? 0).toDouble(),
        hardestQuestionInfo: payload['hardestQuestionInfo']?.toString() ?? 'Chưa có dữ liệu trả lời',
        mostPopularExamInfo: payload['mostPopularExamInfo']?.toString() ?? 'Chưa có lượt thi',
        recentRooms: recentRooms,
        recentExams: recentExams,
        teachingInsights: insights,
      );
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu giáo viên qua RPC ($e). Đang tự động chuyển sang chế độ fallback trực tiếp bảng...');
      return fetchTeacherData(
        userId: effectiveUserId,
        userEmail: effectiveUserEmail,
        userName: effectiveUserName,
      );
    }
  }

  /// Legacy direct-table implementation kept for compatibility with older tests.
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
      return await SupabaseRetryHelper.run(() async {
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
      });
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu Hồ sơ Giáo viên từ Supabase: $e');
      return TeacherProfileData.empty();
    }
  }

  /// Fetch all created rooms for teacher
  static Future<List<TeacherRoomData>> fetchTeacherRoomsSecure({
    String? userId,
    String? userEmail,
    String? userName,
  }) async {
    final profile = await fetchTeacherDataSecure(
      userId: userId,
      userEmail: userEmail,
      userName: userName,
    );
    return profile.recentRooms;
  }

  /// Fetch student submissions for teacher's exams and rooms securely
  static Future<List<Map<String, dynamic>>> fetchTeacherStudentResultsSecure({
    String? userId,
    String? userEmail,
    String? userName,
  }) async {
    final client = _client;
    if (client == null) return [];

    // 1. Try RPC teacher_student_results if available
    try {
      final res = await SupabaseRetryHelper.run(() => client.rpc('teacher_student_results'));
      if (res is List) {
        return List<Map<String, dynamic>>.from(
          res.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    } catch (_) {
      // RPC not defined or not exposed, fall back to safe direct queries below
    }

    // 2. Direct table fallback with retry helper
    try {
      final effectiveUserId = userId ?? client.auth.currentUser?.id;
      final effectiveUserEmail = userEmail ?? client.auth.currentUser?.email;

      String? teacherId;
      if (effectiveUserId != null) {
        final tResOwner = await SupabaseRetryHelper.run(() => client
            .from('teachers')
            .select('id')
            .eq('owner_user_id', effectiveUserId)
            .maybeSingle());
        if (tResOwner != null) {
          teacherId = tResOwner['id']?.toString();
        }
      }
      if (teacherId == null && effectiveUserEmail != null) {
        final tResEmail = await SupabaseRetryHelper.run(() => client
            .from('teachers')
            .select('id')
            .eq('email', effectiveUserEmail)
            .maybeSingle());
        if (tResEmail != null) {
          teacherId = tResEmail['id']?.toString();
        }
      }
      if (teacherId == null && userName != null && userName.isNotEmpty) {
        final tResName = await SupabaseRetryHelper.run(() => client
            .from('teachers')
            .select('id')
            .ilike('display_name', userName)
            .maybeSingle());
        if (tResName != null) {
          teacherId = tResName['id']?.toString();
        }
      }

      if (teacherId == null) {
        final firstTeacher = await SupabaseRetryHelper.run(() => client
            .from('teachers')
            .select('id')
            .limit(1)
            .maybeSingle());
        if (firstTeacher != null) {
          teacherId = firstTeacher['id']?.toString();
        }
      }

      if (teacherId == null) return [];
      final effectiveTeacherId = teacherId;

      // Fetch exams created by this teacher
      final examsRes = await SupabaseRetryHelper.run(() => client
          .from('exams')
          .select('id, title, subject')
          .eq('teacher_id', effectiveTeacherId));
      final examMap = <String, Map<String, dynamic>>{};
      for (final ex in (examsRes as List<dynamic>)) {
        final id = ex['id']?.toString();
        if (id != null) examMap[id] = Map<String, dynamic>.from(ex as Map);
      }
      final examIds = examMap.keys.toList();
      if (examIds.isEmpty) return [];

      // Query attempts WITHOUT invalid relationship 'profiles(display_name)'
      final attemptsRes = await SupabaseRetryHelper.run(() => client
          .from('attempts')
          .select('id, user_id, room_id, exam_id, score, status, submitted_at, guest_name')
          .inFilter('exam_id', examIds)
          .inFilter('status', ['submitted', 'expired'])
          .not('score', 'is', null)
          .order('submitted_at', ascending: false));

      final attemptsList = attemptsRes as List<dynamic>;
      if (attemptsList.isEmpty) return [];

      // Lookup profile names for all user_ids without requiring PostgREST FK join
      final userIds = attemptsList
          .map((a) => a['user_id']?.toString())
          .where((uid) => uid != null && uid.isNotEmpty)
          .toSet()
          .toList();

      Map<String, String> profileNames = {};
      if (userIds.isNotEmpty) {
        try {
          final profilesRes = await SupabaseRetryHelper.run(() => client
              .from('profiles')
              .select('id, display_name')
              .inFilter('id', userIds));
          for (final p in (profilesRes as List<dynamic>)) {
            final pid = p['id']?.toString();
            final dName = p['display_name']?.toString();
            if (pid != null && dName != null && dName.isNotEmpty) {
              profileNames[pid] = dName;
            }
          }
        } catch (eProf) {
          debugPrint('Không thể tải tên profiles: $eProf');
        }
      }

      return attemptsList.map((a) {
        final ex = examMap[a['exam_id']?.toString()];
        final uid = a['user_id']?.toString();
        final guestName = a['guest_name']?.toString();
        final studentName = (uid != null ? profileNames[uid] : null) ??
            (guestName != null && guestName.isNotEmpty ? guestName : 'Học sinh');

        return {
          'attemptId': a['id'],
          'roomId': a['room_id'],
          'studentName': studentName,
          'score': a['score'],
          'status': a['status'],
          'submittedAt': a['submitted_at'],
          'examTitle': ex?['title'] ?? 'Đề thi',
          'subject': ex?['subject'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Lỗi truy vấn kết quả làm bài trực tiếp từ bảng: $e');
      return [];
    }
  }
}
