-- Migration: Add close_teacher_room RPC function
-- Description: Allows teachers to close a live room, finalize in-progress attempts, compute weighted scores, and release results to participants.

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

grant execute on function public.close_teacher_room(uuid) to authenticated;
