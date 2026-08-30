-- Real teacher-owned rooms. Sensitive columns stay server-side; clients only
-- receive narrow JSON payloads from these RPCs.

create or replace function public.next_room_code()
returns text language plpgsql security definer set search_path = public as $$
declare v_code text;
begin
  loop
    v_code := 'PT' || lpad(floor(random() * 1000000)::integer::text, 6, '0');
    exit when not exists (select 1 from public.rooms where code = v_code);
  end loop;
  return v_code;
end;
$$;

create or replace function public.create_teacher_room(
  p_exam_id uuid, p_name text, p_password text default null, p_max_participants integer default 50
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_teacher_id uuid; v_room public.rooms;
begin
  v_teacher_id := public.ensure_current_teacher();
  if char_length(trim(p_name)) < 3 then raise exception 'Room name must have at least 3 characters'; end if;
  if p_max_participants not between 1 and 1000 then raise exception 'Participant limit must be between 1 and 1000'; end if;
  if not exists (select 1 from public.exams where id = p_exam_id and teacher_id = v_teacher_id and status = 'published') then
    raise exception 'Only one of your published exams can be used for a room';
  end if;

  insert into public.rooms (code, exam_id, teacher_id, name, password_hash, max_participants)
  values (
    public.next_room_code(), p_exam_id, v_teacher_id, trim(p_name),
    case when nullif(trim(coalesce(p_password, '')), '') is null then null else extensions.crypt(p_password, extensions.gen_salt('bf')) end,
    p_max_participants
  ) returning * into v_room;
  return jsonb_build_object('id', v_room.id, 'code', v_room.code, 'name', v_room.name, 'status', v_room.status);
end;
$$;

create or replace function public.teacher_room_dashboard(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_room public.rooms;
begin
  select r.* into v_room from public.rooms r
  where r.id = p_room_id and r.teacher_id = public.ensure_current_teacher();
  if not found then raise exception 'Room not found'; end if;
  return jsonb_build_object(
    'id', v_room.id, 'code', v_room.code, 'name', v_room.name, 'status', v_room.status,
    'examTitle', (select title from public.exams where id = v_room.exam_id),
    'subject', (select subject from public.exams where id = v_room.exam_id),
    'durationMinutes', (select duration_minutes from public.exams where id = v_room.exam_id),
    'maxParticipants', v_room.max_participants,
    'participants', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', rp.id,
        'name', coalesce(nullif(p.display_name, ''), rp.guest_name, 'Học sinh'),
        'status', rp.status,
        'requestedAt', rp.requested_at
      ) order by rp.requested_at)
      from public.room_participants rp left join public.profiles p on p.id = rp.user_id
      where rp.room_id = v_room.id and rp.status <> 'left'
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.start_teacher_room(p_room_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_room public.rooms; v_duration integer;
begin
  select r.* into v_room from public.rooms r
  where r.id = p_room_id and r.teacher_id = public.ensure_current_teacher() for update;
  if not found then raise exception 'Room not found'; end if;
  if v_room.status <> 'waiting' then raise exception 'Room has already started or closed'; end if;
  select duration_minutes into v_duration from public.exams where id = v_room.exam_id;
  update public.rooms set status = 'live', started_at = now() where id = v_room.id;
  update public.room_participants
    set status = 'approved', approved_at = now()
    where room_id = v_room.id and status = 'waiting';
  insert into public.attempts (exam_id, room_id, user_id, guest_name, guest_access_token_hash, expires_at)
  select v_room.exam_id, v_room.id, rp.user_id, rp.guest_name, rp.guest_access_token_hash,
    now() + make_interval(mins => v_duration)
  from public.room_participants rp
  where rp.room_id = v_room.id and rp.status = 'approved' and rp.attempt_id is null;
  update public.room_participants rp set attempt_id = a.id
  from public.attempts a where a.room_id = v_room.id and a.user_id is not distinct from rp.user_id
    and a.guest_name is not distinct from rp.guest_name and rp.room_id = v_room.id and rp.attempt_id is null;
  return public.teacher_room_dashboard(v_room.id);
end;
$$;

grant execute on function public.create_teacher_room(uuid, text, text, integer) to authenticated;
grant execute on function public.teacher_room_dashboard(uuid) to authenticated;
grant execute on function public.start_teacher_room(uuid) to authenticated;
