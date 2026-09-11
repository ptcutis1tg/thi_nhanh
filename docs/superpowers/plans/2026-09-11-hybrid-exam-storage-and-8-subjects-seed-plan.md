# Hybrid Exam Storage (CQRS) & 8 Subjects Exam Seed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement high-performance Hybrid CQRS storage (3NF authoring + automated JSONB exam snapshot) in Supabase and populate 24 high-quality multiple-choice exams across 8 subjects (Toán học, Vật lý, Hóa học, Sinh học, Tiếng Anh, Lịch sử, Địa lý, Tin học).

**Architecture:** A PostgreSQL migration adds `snapshot_payload jsonb` to `public.exams` with an automated trigger on `questions` and `question_options`. An anti-cheat snapshot builder function generates a clean, single-fetch payload omitting `is_correct`. 24 exams (240 questions, 960 options) are inserted with verified academic content.

**Tech Stack:** PostgreSQL (PL/pgSQL triggers, JSONB, GIN indexing), Supabase, Flutter / Dart.

## Global Constraints
- Every question must have exactly 1 correct option (`is_correct = true`) and 3 incorrect options.
- The `snapshot_payload` must NOT contain `is_correct` flags or answers to prevent client DevTools inspection leaks during active tests.
- Exam codes follow `^DT[0-9]{6}$`.
- All tests in `flutter test` must remain green.

---

### Task 1: Database Migration - Hybrid CQRS Snapshot Architecture

**Files:**
- Create: `supabase/migrations/202609110001_hybrid_storage_and_8_subjects_seed.sql`
- Test: `test/repositories/assessment_repository_test.dart`

**Interfaces:**
- Produces: `public.exams.snapshot_payload jsonb`, `public.fn_rebuild_exam_snapshot(uuid)`, `public.fn_trigger_sync_exam_snapshot()`

- [ ] **Step 1: Write SQL schema changes and trigger functions**
Add DDL for `snapshot_payload`, the JSONB builder function, and triggers on `questions` and `question_options`.

```sql
-- Migration: 202609110001_hybrid_storage_and_8_subjects_seed.sql
alter table public.exams add column if not exists snapshot_payload jsonb;
create index if not exists idx_exams_snapshot_payload on public.exams using gin (snapshot_payload);

create or replace function public.fn_rebuild_exam_snapshot(p_exam_id uuid)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_payload jsonb;
begin
  select jsonb_build_object(
    'id', e.id,
    'code', e.code,
    'title', e.title,
    'description', e.description,
    'subject', e.subject,
    'difficulty', e.difficulty,
    'duration_minutes', e.duration_minutes,
    'total_questions', count(q.id),
    'questions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', q_sub.id,
            'position', q_sub.position,
            'body', q_sub.body,
            'points', q_sub.points,
            'options', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'id', o.id,
                    'position', o.position,
                    'body', o.body
                  ) order by o.position
                )
                from public.question_options o
                where o.question_id = q_sub.id
              ),
              '[]'::jsonb
            )
          ) order by q_sub.position
        )
        from public.questions q_sub
        where q_sub.exam_id = e.id
      ),
      '[]'::jsonb
    )
  )
  into v_payload
  from public.exams e
  left join public.questions q on q.exam_id = e.id
  where e.id = p_exam_id
  group by e.id;

  update public.exams
  set snapshot_payload = v_payload
  where id = p_exam_id;

  return v_payload;
end;
$$;

create or replace function public.fn_trigger_sync_exam_snapshot()
returns trigger
language plpgsql
security definer
as $$
declare
  v_exam_id uuid;
begin
  if tg_table_name = 'questions' then
    v_exam_id := coalesce(new.exam_id, old.exam_id);
  elsif tg_table_name = 'question_options' then
    select exam_id into v_exam_id
    from public.questions
    where id = coalesce(new.question_id, old.question_id);
  end if;

  if v_exam_id is not null then
    perform public.fn_rebuild_exam_snapshot(v_exam_id);
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_sync_exam_snapshot_questions on public.questions;
create trigger trg_sync_exam_snapshot_questions
after insert or update or delete on public.questions
for each row execute function public.fn_trigger_sync_exam_snapshot();

drop trigger if exists trg_sync_exam_snapshot_options on public.question_options;
create trigger trg_sync_exam_snapshot_options
after insert or update or delete on public.question_options
for each row execute function public.fn_trigger_sync_exam_snapshot();
```

- [ ] **Step 2: Commit Task 1 files**
```bash
git add supabase/migrations/202609110001_hybrid_storage_and_8_subjects_seed.sql
git commit -m "feat(db): add snapshot_payload column and triggers for hybrid exam storage"
```

---

### Task 2: Generate 24 High-Quality Exams Across 8 Subjects

**Files:**
- Modify: `supabase/migrations/202609110001_hybrid_storage_and_8_subjects_seed.sql`
- Modify: `supabase/seed.sql`

**Subjects & Exam Breakdown:**
- 8 Teachers: Ensure specialized teachers for each subject (Toán, Lý, Hóa, Sinh, Anh, Sử, Địa, Tin).
- 24 Exams (Codes `DT010101` to `DT010803`), each with:
  - 10 Questions (`position` 1 to 10)
  - 4 Options per question (`position` 1 to 4)
  - Exactly 1 correct option (`is_correct = true`)
  - No dummy/placeholder questions; accurate Vietnamese educational content.
- Execution loop: Trigger `public.fn_rebuild_exam_snapshot(id)` for all 24 exams.

- [ ] **Step 1: Write and append 24 exams DML to migration and seed.sql**
Write SQL inserts for:
1. Teachers: `Thầy Nguyễn Văn A` (Toán), `Cô Lê Thị B` (Lý), `Cô Phạm Thị D` (Hóa), `Thầy Vũ Đình E` (Sinh), `Cô Trần Thị C` (Anh), `Thầy Hoàng Văn F` (Sử), `Cô Đặng Thị G` (Địa), `Thầy Ngô Bá H` (Tin).
2. 24 Exams with standard UUIDs.
3. 240 Questions with clear, accurate multiple-choice prompts.
4. 960 Options with verified keys.
5. Auto-snapshot generation statement:
   ```sql
   do $$
   declare
     r record;
   begin
     for r in select id from public.exams loop
       perform public.fn_rebuild_exam_snapshot(r.id);
     end loop;
   end;
   $$;
   ```

- [ ] **Step 2: Commit Task 2 files**
```bash
git add supabase/migrations/202609110001_hybrid_storage_and_8_subjects_seed.sql supabase/seed.sql
git commit -m "feat(seed): generate 24 high quality exams across 8 subjects"
```

---

### Task 3: Client Integration, Verification & Test Suite

**Files:**
- Modify: `lib/core/repositories/assessment_repository.dart`
- Test: `test/repositories/assessment_repository_test.dart`

- [ ] **Step 1: Write test for AssessmentRepository snapshot parsing**
Add unit test verifying that if an exam has `snapshot_payload`, `AssessmentRepository` can parse the questions directly without fallback joins.

- [ ] **Step 2: Update AssessmentRepository to consume snapshot_payload**
When querying an exam, if `snapshot_payload` is present and populated, use it directly for sub-millisecond loading; otherwise fall back to standard relational query.

- [ ] **Step 3: Run full flutter test suite**
Run: `flutter test`
Expected: 26+ passing tests.

- [ ] **Step 4: Commit and Push**
Commit changes and push to remote according to user rules.
