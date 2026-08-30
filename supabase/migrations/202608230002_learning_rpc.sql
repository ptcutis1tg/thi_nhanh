-- Client-facing RPCs. They are the only supported way to read questions or
-- write an attempt. `is_correct`, explanations and password hashes never leave
-- this boundary before results are released.

create or replace function public.can_access_attempt(p_attempt_id uuid, p_guest_token text default null)
returns boolean language sql security definer set search_path = public as $$
  select exists (
    select 1 from public.attempts a
    where a.id = p_attempt_id
      and (a.user_id = auth.uid()
        or (a.user_id is null and p_guest_token is not null
            and extensions.crypt(p_guest_token, a.guest_access_token_hash) = a.guest_access_token_hash))
  );
$$;

create or replace function public.exam_payload(p_exam_id uuid)
returns jsonb language sql security definer set search_path = public as $$
  select jsonb_build_object(
    'id', e.id, 'code', e.code, 'title', e.title, 'description', e.description,
    'subject', e.subject, 'durationMinutes', e.duration_minutes,
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', q.id, 'position', q.position, 'body', q.body, 'points', q.points,
        'options', (select jsonb_agg(jsonb_build_object('id', o.id, 'position', o.position, 'body', o.body) order by o.position)
                    from public.question_options o where o.question_id = q.id)
      ) order by q.position)
      from public.questions q where q.exam_id = e.id
    ), '[]'::jsonb)
  )
  from public.exams e
  where e.id = p_exam_id and e.status = 'published';
$$;

create or replace function public.begin_practice_attempt(p_exam_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_exam public.exams;
  v_attempt public.attempts;
  v_token text;
begin
  select * into v_exam from public.exams where id = p_exam_id and status = 'published';
  if not found then raise exception 'Exam is unavailable'; end if;

  if auth.uid() is not null then
    insert into public.attempts (exam_id, user_id, expires_at)
    values (v_exam.id, auth.uid(), now() + make_interval(mins => v_exam.duration_minutes))
    returning * into v_attempt;
    return jsonb_build_object('attemptId', v_attempt.id, 'expiresAt', v_attempt.expires_at);
  end if;

  v_token := encode(extensions.gen_random_bytes(32), 'hex');
  insert into public.attempts (exam_id, guest_name, guest_access_token_hash, expires_at)
  values (v_exam.id, 'Khách', extensions.crypt(v_token, extensions.gen_salt('bf')),
          now() + make_interval(mins => v_exam.duration_minutes))
  returning * into v_attempt;
  return jsonb_build_object('attemptId', v_attempt.id, 'guestToken', v_token, 'expiresAt', v_attempt.expires_at);
end;
$$;

create or replace function public.attempt_payload(p_attempt_id uuid, p_guest_token text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_attempt public.attempts;
  v_payload jsonb;
begin
  if not public.can_access_attempt(p_attempt_id, p_guest_token) then raise exception 'Not allowed'; end if;
  select * into v_attempt from public.attempts where id = p_attempt_id;
  if v_attempt.status = 'in_progress' and now() >= v_attempt.expires_at then
    update public.attempts set status = 'expired', submitted_at = now() where id = p_attempt_id;
    select * into v_attempt from public.attempts where id = p_attempt_id;
  end if;
  select public.exam_payload(v_attempt.exam_id) into v_payload;
  return v_payload || jsonb_build_object(
    'attemptId', v_attempt.id, 'status', v_attempt.status, 'expiresAt', v_attempt.expires_at,
    'answers', coalesce((select jsonb_object_agg(question_id, selected_option_id)
                         from public.attempt_answers where attempt_id = v_attempt.id), '{}'::jsonb)
  );
end;
$$;

create or replace function public.save_attempt_answer(
  p_attempt_id uuid, p_question_id uuid, p_option_id uuid, p_guest_token text default null
)
returns void language plpgsql security definer set search_path = public as $$
declare v_attempt public.attempts;
begin
  if not public.can_access_attempt(p_attempt_id, p_guest_token) then raise exception 'Not allowed'; end if;
  select * into v_attempt from public.attempts where id = p_attempt_id for update;
  if v_attempt.status <> 'in_progress' or now() >= v_attempt.expires_at then
    if v_attempt.status = 'in_progress' then
      update public.attempts set status = 'expired', submitted_at = now() where id = p_attempt_id;
    end if;
    raise exception 'Attempt is closed';
  end if;
  if not exists (select 1 from public.questions where id = p_question_id and exam_id = v_attempt.exam_id) then
    raise exception 'Question is not in this exam';
  end if;
  if not exists (select 1 from public.question_options o join public.questions q on q.id = o.question_id
                 where o.id = p_option_id and q.id = p_question_id) then
    raise exception 'Option is not in this question';
  end if;
  insert into public.attempt_answers (attempt_id, question_id, selected_option_id)
  values (p_attempt_id, p_question_id, p_option_id)
  on conflict (attempt_id, question_id) do update
    set selected_option_id = excluded.selected_option_id, answered_at = now();
end;
$$;

create or replace function public.submit_attempt(p_attempt_id uuid, p_guest_token text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_attempt public.attempts; v_score numeric(8,2); v_release boolean;
begin
  if not public.can_access_attempt(p_attempt_id, p_guest_token) then raise exception 'Not allowed'; end if;
  select * into v_attempt from public.attempts where id = p_attempt_id for update;
  if v_attempt.status not in ('in_progress', 'expired') then raise exception 'Attempt was already submitted'; end if;
  select coalesce(sum(q.points), 0) into v_score
  from public.attempt_answers a
  join public.questions q on q.id = a.question_id
  join public.question_options o on o.id = a.selected_option_id
  where a.attempt_id = v_attempt.id and o.is_correct;
  v_release := v_attempt.room_id is null;
  if not v_release then
    select status = 'closed' into v_release from public.rooms where id = v_attempt.room_id;
  end if;
  update public.attempts
  set status = case when now() >= expires_at then 'expired' else 'submitted' end,
      submitted_at = now(), score = v_score,
      result_released_at = case when v_release then now() else null end
  where id = v_attempt.id
  returning * into v_attempt;
  return jsonb_build_object('attemptId', v_attempt.id, 'status', v_attempt.status,
    'resultReleased', v_attempt.result_released_at is not null,
    'score', case when v_attempt.result_released_at is not null then v_attempt.score else null end);
end;
$$;

grant execute on function public.exam_payload(uuid) to anon, authenticated;
grant execute on function public.begin_practice_attempt(uuid) to anon, authenticated;
grant execute on function public.attempt_payload(uuid, text) to anon, authenticated;
grant execute on function public.save_attempt_answer(uuid, uuid, uuid, text) to anon, authenticated;
grant execute on function public.submit_attempt(uuid, text) to anon, authenticated;
