import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_retry_helper.dart';

class TeacherExamSummary {
  const TeacherExamSummary({
    required this.id,
    required this.title,
    required this.subject,
    required this.durationMinutes,
    required this.questionCount,
    required this.status,
    this.code = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String subject;
  final int durationMinutes;
  final int questionCount;
  final String status;
  final String code;
  final DateTime? createdAt;

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';

  factory TeacherExamSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['createdAt'] as String);
      } catch (_) {}
    }

    return TeacherExamSummary(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Đề thi',
      subject: json['subject'] as String? ?? 'Chung',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      code: json['code'] as String? ?? '',
      createdAt: parsedDate,
    );
  }
}

class TeacherExamRepository {
  TeacherExamRepository(this._client);
  final SupabaseClient _client;

  Future<String> saveDraft({String? examId, required String title, required String subject, required int durationMinutes, required List<Map<String, dynamic>> questions}) async {
    final value = await SupabaseRetryHelper.run(
      () => _client.rpc('save_teacher_exam_draft', params: {
        'p_exam_id': examId,
        'p_title': title,
        'p_subject': subject,
        'p_duration_minutes': durationMinutes,
        'p_questions': questions,
      }),
    );
    return _map(value)['id'] as String;
  }

  Future<List<TeacherExamSummary>> summaries() async {
    final value = await SupabaseRetryHelper.run(
      () => _client.rpc('teacher_exam_summaries'),
    );
    return (_list(value)).map((item) => TeacherExamSummary.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>?> draft(String examId) async {
    final value = await SupabaseRetryHelper.run(
      () => _client.rpc('teacher_exam_draft', params: {'p_exam_id': examId}),
    );
    if (value == null) return null;
    return _map(value);
  }

  Future<void> publish(String examId) => SupabaseRetryHelper.run(
        () => _client.rpc('publish_teacher_exam', params: {'p_exam_id': examId}),
      );

  Future<void> deleteDraft(String examId) => SupabaseRetryHelper.run(
        () => _client.from('exams').delete().eq('id', examId).eq('status', 'draft'),
      );

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) return Map<String, dynamic>.from(jsonDecode(value) as Map);
    throw const FormatException('Invalid teacher exam response.');
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    final list = value is String ? jsonDecode(value) as List<dynamic> : value as List<dynamic>;
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
