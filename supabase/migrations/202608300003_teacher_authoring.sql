-- Server-side teacher authoring. Flutter never writes questions/options directly.

create or replace function public.ensure_current_teacher()
returns uuid language plpgsql security definer set search_path = public as $$
declare v_teacher_id uuid; v_name text;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  select id into v_teacher_id from public.teachers where owner_user_id = auth.uid();
  if v_teacher_id is not null then return v_teacher_id; end if;
  select coalesce(nullif(trim(display_name), ''), nullif(trim(auth.jwt() ->> 'email'), ''), 'Giáo viên')
    into v_name from public.profiles where id = auth.uid();
  insert into public.teachers (owner_user_id, display_name)
  values (auth.uid(), coalesce(v_name, 'Giáo viên')) returning id into v_teacher_id;
  return v_teacher_id;
end;
$$;

create or replace function public.next_exam_code()
returns text language plpgsql security definer set search_path = public as $$
declare v_code text;
begin
  loop
    v_code := 'DT' || lpad(floor(random() * 1000000)::integer::text, 6, '0');
    exit when not exists (select 1 from public.exams where code = v_code);
  end loop;
  return v_code;
end;
$$;

create or replace function public.save_teacher_exam_draft(
  p_exam_id uuid, p_title text, p_subject text, p_duration_minutes integer, p_questions jsonb
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_teacher_id uuid; v_exam public.exams; v_question jsonb; v_option jsonb;
declare v_position integer := 0; v_option_position integer; v_question_id uuid;
begin
  v_teacher_id := public.ensure_current_teacher();
  if char_length(trim(p_title)) < 3 then raise exception 'Exam title must have at least 3 characters'; end if;
  if p_duration_minutes not between 1 and 360 then raise exception 'Duration must be between 1 and 360 minutes'; end if;

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
    update public.exams set title = trim(p_title), subject = trim(p_subject), duration_minutes = p_duration_minutes
      where id = p_exam_id returning * into v_exam;
    delete from public.questions where exam_id = v_exam.id;
  end if;

  for v_question in select value from jsonb_array_elements(p_questions) loop
    v_position := v_position + 1;
    if char_length(trim(coalesce(v_question ->> 'body', ''))) = 0 then raise exception 'Question % is empty', v_position; end if;
    insert into public.questions (exam_id, position, body, points)
    values (v_exam.id, v_position, trim(v_question ->> 'body'), coalesce((v_question ->> 'points')::numeric, 1))
    returning id into v_question_id;
    v_option_position := 0;
    for v_option in select value from jsonb_array_elements(v_question -> 'answers') loop
      v_option_position := v_option_position + 1;
      if char_length(trim(v_option #>> '{}')) = 0 then raise exception 'Option % for question % is empty', v_option_position, v_position; end if;
      insert into public.question_options (question_id, position, body, is_correct)
      values (v_question_id, v_option_position, trim(v_option #>> '{}'), v_option_position - 1 = coalesce((v_question ->> 'correctAnswer')::integer, 0));
    end loop;
    if v_option_position < 2 then raise exception 'Question % requires at least two options', v_position; end if;
  end loop;
  return jsonb_build_object('id', v_exam.id, 'code', v_exam.code, 'status', v_exam.status);
end;
$$;

create or replace function public.teacher_exam_summaries()
returns jsonb language sql security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', e.id, 'code', e.code, 'title', e.title, 'subject', e.subject,
    'durationMinutes', e.duration_minutes, 'status', e.status,
    'questionCount', (select count(*) from public.questions q where q.exam_id = e.id),
    'createdAt', e.created_at
  ) order by e.created_at desc), '[]'::jsonb)
  from public.exams e where e.teacher_id = public.ensure_current_teacher();
$$;

create or replace function public.publish_teacher_exam(p_exam_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_exam public.exams;
begin
  select e.* into v_exam from public.exams e
  where e.id = p_exam_id and e.teacher_id = public.ensure_current_teacher() for update;
  if not found then raise exception 'Exam not found'; end if;
  if not exists (select 1 from public.questions where exam_id = v_exam.id) then raise exception 'Add at least one question before publishing'; end if;
  if exists (select 1 from public.questions q where q.exam_id = v_exam.id and
    (select count(*) from public.question_options o where o.question_id = q.id) < 2) then raise exception 'Every question needs at least two options'; end if;
  update public.exams set status = 'published', published_at = now() where id = v_exam.id returning * into v_exam;
  return jsonb_build_object('id', v_exam.id, 'code', v_exam.code, 'status', v_exam.status);
end;
$$;

grant execute on function public.save_teacher_exam_draft(uuid, text, text, integer, jsonb) to authenticated;
grant execute on function public.teacher_exam_summaries() to authenticated;
grant execute on function public.publish_teacher_exam(uuid) to authenticated;
