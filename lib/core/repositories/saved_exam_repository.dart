import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_exam_repository.dart';
import '../utils/supabase_retry_helper.dart';

class SavedExamRepository {
  SavedExamRepository(this._client);
  final SupabaseClient? _client;

  static const String _storageKey = 'locally_saved_exam_ids_v1';
  final Set<String> _localSavedExamIds = <String>{};
  bool _isCacheLoaded = false;

  Set<String> get localSavedExamIds => Set.unmodifiable(_localSavedExamIds);

  Future<void> _ensureCacheLoaded() async {
    if (_isCacheLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey);
      if (list != null) {
        _localSavedExamIds.addAll(list);
      }
      _isCacheLoaded = true;
    } catch (_) {
      _isCacheLoaded = true;
    }
  }

  Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _localSavedExamIds.toList());
    } catch (_) {}
  }

  Future<Set<String>> getSavedExamIds() async {
    await _ensureCacheLoaded();
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return Set.unmodifiable(_localSavedExamIds);
    }
    try {
      final res = await SupabaseRetryHelper.run(
        () => client
            .from('saved_exams')
            .select('exam_id')
            .eq('user_id', client.auth.currentUser!.id),
      );
      final list = res as List<dynamic>;
      for (final item in list) {
        final eid = item['exam_id']?.toString();
        if (eid != null && eid.isNotEmpty) {
          _localSavedExamIds.add(eid);
        }
      }
      await _persistCache();
      return Set.unmodifiable(_localSavedExamIds);
    } catch (_) {
      return Set.unmodifiable(_localSavedExamIds);
    }
  }

  Future<bool> isExamSaved(String examId) async {
    if (examId.isEmpty) return false;
    await _ensureCacheLoaded();
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
      await _persistCache();
      return isSaved;
    } catch (_) {
      return _localSavedExamIds.contains(examId);
    }
  }

  Future<bool> toggleSaveExam(String examId) async {
    if (examId.isEmpty) return false;
    await _ensureCacheLoaded();

    final currentlySaved = _localSavedExamIds.contains(examId);
    final isNowSaved = !currentlySaved;

    if (isNowSaved) {
      _localSavedExamIds.add(examId);
    } else {
      _localSavedExamIds.remove(examId);
    }
    await _persistCache();

    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      final userId = client.auth.currentUser!.id;
      try {
        if (!isNowSaved) {
          await SupabaseRetryHelper.run(
            () => client
                .from('saved_exams')
                .delete()
                .eq('exam_id', examId)
                .eq('user_id', userId),
          );
        } else {
          await SupabaseRetryHelper.run(
            () => client.from('saved_exams').insert({
              'exam_id': examId,
              'user_id': userId,
            }),
          );
        }
      } catch (e) {
        debugPrint('Lỗi đồng bộ saved_exams lên Supabase (vẫn lưu cục bộ thành công): $e');
      }
    }

    return isNowSaved;
  }

  Future<List<TeacherExamSummary>> getSavedExams() async {
    await _ensureCacheLoaded();
    final client = _client;

    // Attempt 1: Query Supabase saved_exams table if authenticated
    if (client != null && client.auth.currentUser != null) {
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

          final id = examMap['id']?.toString() ?? '';
          if (id.isNotEmpty) _localSavedExamIds.add(id);

          summaries.add(
            TeacherExamSummary(
              id: id,
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

        if (summaries.isNotEmpty || _localSavedExamIds.isEmpty) {
          await _persistCache();
          return summaries;
        }
      } catch (e) {
        debugPrint('Bảng saved_exams chưa khả dụng trên Supabase ($e). Kích hoạt cơ chế truy vấn dự phòng theo ID lưu cục bộ...');
      }
    }

    // Attempt 2: Fallback querying exams table directly by saved IDs (works even if saved_exams table is not yet created on Supabase!)
    if (_localSavedExamIds.isNotEmpty && client != null) {
      try {
        final res = await SupabaseRetryHelper.run(
          () => client
              .from('exams')
              .select('id, code, title, subject, duration_minutes, status, created_at, questions(count)')
              .inFilter('id', _localSavedExamIds.toList())
              .order('created_at', ascending: false),
        );

        final list = res as List<dynamic>;
        final List<TeacherExamSummary> summaries = [];
        for (final item in list) {
          final questions = item['questions'] as List<dynamic>?;
          final count = (questions != null && questions.isNotEmpty)
              ? ((questions.first as Map<String, dynamic>?)?['count'] as num?)?.toInt() ?? 0
              : 0;

          summaries.add(
            TeacherExamSummary(
              id: item['id']?.toString() ?? '',
              code: item['code']?.toString() ?? '',
              title: item['title']?.toString() ?? 'Đề thi đã lưu',
              subject: item['subject']?.toString() ?? 'Chung',
              durationMinutes: (item['duration_minutes'] as num?)?.toInt() ?? 45,
              questionCount: count,
              status: item['status']?.toString() ?? 'published',
              createdAt: DateTime.tryParse(item['created_at']?.toString() ?? ''),
            ),
          );
        }

        if (summaries.isNotEmpty) {
          return summaries;
        }
      } catch (e) {
        debugPrint('Lỗi truy vấn dự phòng bảng exams: $e');
      }
    }

    // Attempt 3: Local mock fallback if no internet or client uninitialized
    if (_localSavedExamIds.isNotEmpty) {
      return _localSavedExamIds
          .map(
            (id) => TeacherExamSummary(
              id: id,
              code: 'SAVED',
              title: 'Đề thi đã lưu ($id)',
              subject: 'Chung',
              durationMinutes: 45,
              questionCount: 10,
              status: 'published',
              createdAt: DateTime.now(),
            ),
          )
          .toList();
    }

    return [];
  }
}

