-- Migration: 202609120001_public_published_exam_questions_policy.sql
-- Allow public and students to read questions and options of published exams for practice and display

drop policy if exists "published exam questions are public" on public.questions;
create policy "published exam questions are public" on public.questions
for select using (
  exists (select 1 from public.exams where id = exam_id and status = 'published')
);

drop policy if exists "published exam question options are public" on public.question_options;
create policy "published exam question options are public" on public.question_options
for select using (
  exists (
    select 1 from public.questions q
    join public.exams e on e.id = q.exam_id
    where q.id = question_id and e.status = 'published'
  )
);
