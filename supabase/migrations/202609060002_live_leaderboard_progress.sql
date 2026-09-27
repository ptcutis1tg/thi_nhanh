-- Rank participants from their live answers so the leaderboard can move while
-- an exam is still in progress, instead of waiting for attempt submission.

create or replace function public.get_room_leaderboard(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_room public.rooms;
  v_total_questions integer;
begin
  select * into v_room from public.rooms where id = p_room_id;
  if not found then raise exception 'Room not found'; end if;

  select count(*) into v_total_questions
  from public.questions
  where exam_id = v_room.exam_id;

  return coalesce((
    with participant_stats as (
      select
        rp.id as participant_id,
        coalesce(nullif(p.display_name, ''), rp.guest_name, 'Học sinh') as name,
        case
          when a.status in ('submitted', 'expired') then 'submitted'
          when a.status = 'in_progress' then 'in_progress'
          else 'waiting'
        end as attempt_status,
        coalesce(sum(q.points) filter (where qo.is_correct), 0) as live_score,
        count(aa.question_id) filter (where qo.is_correct) as correct_count,
        case
          when a.submitted_at is not null
            then extract(epoch from (a.submitted_at - a.started_at))::integer
          else null
        end as duration_seconds,
        a.submitted_at,
        rp.requested_at
      from public.room_participants rp
      left join public.profiles p on p.id = rp.user_id
      left join public.attempts a on a.id = rp.attempt_id
      left join public.attempt_answers aa on aa.attempt_id = a.id
      left join public.question_options qo on qo.id = aa.selected_option_id
      left join public.questions q on q.id = aa.question_id
      where rp.room_id = v_room.id and rp.status <> 'left'
      group by rp.id, p.display_name, rp.guest_name, a.status, a.submitted_at,
        a.started_at, rp.requested_at
    ),
    ranked as (
      select
        participant_stats.*,
        row_number() over (
          order by
            live_score desc,
            correct_count desc,
            case when attempt_status = 'submitted' then 1
                 when attempt_status = 'in_progress' then 2 else 3 end,
            coalesce(duration_seconds, 2147483647),
            requested_at
        ) as rank_no
      from participant_stats
    )
    select jsonb_agg(
      jsonb_build_object(
        'rank', rank_no,
        'participantId', participant_id,
        'name', name,
        'status', attempt_status,
        'score', live_score,
        'correctCount', correct_count,
        'totalQuestions', v_total_questions,
        'durationSeconds', duration_seconds,
        'submittedAt', submitted_at
      ) order by rank_no
    )
    from ranked
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_room_leaderboard(uuid) to anon, authenticated;
