import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assessment.dart';

class AssessmentRepository {
  AssessmentRepository(this._client);

  final SupabaseClient _client;
  static const _guestTokenPrefix = 'guest-attempt-token:';

  Future<StartedAttempt> beginPractice(String examId) async {
    final response = await _client.rpc('begin_practice_attempt', params: {'p_exam_id': examId});
    final started = StartedAttempt.fromJson(_map(response));
    if (started.guestToken != null) await _saveGuestToken(started.attemptId, started.guestToken!);
    return started;
  }

  Future<AttemptPayload> loadAttempt(String attemptId) async {
    final response = await _client.rpc('attempt_payload', params: {
      'p_attempt_id': attemptId,
      'p_guest_token': await _guestToken(attemptId),
    });
    return AttemptPayload.fromJson(_map(response));
  }

  Future<AttemptReviewPayload> loadReview(String attemptId) async {
    final response = await _client.rpc('attempt_review_payload', params: {
      'p_attempt_id': attemptId,
      'p_guest_token': await _guestToken(attemptId),
    });
    return AttemptReviewPayload.fromJson(_map(response));
  }

  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    required String optionId,
  }) async {
    await _client.rpc('save_attempt_answer', params: {
      'p_attempt_id': attemptId,
      'p_question_id': questionId,
      'p_option_id': optionId,
      'p_guest_token': await _guestToken(attemptId),
    });
  }

  Future<Map<String, dynamic>> submit(String attemptId) async {
    final response = await _client.rpc('submit_attempt', params: {
      'p_attempt_id': attemptId,
      'p_guest_token': await _guestToken(attemptId),
    });
    return _map(response);
  }

  Future<void> _saveGuestToken(String attemptId, String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_guestTokenPrefix$attemptId', token);
  }

  Future<String?> _guestToken(String attemptId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('$_guestTokenPrefix$attemptId');
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) return Map<String, dynamic>.from(jsonDecode(value) as Map);
    throw const FormatException('Invalid response from assessment service.');
  }
}
