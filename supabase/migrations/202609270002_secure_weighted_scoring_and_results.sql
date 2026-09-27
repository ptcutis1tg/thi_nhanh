-- Canonical weighted scoring and result payloads.
-- Scores are always normalized to a 10-point scale. Correct answers and
-- explanations are only released for practice attempts or after a room closes.

-- Options must only be read through exam_payload/attempt_payload so the
-- is_correct column cannot be selected through PostgREST during an exam.
drop policy if exists "published exam question options are public" on public.question_options;

create or replace function public.submit_attempt(
  p_attempt_id uuid,
  p_guest_token text default null
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_attempt public.attempts;
  v_earned_points numeric := 0;
  v_total_points numeric := 0;
  v_score numeric(8,2) := 0;
  v_total_questions integer := 0;
  v_correct_count integer := 0;
  v_wrong_count integer := 0;
  v_answered_count integer := 0;
  v_release boolean := false;
begin
  if not public.can_access_attempt(p_attempt_id, p_guest_token) then
    raise exception 'Not allowed';
  end if;

  select * into v_attempt
  from public.attempts
  where id = p_attempt_id
  for update;

  if not found then raise exception 'Attempt not found'; end if;

  select count(*), coalesce(sum(points), 0)
  into v_total_questions, v_total_points
  from public.questions
  where exam_id = v_attempt.exam_id;

  select
    count(aa.question_id),
    count(aa.question_id) filter (where qo.is_correct),
    count(aa.question_id) filter (where not qo.is_correct),
    coalesce(sum(q.points) filter (where qo.is_correct), 0)
  into v_answered_count, v_correct_count, v_wrong_count, v_earned_points
  from public.attempt_answers aa
  join public.questions q on q.id = aa.question_id and q.exam_id = v_attempt.exam_id
  join public.question_options qo on qo.id = aa.selected_option_id and qo.question_id = q.id
  where aa.attempt_id = v_attempt.id;

  v_score := case
    when v_total_points > 0 then round(v_earned_points / v_total_points * 10, 2)
    else 0
  end;

  v_release := v_attempt.room_id is null;
  if not v_release then
    select coalesce(status = 'closed', false) into v_release
    from public.rooms where id = v_attempt.room_id;
  end if;

  -- Idempotent submission: retries return the already-finalized result.
  if v_attempt.status in ('in_progress', 'expired') then
    update public.attempts
    set status = case
          when now() >= expires_at then 'expired'::public.attempt_status
          else 'submitted'::public.attempt_status
        end,
        submitted_at = coalesce(submitted_at, now()),
        score = v_score,
        result_released_at = case when v_release then coalesce(result_released_at, now()) else result_released_at end
    where id = v_attempt.id
    returning * into v_attempt;
  elsif v_attempt.status not in ('submitted', 'expired') then
    raise exception 'Attempt cannot be submitted in its current state';
  end if;

  return jsonb_build_object(
    'attemptId', v_attempt.id,
    'roomId', v_attempt.room_id,
    'status', v_attempt.status,
    'resultReleased', v_attempt.result_released_at is not null or v_release,
    'score', case when v_attempt.result_released_at is not null or v_release then v_attempt.score else null end,
    'earnedPoints', case when v_attempt.result_released_at is not null or v_release then v_earned_points else null end,
    'totalPoints', v_total_points,
    'correctCount', case when v_attempt.result_released_at is not null or v_release then v_correct_count else null end,
    'wrongCount', case when v_attempt.result_released_at is not null or v_release then v_wrong_count else null end,
    'skippedCount', case when v_attempt.result_released_at is not null or v_release then greatest(0, v_total_questions - v_answered_count) else null end,
    'answeredCount', v_answered_count,
    'totalQuestions', v_total_questions
  );
end;
$$;

create or replace function public.attempt_review_payload(
  p_attempt_id uuid,
  p_guest_token text default null
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_attempt public.attempts;
  v_exam public.exams;
  v_room public.rooms;
  v_result_released boolean := false;
  v_total_questions integer := 0;
  v_answered_count integer := 0;
  v_correct_count integer := 0;
  v_wrong_count integer := 0;
  v_total_points numeric := 0;
  v_earned_points numeric := 0;
  v_duration_seconds integer;
  v_rank integer;
  v_participant_count integer;
  v_questions jsonb := '[]'::jsonb;
begin
  if not public.can_access_attempt(p_attempt_id, p_guest_token) then
    raise exception 'Not allowed to view this attempt';
  end if;

  select * into v_attempt from public.attempts where id = p_attempt_id;
  if not found then raise exception 'Attempt not found'; end if;
  select * into v_exam from public.exams where id = v_attempt.exam_id;

  if v_attempt.room_id is null then
    v_result_released := v_attempt.status in ('submitted', 'expired');
  else
    select * into v_room from public.rooms where id = v_attempt.room_id;
    v_result_released := v_room.status = 'closed' or v_attempt.result_released_at is not null;
    if v_room.status = 'closed' and v_attempt.result_released_at is null then
      update public.attempts set result_released_at = now()
      where id = v_attempt.id returning * into v_attempt;
    end if;
  end if;

  select count(*), coalesce(sum(points), 0)
  into v_total_questions, v_total_points
  from public.questions where exam_id = v_attempt.exam_id;

  select
    count(aa.question_id),
    count(aa.question_id) filter (where qo.is_correct),
    count(aa.question_id) filter (where not qo.is_correct),
    coalesce(sum(q.points) filter (where qo.is_correct), 0)
  into v_answered_count, v_correct_count, v_wrong_count, v_earned_points
  from public.attempt_answers aa
  join public.questions q on q.id = aa.question_id and q.exam_id = v_attempt.exam_id
  join public.question_options qo on qo.id = aa.selected_option_id and qo.question_id = q.id
  where aa.attempt_id = v_attempt.id;

  if v_attempt.submitted_at is not null then
    v_duration_seconds := greatest(0, extract(epoch from (v_attempt.submitted_at - v_attempt.started_at))::integer);
  end if;

  if v_attempt.room_id is not null and v_result_released then
    select ranked.rank_no, ranked.participant_count
    into v_rank, v_participant_count
    from (
      select a.id,
        (row_number() over (order by coalesce(a.score, 0) desc,
          extract(epoch from (coalesce(a.submitted_at, now()) - a.started_at)) asc,
          a.started_at asc))::integer as rank_no,
        (count(*) over ())::integer as participant_count
      from public.attempts a
      where a.room_id = v_attempt.room_id and a.status in ('submitted', 'expired')
    ) ranked
    where ranked.id = v_attempt.id;
  end if;

  if v_result_released then
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', q.id,
      'position', q.position,
      'body', q.body,
      'points', q.points,
      'earnedPoints', case when selected.is_correct then q.points else 0 end,
      'explanation', coalesce(q.explanation, ''),
      'selectedOptionId', selected.selected_option_id,
      'correctOptionId', (select id from public.question_options where question_id = q.id and is_correct limit 1),
      'options', (select jsonb_agg(jsonb_build_object(
        'id', o.id, 'position', o.position, 'body', o.body, 'isCorrect', o.is_correct
      ) order by o.position) from public.question_options o where o.question_id = q.id)
    ) order by q.position), '[]'::jsonb)
    into v_questions
    from public.questions q
    left join lateral (
      select aa.selected_option_id, qo.is_correct
      from public.attempt_answers aa
      join public.question_options qo on qo.id = aa.selected_option_id
      where aa.attempt_id = v_attempt.id and aa.question_id = q.id
      limit 1
    ) selected on true
    where q.exam_id = v_attempt.exam_id;
  end if;

  return jsonb_build_object(
    'attemptId', v_attempt.id,
    'roomId', v_attempt.room_id,
    'examId', v_exam.id,
    'title', v_exam.title,
    'subject', v_exam.subject,
    'status', v_attempt.status,
    'resultReleased', v_result_released,
    'score', case when v_result_released then coalesce(v_attempt.score, 0) else null end,
    'earnedPoints', case when v_result_released then v_earned_points else null end,
    'totalPoints', v_total_points,
    'maxScore', 10.0,
    'answeredCount', v_answered_count,
    'correctCount', case when v_result_released then v_correct_count else null end,
    'wrongCount', case when v_result_released then v_wrong_count else null end,
    'skippedCount', case when v_result_released then greatest(0, v_total_questions - v_answered_count) else null end,
    'totalQuestions', v_total_questions,
    'durationSeconds', v_duration_seconds,
    'submittedAt', v_attempt.submitted_at,
    'rank', v_rank,
    'participantCount', v_participant_count,
    'questions', v_questions
  );
end;
$$;

-- Live scores use the exact same normalized formula as final scores and are
-- visible only to the teacher who owns the room.
create or replace function public.get_room_leaderboard(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_room public.rooms;
  v_total_questions integer;
  v_total_points numeric;
begin
  select r.* into v_room
  from public.rooms r
  join public.teachers t on t.id = r.teacher_id
  where r.id = p_room_id and t.owner_user_id = auth.uid();
  if not found then raise exception 'Not allowed to view this room'; end if;

  select count(*), coalesce(sum(points), 0)
  into v_total_questions, v_total_points
  from public.questions where exam_id = v_room.exam_id;

  return coalesce((
    with participant_stats as (
      select rp.id participant_id,
        coalesce(nullif(p.display_name, ''), rp.guest_name, 'Học sinh') name,
        case when a.status in ('submitted', 'expired') then 'submitted'
             when a.status = 'in_progress' then 'in_progress' else 'waiting' end attempt_status,
        case when v_total_points > 0
          then round(coalesce(sum(q.points) filter (where qo.is_correct), 0) / v_total_points * 10, 2)
          else 0 end live_score,
        count(aa.question_id) answered_count,
        count(aa.question_id) filter (where qo.is_correct) correct_count,
        case when a.submitted_at is not null
          then extract(epoch from (a.submitted_at - a.started_at))::integer end duration_seconds,
        a.submitted_at, rp.requested_at
      from public.room_participants rp
      left join public.profiles p on p.id = rp.user_id
      left join public.attempts a on a.id = rp.attempt_id
      left join public.attempt_answers aa on aa.attempt_id = a.id
      left join public.question_options qo on qo.id = aa.selected_option_id
      left join public.questions q on q.id = aa.question_id and q.exam_id = v_room.exam_id
      where rp.room_id = v_room.id and rp.status <> 'left'
      group by rp.id, p.display_name, rp.guest_name, a.status, a.submitted_at, a.started_at, rp.requested_at
    ), ranked as (
      select *, (row_number() over (order by live_score desc, correct_count desc,
        coalesce(duration_seconds, 2147483647), requested_at))::integer rank_no
      from participant_stats
    )
    select jsonb_agg(jsonb_build_object(
      'rank', rank_no, 'participantId', participant_id, 'name', name,
      'status', attempt_status, 'score', live_score,
      'answeredCount', answered_count, 'correctCount', correct_count,
      'totalQuestions', v_total_questions, 'durationSeconds', duration_seconds,
      'submittedAt', submitted_at
    ) order by rank_no) from ranked
  ), '[]'::jsonb);
end;
$$;

create or replace function public.publish_teacher_exam(p_exam_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_exam public.exams; v_total_points numeric;
begin
  select e.* into v_exam from public.exams e
  where e.id = p_exam_id and e.teacher_id = public.ensure_current_teacher() for update;
  if not found then raise exception 'Exam not found'; end if;
  if not exists (select 1 from public.questions where exam_id = v_exam.id) then
    raise exception 'Add at least one question before publishing';
  end if;
  if exists (select 1 from public.questions q where q.exam_id = v_exam.id and
    (select count(*) from public.question_options o where o.question_id = q.id) < 2) then
    raise exception 'Every question needs at least two options';
  end if;
  select coalesce(sum(points), 0) into v_total_points from public.questions where exam_id = v_exam.id;
  if v_total_points <> 10 then raise exception 'Total question points must equal 10'; end if;
  update public.exams set status = 'published', published_at = now()
  where id = v_exam.id returning * into v_exam;
  return jsonb_build_object('id', v_exam.id, 'code', v_exam.code, 'status', v_exam.status);
end;
$$;

create or replace function public.close_teacher_room(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_room public.rooms;
begin
  select r.* into v_room
  from public.rooms r
  join public.teachers t on t.id = r.teacher_id
  where r.id = p_room_id and t.owner_user_id = auth.uid()
  for update of r;
  if not found then raise exception 'Room not found'; end if;
  if v_room.status <> 'live' then raise exception 'Only a live room can be closed'; end if;

  with scores as (
    select a.id,
      case when coalesce(sum(q.points), 0) > 0 then round(
        coalesce(sum(q.points) filter (where qo.is_correct), 0) / sum(q.points) * 10, 2
      ) else 0 end score
    from public.attempts a
    join public.questions q on q.exam_id = a.exam_id
    left join public.attempt_answers aa on aa.attempt_id = a.id and aa.question_id = q.id
    left join public.question_options qo on qo.id = aa.selected_option_id
    where a.room_id = v_room.id and a.status = 'in_progress'
    group by a.id
  )
  update public.attempts a
  set status = 'expired'::public.attempt_status,
      submitted_at = now(),
      score = scores.score,
      result_released_at = now()
  from scores where a.id = scores.id;

  update public.attempts set result_released_at = coalesce(result_released_at, now())
  where room_id = v_room.id and status in ('submitted', 'expired');
  update public.rooms set status = 'closed', closed_at = now() where id = v_room.id;
  return public.teacher_room_dashboard(v_room.id);
end;
$$;

grant execute on function public.submit_attempt(uuid, text) to anon, authenticated;
grant execute on function public.attempt_review_payload(uuid, text) to anon, authenticated;
revoke execute on function public.get_room_leaderboard(uuid) from anon;
grant execute on function public.get_room_leaderboard(uuid) to authenticated;
grant execute on function public.publish_teacher_exam(uuid) to authenticated;
grant execute on function public.close_teacher_room(uuid) to authenticated;
