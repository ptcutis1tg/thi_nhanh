import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/models/assessment.dart';
import 'package:onthi_community/screens/exam/taking_exam_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('AttemptPayload parses isAuthorPreview flag properly', () {
    final payloadWithPreview = {
      'attemptId': 'att-123',
      'title': 'Đề thi Toán',
      'durationMinutes': 45,
      'expiresAt': DateTime.now().add(const Duration(minutes: 45)).toIso8601String(),
      'status': 'in_progress',
      'questions': [],
      'answers': {},
      'isAuthorPreview': true,
    };

    final attempt = AttemptPayload.fromJson(payloadWithPreview);
    expect(attempt.isAuthorPreview, isTrue);

    final payloadWithoutPreview = {
      'attemptId': 'att-123',
      'title': 'Đề thi Toán',
      'durationMinutes': 45,
      'expiresAt': DateTime.now().add(const Duration(minutes: 45)).toIso8601String(),
      'status': 'in_progress',
      'questions': [],
      'answers': {},
    };

    final normalAttempt = AttemptPayload.fromJson(payloadWithoutPreview);
    expect(normalAttempt.isAuthorPreview, isFalse);
  });

  testWidgets('TakingExamScreen displays author preview banner when isAuthorPreview is true', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: TakingExamScreen(isAuthorPreview: true),
      ),
    );

    // Initial loading state or loaded state
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Chế độ xem trước của tác giả'),
      findsOneWidget,
    );
  });
}
