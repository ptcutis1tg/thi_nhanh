import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved_exams migration contains table creation, RLS, and updated create_teacher_room', () {
    final file = File('supabase/migrations/202610090001_saved_exams_and_host_permission.sql');
    expect(file.existsSync(), isTrue, reason: 'Migration file must exist');

    final content = file.readAsStringSync();
    expect(content, contains('create table if not exists public.saved_exams'));
    expect(content, contains('references public.exams(id)'));
    expect(content, contains('enable row level security'));
    expect(content, contains('create or replace function public.create_teacher_room'));
    expect(content, contains('public.saved_exams se'));
  });
}
