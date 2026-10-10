import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum QuestionReportCategory {
  wrongAnswer('wrong_answer', 'Đáp án đúng bị sai'),
  unclearQuestion('unclear_question', 'Câu hỏi chưa rõ'),
  typo('typo', 'Lỗi chính tả hoặc trình bày'),
  wrongExplanation('wrong_explanation', 'Lời giải chưa đúng'),
  other('other', 'Vấn đề khác');

  const QuestionReportCategory(this.value, this.label);
  final String value;
  final String label;
}

class QuestionReport {
  const QuestionReport({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.questionId,
    required this.questionPosition,
    required this.questionBody,
    required this.category,
    required this.detail,
    required this.status,
    required this.createdAt,
    this.teacherNote = '',
    this.resolvedAt,
  });

  final String id;
  final String examId;
  final String examTitle;
  final String questionId;
  final int questionPosition;
  final String questionBody;
  final String category;
  final String detail;
  final String status;
  final String teacherNote;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  QuestionReportCategory? get categoryInfo {
    for (final value in QuestionReportCategory.values) {
      if (value.value == category) return value;
    }
    return null;
  }

  factory QuestionReport.fromJson(Map<String, dynamic> json) => QuestionReport(
    id: json['id'] as String,
    examId: json['examId'] as String? ?? '',
    examTitle: json['examTitle'] as String? ?? 'Đề thi',
    questionId: json['questionId'] as String? ?? '',
    questionPosition: (json['questionPosition'] as num?)?.toInt() ?? 0,
    questionBody: json['questionBody'] as String? ?? '',
    category: json['category'] as String? ?? 'other',
    detail: json['detail'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    teacherNote: json['teacherNote'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    resolvedAt: DateTime.tryParse(json['resolvedAt']?.toString() ?? ''),
  );
}

class QuestionReportRepository {
  QuestionReportRepository([this._client]);

  final SupabaseClient? _client;
  static const _guestTokenPrefix = 'guest-attempt-token:';
  static const _localKey = 'local_question_reports_v1';

  Future<String> submit({
    required String attemptId,
    required String examId,
    required String examTitle,
    required String questionId,
    required int questionPosition,
    required String questionBody,
    required QuestionReportCategory category,
    String detail = '',
  }) async {
    final client = _client;
    if (client != null) {
      final prefs = await SharedPreferences.getInstance();
      final response = await client.rpc(
        'submit_question_report',
        params: {
          'p_attempt_id': attemptId,
          'p_question_id': questionId,
          'p_category': category.value,
          'p_detail': detail.trim().isEmpty ? null : detail.trim(),
          'p_guest_token': prefs.getString('$_guestTokenPrefix$attemptId'),
        },
      );
      return response.toString();
    }

    final id = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final reports = await _loadLocal();
    final duplicateIndex = reports.indexWhere(
      (item) =>
          item['attemptId'] == attemptId &&
          item['questionId'] == questionId &&
          item['category'] == category.value,
    );
    final report = <String, dynamic>{
      'id': id,
      'attemptId': attemptId,
      'examId': examId,
      'examTitle': examTitle,
      'questionId': questionId,
      'questionPosition': questionPosition,
      'questionBody': questionBody,
      'category': category.value,
      'detail': detail.trim(),
      'status': 'pending',
      'teacherNote': '',
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (duplicateIndex >= 0) {
      report['id'] = reports[duplicateIndex]['id'];
      reports[duplicateIndex] = report;
    } else {
      reports.add(report);
    }
    await _saveLocal(reports);
    return report['id'] as String;
  }

  Future<List<QuestionReport>> teacherReports() async {
    final client = _client;
    if (client != null) {
      final response = await client.rpc('teacher_question_reports');
      return (response as List<dynamic>? ?? const [])
          .map(
            (item) =>
                QuestionReport.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
    return (await _loadLocal())
        .map(QuestionReport.fromJson)
        .toList()
        .reversed
        .toList();
  }

  Future<void> resolve({
    required String reportId,
    required bool accepted,
    String teacherNote = '',
  }) async {
    final status = accepted ? 'resolved' : 'dismissed';
    final client = _client;
    if (client != null) {
      await client.rpc(
        'resolve_question_report',
        params: {
          'p_report_id': reportId,
          'p_status': status,
          'p_teacher_note': teacherNote.trim().isEmpty
              ? null
              : teacherNote.trim(),
        },
      );
      return;
    }
    final reports = await _loadLocal();
    final index = reports.indexWhere((item) => item['id'] == reportId);
    if (index < 0) return;
    reports[index] = {
      ...reports[index],
      'status': status,
      'teacherNote': teacherNote.trim(),
      'resolvedAt': DateTime.now().toIso8601String(),
    };
    await _saveLocal(reports);
  }

  Future<List<Map<String, dynamic>>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _saveLocal(List<Map<String, dynamic>> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode(reports));
  }
}
