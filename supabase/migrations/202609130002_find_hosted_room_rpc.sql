-- Migration: find_hosted_room RPC to route room creator directly to host dashboard
create or replace function public.find_hosted_room(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_teacher_id uuid;
  v_room public.rooms;
begin
  if auth.uid() is null then
    return null;
  end if;

  select id into v_teacher_id from public.teachers where owner_user_id = auth.uid();
  if v_teacher_id is null then
    return null;
  end if;

  select r.* into v_room from public.rooms r
  where (r.code = upper(trim(p_code)) or r.id::text = trim(p_code))
    and r.teacher_id = v_teacher_id
  limit 1;

  if not found then
    return null;
  end if;

  return jsonb_build_object(
    'id', v_room.id,
    'code', v_room.code,
    'status', v_room.status
  );
end;
$$;

grant execute on function public.find_hosted_room(text) to authenticated, anon;
