-- Fix submit_attempt assigning text values to the attempt_status enum.

create or replace function public.submit_attempt(
  p_attempt_id uuid,
  p_guest_token text default null
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_attempt public.attempts;
  v_score numeric(8,2);
  v_release boolean;
begin
  if not public.can_access_attempt(p_attempt_id, p_guest_token) then
    raise exception 'Not allowed';
  end if;

  select * into v_attempt
  from public.attempts
  where id = p_attempt_id
  for update;

  if v_attempt.status not in ('in_progress', 'expired') then
    raise exception 'Attempt was already submitted';
  end if;

  select coalesce(sum(q.points), 0) into v_score
  from public.attempt_answers a
  join public.questions q on q.id = a.question_id
  join public.question_options o on o.id = a.selected_option_id
  where a.attempt_id = v_attempt.id and o.is_correct;

  v_release := v_attempt.room_id is null;
  if not v_release then
    select status = 'closed' into v_release
    from public.rooms
    where id = v_attempt.room_id;
  end if;

  update public.attempts
  set status = case
        when now() >= expires_at then 'expired'::public.attempt_status
        else 'submitted'::public.attempt_status
      end,
      submitted_at = now(),
      score = v_score,
      result_released_at = case when v_release then now() else null end
  where id = v_attempt.id
  returning * into v_attempt;

  return jsonb_build_object(
    'attemptId', v_attempt.id,
    'status', v_attempt.status,
    'resultReleased', v_attempt.result_released_at is not null,
    'score', case when v_attempt.result_released_at is not null then v_attempt.score else null end
  );
end;
$$;

grant execute on function public.submit_attempt(uuid, text) to anon, authenticated;
