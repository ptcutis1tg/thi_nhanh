import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('question reports migration defines the secure reporting workflow', () {
    final file = File('supabase/migrations/202610100001_question_reports.sql');
    expect(file.existsSync(), isTrue);

    final sql = file.readAsStringSync();
    expect(sql, contains('create table if not exists public.question_reports'));
    expect(sql, contains('enable row level security'));
    expect(
      sql,
      contains('create or replace function public.submit_question_report'),
    );
    expect(
      sql,
      contains('create or replace function public.teacher_question_reports'),
    );
    expect(
      sql,
      contains('create or replace function public.resolve_question_report'),
    );
    expect(sql, contains('guest_access_token_hash'));
    expect(sql, contains('question_reports_attempt_question_category_uidx'));
  });
}
