import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class RoomParticipant {
  const RoomParticipant({required this.id, required this.name, required this.status});
  final String id;
  final String name;
  final String status;

  factory RoomParticipant.fromJson(Map<String, dynamic> json) => RoomParticipant(
        id: json['id'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
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

class RoomRepository {
  RoomRepository(this._client);
  final SupabaseClient _client;

  Future<TeacherRoomDashboard> create({required String examId, required String name, String? password}) async {
    final result = await _client.rpc('create_teacher_room', params: {
      'p_exam_id': examId,
      'p_name': name,
      'p_password': password,
      'p_max_participants': 50,
    });
    return dashboard(_map(result)['id'] as String);
  }

  Future<TeacherRoomDashboard> dashboard(String roomId) async => TeacherRoomDashboard.fromJson(
        _map(await _client.rpc('teacher_room_dashboard', params: {'p_room_id': roomId})),
      );

  Future<TeacherRoomDashboard> start(String roomId) async => TeacherRoomDashboard.fromJson(
        _map(await _client.rpc('start_teacher_room', params: {'p_room_id': roomId})),
      );

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) return Map<String, dynamic>.from(jsonDecode(value) as Map);
    throw const FormatException('Invalid room response.');
  }
}
