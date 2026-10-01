-- supabase/migrations/202610010001_rich_exam_questions_and_types.sql
-- Migration: Add question_type, time_limit_seconds, image_url and support multi-choice answers

alter table public.questions 
  add column if not exists question_type text not null default 'single_choice',
  add column if not exists time_limit_seconds integer check (time_limit_seconds is null or time_limit_seconds > 0),
  add column if not exists image_url text;

-- Drop unique single correct answer index to support multiple_choice
drop index if exists public.question_options_one_correct_answer;

-- Replace save_teacher_exam_draft RPC
create or replace function public.save_teacher_exam_draft(
  p_exam_id uuid,
  p_title text,
  p_subject text,
  p_duration_minutes integer,
  p_questions jsonb
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_teacher_id uuid;
  v_exam public.exams;
  v_question jsonb;
  v_option jsonb;
  v_position integer := 0;
  v_option_position integer;
  v_question_id uuid;
  v_q_type text;
  v_correct_list jsonb;
  v_is_correct boolean;
begin
  v_teacher_id := public.ensure_current_teacher();
  if char_length(trim(p_title)) < 3 then raise exception 'Tên đề thi phải có ít nhất 3 ký tự'; end if;
  if p_duration_minutes not between 1 and 360 then raise exception 'Thời lượng thi phải từ 1 đến 360 phút'; end if;

  if p_exam_id is null then
    insert into public.exams (code, teacher_id, title, subject, duration_minutes, status)
    values (public.next_exam_code(), v_teacher_id, trim(p_title), trim(p_subject), p_duration_minutes, 'draft')
    returning * into v_exam;
  else
    select * into v_exam from public.exams where id = p_exam_id and teacher_id = v_teacher_id for update;
    if not found then raise exception 'Exam not found'; end if;
    if exists (select 1 from public.attempts where exam_id = p_exam_id) then
      raise exception 'An exam with attempts cannot be changed; duplicate it first.';
    end if;
    update public.exams 
    set title = trim(p_title), subject = trim(p_subject), duration_minutes = p_duration_minutes, updated_at = now()
    where id = p_exam_id returning * into v_exam;
    
    delete from public.questions where exam_id = v_exam.id;
  end if;

  for v_question in select value from jsonb_array_elements(p_questions) loop
    v_position := v_position + 1;
    v_q_type := coalesce(v_question ->> 'type', v_question ->> 'question_type', 'single_choice');
    
    if char_length(trim(coalesce(v_question ->> 'body', ''))) = 0 then 
      raise exception 'Question % is empty', v_position; 
    end if;

    insert into public.questions (
      exam_id, position, body, points, question_type, time_limit_seconds, image_url, explanation
    )
    values (
      v_exam.id,
      v_position,
      trim(v_question ->> 'body'),
      coalesce((v_question ->> 'points')::numeric, 1),
      v_q_type,
      (v_question ->> 'timeLimitSeconds')::integer,
      v_question ->> 'imageUrl',
      trim(coalesce(v_question ->> 'explanation', ''))
    )
    returning id into v_question_id;

    v_option_position := 0;
    v_correct_list := v_question -> 'correctAnswers';

    for v_option in select value from jsonb_array_elements(v_question -> 'answers') loop
      v_option_position := v_option_position + 1;
      
      if v_correct_list is not null and jsonb_typeof(v_correct_list) = 'array' then
        v_is_correct := v_correct_list @> to_jsonb(v_option_position - 1);
      else
        v_is_correct := (v_option_position - 1 = coalesce((v_question ->> 'correctAnswer')::integer, 0));
      end if;

      insert into public.question_options (question_id, position, body, is_correct)
      values (v_question_id, v_option_position, trim(v_option #>> '{}'), v_is_correct);
    end loop;
  end loop;

  return jsonb_build_object('id', v_exam.id, 'code', v_exam.code, 'status', v_exam.status);
end;
$$;

-- Replace teacher_exam_draft RPC to return enhanced fields
create or replace function public.teacher_exam_draft(p_exam_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_exam public.exams;
begin
  select * into v_exam from public.exams
  where id = p_exam_id and teacher_id = public.ensure_current_teacher();
  if not found then return null; end if;

  return jsonb_build_object(
    'id', v_exam.id,
    'code', v_exam.code,
    'title', v_exam.title,
    'subject', v_exam.subject,
    'durationMinutes', v_exam.duration_minutes,
    'status', v_exam.status,
    'questions', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', q.id,
        'position', q.position,
        'type', coalesce(q.question_type, 'single_choice'),
        'body', q.body,
        'points', q.points,
        'timeLimitSeconds', q.time_limit_seconds,
        'imageUrl', q.image_url,
        'explanation', coalesce(q.explanation, ''),
        'answers', (
          select coalesce(jsonb_agg(o.body order by o.position), '[]'::jsonb)
          from public.question_options o where o.question_id = q.id
        ),
        'correctAnswers', (
          select coalesce(jsonb_agg(o.position - 1 order by o.position) filter (where o.is_correct), '[]'::jsonb)
          from public.question_options o where o.question_id = q.id
        ),
        'correctAnswer', (
          select coalesce(min(o.position - 1) filter (where o.is_correct), 0)
          from public.question_options o where o.question_id = q.id
        )
      ) order by q.position), '[]'::jsonb)
      from public.questions q where q.exam_id = v_exam.id
    )
  );
end;
$$;
