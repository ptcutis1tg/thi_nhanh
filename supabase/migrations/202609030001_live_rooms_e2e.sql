-- Live Rooms E2E: Student Join, Realtime State, and Live Leaderboards
-- Apply after 202608300005_live_rooms.sql.

create or replace function public.join_student_room(
  p_code text,
  p_password text default null,
  p_guest_name text default null
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_room public.rooms;
  v_exam public.exams;
  v_teacher public.teachers;
  v_participant public.room_participants;
  v_token text := null;
  v_user_id uuid;
  v_guest_name text;
  v_current_count integer;
  v_attempt public.attempts;
begin
  select * into v_room from public.rooms where code = upper(trim(p_code));
  if not found then raise exception 'Room not found with code: %', p_code; end if;
  if v_room.status = 'closed' then raise exception 'This room has already ended'; end if;

  if v_room.password_hash is not null then
    if p_password is null or extensions.crypt(p_password, v_room.password_hash) <> v_room.password_hash then
      raise exception 'Invalid room password';
    end if;
  end if;

  select count(*) into v_current_count
  from public.room_participants
  where room_id = v_room.id and status <> 'left';

  select * into v_exam from public.exams where id = v_room.exam_id;
  select * into v_teacher from public.teachers where id = v_room.teacher_id;

  v_user_id := auth.uid();

  if v_user_id is not null then
    select * into v_participant
    from public.room_participants
    where room_id = v_room.id and user_id = v_user_id;

    if found then
      if v_participant.status = 'left' then
        update public.room_participants
        set status = case when v_room.status = 'live' then 'approved'::public.room_participant_status else 'waiting'::public.room_participant_status end,
            approved_at = case when v_room.status = 'live' then now() else null end,
            last_seen_at = now()
        where id = v_participant.id
        returning * into v_participant;
      else
        update public.room_participants set last_seen_at = now() where id = v_participant.id returning * into v_participant;
      end if;
    else
      if v_current_count >= v_room.max_participants then raise exception 'Room is already full'; end if;
      insert into public.room_participants (room_id, user_id, status, approved_at)
      values (
        v_room.id,
        v_user_id,
        case when v_room.status = 'live' then 'approved'::public.room_participant_status else 'waiting'::public.room_participant_status end,
        case when v_room.status = 'live' then now() else null end
      )
      returning * into v_participant;
    end if;
  else
    v_guest_name := coalesce(nullif(trim(p_guest_name), ''), 'Học sinh');
    if v_current_count >= v_room.max_participants then raise exception 'Room is already full'; end if;
    v_token := encode(extensions.gen_random_bytes(32), 'hex');
    insert into public.room_participants (
      room_id, guest_name, guest_access_token_hash, status, approved_at
    )
    values (
      v_room.id,
      v_guest_name,
      extensions.crypt(v_token, extensions.gen_salt('bf')),
      case when v_room.status = 'live' then 'approved'::public.room_participant_status else 'waiting'::public.room_participant_status end,
      case when v_room.status = 'live' then now() else null end
    )
    returning * into v_participant;
  end if;

  -- If room is already live and participant has no attempt, create attempt now
  if v_room.status = 'live' and v_participant.attempt_id is null then
    insert into public.attempts (
      exam_id, room_id, user_id, guest_name, guest_access_token_hash, expires_at
    )
    values (
      v_room.exam_id,
      v_room.id,
      v_participant.user_id,
      v_participant.guest_name,
      v_participant.guest_access_token_hash,
      now() + make_interval(mins => v_exam.duration_minutes)
    )
    returning * into v_attempt;

    update public.room_participants
    set attempt_id = v_attempt.id
    where id = v_participant.id
    returning * into v_participant;
  end if;

  return jsonb_build_object(
    'roomId', v_room.id,
    'participantId', v_participant.id,
    'code', v_room.code,
    'name', v_room.name,
    'status', v_room.status,
    'examId', v_room.exam_id,
    'examTitle', v_exam.title,
    'subject', v_exam.subject,
    'durationMinutes', v_exam.duration_minutes,
    'teacherName', coalesce(v_teacher.display_name, 'Giáo viên'),
    'guestToken', v_token,
    'attemptId', v_participant.attempt_id
  );
end;
$$;

create or replace function public.get_student_room_state(
  p_room_id uuid,
  p_participant_id uuid,
  p_guest_token text default null
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_room public.rooms;
  v_exam public.exams;
  v_teacher public.teachers;
  v_participant public.room_participants;
  v_attempt public.attempts;
begin
  select * into v_room from public.rooms where id = p_room_id;
  if not found then raise exception 'Room not found'; end if;

  select * into v_participant from public.room_participants where id = p_participant_id and room_id = p_room_id;
  if not found then raise exception 'Participant not found in room'; end if;

  select * into v_exam from public.exams where id = v_room.exam_id;
  select * into v_teacher from public.teachers where id = v_room.teacher_id;

  if v_room.status = 'live' and v_participant.attempt_id is null then
    insert into public.attempts (
      exam_id, room_id, user_id, guest_name, guest_access_token_hash, expires_at
    )
    values (
      v_room.exam_id,
      v_room.id,
      v_participant.user_id,
      v_participant.guest_name,
      v_participant.guest_access_token_hash,
      now() + make_interval(mins => v_exam.duration_minutes)
    )
    returning * into v_attempt;

    update public.room_participants
    set attempt_id = v_attempt.id, status = 'approved', approved_at = coalesce(approved_at, now())
    where id = v_participant.id
    returning * into v_participant;
  end if;

  update public.room_participants set last_seen_at = now() where id = v_participant.id;

  return jsonb_build_object(
    'roomId', v_room.id,
    'code', v_room.code,
    'name', v_room.name,
    'status', v_room.status,
    'examId', v_room.exam_id,
    'examTitle', v_exam.title,
    'subject', v_exam.subject,
    'durationMinutes', v_exam.duration_minutes,
    'teacherName', coalesce(v_teacher.display_name, 'Giáo viên'),
    'participantStatus', v_participant.status,
    'attemptId', v_participant.attempt_id,
    'participantCount', (select count(*) from public.room_participants where room_id = v_room.id and status <> 'left'),
    'participants', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', rp.id,
        'name', coalesce(nullif(p.display_name, ''), rp.guest_name, 'Học sinh'),
        'status', rp.status,
        'isSelf', rp.id = v_participant.id
      ) order by rp.requested_at)
      from public.room_participants rp
      left join public.profiles p on p.id = rp.user_id
      where rp.room_id = v_room.id and rp.status <> 'left'
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.get_room_leaderboard(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_room public.rooms;
  v_total_questions integer;
begin
  select * into v_room from public.rooms where id = p_room_id;
  if not found then raise exception 'Room not found'; end if;

  select count(*) into v_total_questions from public.questions where exam_id = v_room.exam_id;

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'rank', sub.rank_no,
        'participantId', sub.participant_id,
        'name', sub.name,
        'status', sub.attempt_status,
        'score', sub.score,
        'correctCount', sub.correct_count,
        'totalQuestions', v_total_questions,
        'durationSeconds', sub.duration_seconds,
        'submittedAt', sub.submitted_at
      )
    )
    from (
      select
        rp.id as participant_id,
        coalesce(nullif(p.display_name, ''), rp.guest_name, 'Học sinh') as name,
        case
          when a.status = 'submitted' or a.status = 'expired' then 'submitted'
          when a.status = 'in_progress' then 'in_progress'
          else 'waiting'
        end as attempt_status,
        coalesce(a.score, 0) as score,
        coalesce((
          select count(*) from public.attempt_answers aa
          join public.question_options qo on qo.id = aa.selected_option_id
          where aa.attempt_id = a.id and qo.is_correct
        ), 0) as correct_count,
        case
          when a.submitted_at is not null then extract(epoch from (a.submitted_at - a.started_at))::integer
          else null
        end as duration_seconds,
        a.submitted_at,
        row_number() over (
          order by
            case when a.status in ('submitted', 'expired') then 1 when a.status = 'in_progress' then 2 else 3 end,
            coalesce(a.score, 0) desc,
            case when a.submitted_at is not null then extract(epoch from (a.submitted_at - a.started_at)) else 999999 end asc,
            rp.requested_at asc
        ) as rank_no
      from public.room_participants rp
      left join public.profiles p on p.id = rp.user_id
      left join public.attempts a on a.id = rp.attempt_id
      where rp.room_id = v_room.id and rp.status <> 'left'
    ) sub
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.join_student_room(text, text, text) to anon, authenticated;
grant execute on function public.get_student_room_state(uuid, uuid, text) to anon, authenticated;
grant execute on function public.get_room_leaderboard(uuid) to anon, authenticated;
