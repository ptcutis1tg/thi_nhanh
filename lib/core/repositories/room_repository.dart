import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class RoomParticipant {
  const RoomParticipant({
    required this.id,
    required this.name,
    required this.status,
    this.isSelf = false,
  });

  final String id;
  final String name;
  final String status;
  final bool isSelf;

  factory RoomParticipant.fromJson(Map<String, dynamic> json) => RoomParticipant(
        id: json['id'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        isSelf: (json['isSelf'] as bool?) ?? false,
      );
}

class TeacherRoomDashboard {
  const TeacherRoomDashboard({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    required this.examTitle,
    required this.subject,
    required this.durationMinutes,
    required this.maxParticipants,
    required this.participants,
  });

  final String id;
  final String code;
  final String name;
  final String status;
  final String examTitle;
  final String subject;
  final int durationMinutes;
  final int maxParticipants;
  final List<RoomParticipant> participants;

  bool get isWaiting => status == 'waiting';
  bool get isLive => status == 'live';

  factory TeacherRoomDashboard.fromJson(Map<String, dynamic> json) => TeacherRoomDashboard(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        examTitle: json['examTitle'] as String,
        subject: json['subject'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 50,
        participants: ((json['participants'] as List<dynamic>?) ?? const [])
            .map((item) => RoomParticipant.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class StudentJoinResult {
  const StudentJoinResult({
    required this.roomId,
    required this.participantId,
    required this.code,
    required this.name,
    required this.status,
    required this.examId,
    required this.examTitle,
    required this.subject,
    required this.durationMinutes,
    required this.teacherName,
    this.guestToken,
    this.attemptId,
  });

  final String roomId;
  final String participantId;
  final String code;
  final String name;
  final String status;
  final String examId;
  final String examTitle;
  final String subject;
  final int durationMinutes;
  final String teacherName;
  final String? guestToken;
  final String? attemptId;

  bool get isWaiting => status == 'waiting';
  bool get isLive => status == 'live';

  factory StudentJoinResult.fromJson(Map<String, dynamic> json) => StudentJoinResult(
        roomId: json['roomId'] as String,
        participantId: json['participantId'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        examId: json['examId'] as String,
        examTitle: json['examTitle'] as String,
        subject: json['subject'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        teacherName: json['teacherName'] as String,
        guestToken: json['guestToken'] as String?,
        attemptId: json['attemptId'] as String?,
      );
}

class StudentRoomState {
  const StudentRoomState({
    required this.roomId,
    required this.code,
    required this.name,
    required this.status,
    required this.examId,
    required this.examTitle,
    required this.subject,
    required this.durationMinutes,
    required this.teacherName,
    required this.participantStatus,
    required this.participantCount,
    required this.participants,
    this.attemptId,
  });

  final String roomId;
  final String code;
  final String name;
  final String status;
  final String examId;
  final String examTitle;
  final String subject;
  final int durationMinutes;
  final String teacherName;
  final String participantStatus;
  final int participantCount;
  final List<RoomParticipant> participants;
  final String? attemptId;

  bool get isWaiting => status == 'waiting';
  bool get isLive => status == 'live';
  bool get isClosed => status == 'closed';

  factory StudentRoomState.fromJson(Map<String, dynamic> json) => StudentRoomState(
        roomId: json['roomId'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        examId: json['examId'] as String,
        examTitle: json['examTitle'] as String,
        subject: json['subject'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        teacherName: json['teacherName'] as String,
        participantStatus: json['participantStatus'] as String,
        participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
        attemptId: json['attemptId'] as String?,
        participants: ((json['participants'] as List<dynamic>?) ?? const [])
            .map((item) => RoomParticipant.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class RoomLeaderboardEntry {
  const RoomLeaderboardEntry({
    required this.rank,
    required this.participantId,
    required this.name,
    required this.status,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    this.durationSeconds,
    this.submittedAt,
  });

  final int rank;
  final String participantId;
  final String name;
  final String status;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final int? durationSeconds;
  final String? submittedAt;

  bool get isSubmitted => status == 'submitted' || status == 'expired';

  String get durationFormatted {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory RoomLeaderboardEntry.fromJson(Map<String, dynamic> json) => RoomLeaderboardEntry(
        rank: (json['rank'] as num).toInt(),
        participantId: json['participantId'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        score: (json['score'] as num).toDouble(),
        correctCount: (json['correctCount'] as num).toInt(),
        totalQuestions: (json['totalQuestions'] as num).toInt(),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        submittedAt: json['submittedAt'] as String?,
      );
}

class RoomRepository {
  RoomRepository(this._client);
  final SupabaseClient _client;

  Future<TeacherRoomDashboard> create({
    required String examId,
    required String name,
    String? password,
    int maxParticipants = 50,
  }) async {
    final result = await _client.rpc('create_teacher_room', params: {
      'p_exam_id': examId,
      'p_name': name,
      'p_password': password,
      'p_max_participants': maxParticipants,
    });
    return dashboard(_map(result)['id'] as String);
  }

  Future<TeacherRoomDashboard> dashboard(String roomId) async => TeacherRoomDashboard.fromJson(
        _map(await _client.rpc('teacher_room_dashboard', params: {'p_room_id': roomId})),
      );

  Future<TeacherRoomDashboard> start(String roomId) async => TeacherRoomDashboard.fromJson(
        _map(await _client.rpc('start_teacher_room', params: {'p_room_id': roomId})),
      );

  Future<StudentJoinResult> joinRoom({
    required String code,
    String? password,
    String? guestName,
  }) async {
    final result = await _client.rpc('join_student_room', params: {
      'p_code': code,
      'p_password': password,
      'p_guest_name': guestName,
    });
    return StudentJoinResult.fromJson(_map(result));
  }

  Future<StudentRoomState> getStudentRoomState({
    required String roomId,
    required String participantId,
    String? guestToken,
  }) async {
    final result = await _client.rpc('get_student_room_state', params: {
      'p_room_id': roomId,
      'p_participant_id': participantId,
      'p_guest_token': guestToken,
    });
    return StudentRoomState.fromJson(_map(result));
  }

  Future<List<RoomLeaderboardEntry>> getRoomLeaderboard(String roomId) async {
    final result = await _client.rpc('get_room_leaderboard', params: {
      'p_room_id': roomId,
    });
    final list = (result as List<dynamic>?) ?? const [];
    return list
        .map((item) => RoomLeaderboardEntry.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) return Map<String, dynamic>.from(jsonDecode(value) as Map);
    throw const FormatException('Invalid room response.');
  }
}
