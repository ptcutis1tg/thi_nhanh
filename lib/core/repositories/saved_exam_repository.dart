import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_exam_repository.dart';
import '../utils/supabase_retry_helper.dart';

class SavedExamRepository {
  SavedExamRepository(this._client);
  final SupabaseClient? _client;

  final Set<String> _localSavedExamIds = <String>{};

  Set<String> get localSavedExamIds => Set.unmodifiable(_localSavedExamIds);

  Future<bool> isExamSaved(String examId) async {
    if (examId.isEmpty) return false;
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return _localSavedExamIds.contains(examId);
    }

    try {
      final res = await SupabaseRetryHelper.run(
        () => client
            .from('saved_exams')
            .select('id')
            .eq('exam_id', examId)
            .eq('user_id', client.auth.currentUser!.id)
            .maybeSingle(),
      );
      final isSaved = res != null;
      if (isSaved) {
        _localSavedExamIds.add(examId);
      } else {
        _localSavedExamIds.remove(examId);
      }
      return isSaved;
    } catch (_) {
      return _localSavedExamIds.contains(examId);
    }
  }

  Future<bool> toggleSaveExam(String examId) async {
    if (examId.isEmpty) return false;
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      if (_localSavedExamIds.contains(examId)) {
        _localSavedExamIds.remove(examId);
        return false;
      } else {
        _localSavedExamIds.add(examId);
        return true;
      }
    }

    final userId = client.auth.currentUser!.id;
    final currentlySaved = await isExamSaved(examId);

    try {
      if (currentlySaved) {
        await SupabaseRetryHelper.run(
          () => client
              .from('saved_exams')
              .delete()
              .eq('exam_id', examId)
              .eq('user_id', userId),
        );
        _localSavedExamIds.remove(examId);
        return false;
      } else {
        await SupabaseRetryHelper.run(
          () => client.from('saved_exams').insert({
            'exam_id': examId,
            'user_id': userId,
          }),
        );
        _localSavedExamIds.add(examId);
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi toggle save exam: $e');
      if (_localSavedExamIds.contains(examId)) {
        _localSavedExamIds.remove(examId);
        return false;
      } else {
        _localSavedExamIds.add(examId);
        return true;
      }
    }
  }

  Future<List<TeacherExamSummary>> getSavedExams() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return [];
    }

    try {
      final res = await SupabaseRetryHelper.run(
        () => client
            .from('saved_exams')
            .select('exam_id, exams(id, code, title, subject, duration_minutes, status, created_at, questions(count))')
            .eq('user_id', client.auth.currentUser!.id)
            .order('created_at', ascending: false),
      );

      final list = res as List<dynamic>;
      final List<TeacherExamSummary> summaries = [];
      for (final item in list) {
        final examMap = item['exams'] as Map<String, dynamic>?;
        if (examMap == null) continue;
        final questions = examMap['questions'] as List<dynamic>?;
        final count = (questions != null && questions.isNotEmpty)
            ? ((questions.first as Map<String, dynamic>?)?['count'] as num?)?.toInt() ?? 0
            : 0;

        summaries.add(
          TeacherExamSummary(
            id: examMap['id']?.toString() ?? '',
            code: examMap['code']?.toString() ?? '',
            title: examMap['title']?.toString() ?? 'Đề thi đã lưu',
            subject: examMap['subject']?.toString() ?? 'Chung',
            durationMinutes: (examMap['duration_minutes'] as num?)?.toInt() ?? 45,
            questionCount: count,
            status: examMap['status']?.toString() ?? 'published',
            createdAt: DateTime.tryParse(examMap['created_at']?.toString() ?? ''),
          ),
        );
      }
      return summaries;
    } catch (e) {
      debugPrint('Lỗi tải danh sách đề đã lưu: $e');
      return [];
    }
  }
}
