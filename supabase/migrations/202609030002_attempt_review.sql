-- Assessment Review RPC: returns scored questions, selected answers, correct answers and explanations
-- Apply after 202609030001_live_rooms_e2e.sql.

create or replace function public.attempt_review_payload(
  p_attempt_id uuid,
  p_guest_token text default null
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_attempt public.attempts;
  v_exam public.exams;
  v_total_questions integer;
  v_correct_count integer;
  v_wrong_count integer;
  v_skipped_count integer;
  v_duration_seconds integer;
  v_questions jsonb;
begin
  if not public.can_access_attempt(p_attempt_id, p_guest_token) then
    raise exception 'Not allowed to view this attempt';
  end if;

  select * into v_attempt from public.attempts where id = p_attempt_id;
  if not found then raise exception 'Attempt not found'; end if;

  select * into v_exam from public.exams where id = v_attempt.exam_id;

  select count(*) into v_total_questions from public.questions where exam_id = v_exam.id;

  select count(*) into v_correct_count
  from public.attempt_answers aa
  join public.question_options qo on qo.id = aa.selected_option_id
  where aa.attempt_id = v_attempt.id and qo.is_correct;

  select count(*) into v_wrong_count
  from public.attempt_answers aa
  join public.question_options qo on qo.id = aa.selected_option_id
  where aa.attempt_id = v_attempt.id and not qo.is_correct;

  v_skipped_count := greatest(0, v_total_questions - v_correct_count - v_wrong_count);

  if v_attempt.submitted_at is not null and v_attempt.started_at is not null then
    v_duration_seconds := extract(epoch from (v_attempt.submitted_at - v_attempt.started_at))::integer;
  else
    v_duration_seconds := null;
  end if;

  -- Questions with answer status and explanations
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', q.id,
      'position', q.position,
      'body', q.body,
      'points', q.points,
      'explanation', coalesce(q.explanation, ''),
      'selectedOptionId', (select selected_option_id from public.attempt_answers where attempt_id = v_attempt.id and question_id = q.id),
      'correctOptionId', (select id from public.question_options where question_id = q.id and is_correct limit 1),
      'options', (
        select jsonb_agg(
          jsonb_build_object(
            'id', o.id,
            'position', o.position,
            'body', o.body,
            'isCorrect', o.is_correct
          ) order by o.position
        )
        from public.question_options o
        where o.question_id = q.id
      )
    ) order by q.position
  ), '[]'::jsonb)
  into v_questions
  from public.questions q
  where q.exam_id = v_exam.id;

  return jsonb_build_object(
    'attemptId', v_attempt.id,
    'roomId', v_attempt.room_id,
    'examId', v_exam.id,
    'title', v_exam.title,
    'subject', v_exam.subject,
    'status', v_attempt.status,
    'score', coalesce(v_attempt.score, 0),
    'maxScore', 10.0,
    'correctCount', v_correct_count,
    'wrongCount', v_wrong_count,
    'skippedCount', v_skipped_count,
    'totalQuestions', v_total_questions,
    'durationSeconds', v_duration_seconds,
    'submittedAt', v_attempt.submitted_at,
    'questions', v_questions
  );
end;
$$;

grant execute on function public.attempt_review_payload(uuid, text) to anon, authenticated;
