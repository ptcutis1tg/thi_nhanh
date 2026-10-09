-- Migration: 202610090001_saved_exams_and_host_permission.sql
-- Description: Table for saving community exams & authorization to host rooms from saved exams

create table if not exists public.saved_exams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, exam_id)
);

alter table public.saved_exams enable row level security;

-- Drop old policies if exist
drop policy if exists "users can manage their own saved exams" on public.saved_exams;
drop policy if exists "users can view their saved exams" on public.saved_exams;

create policy "users can manage their own saved exams"
on public.saved_exams
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can view their saved exams"
on public.saved_exams
for select
to authenticated
using (auth.uid() = user_id);

-- Update create_teacher_room to allow creating room from saved published exams
create or replace function public.create_teacher_room(
  p_exam_id uuid, p_name text, p_password text default null, p_max_participants integer default 50
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_teacher_id uuid; v_room public.rooms;
begin
  v_teacher_id := public.ensure_current_teacher();
  if char_length(trim(p_name)) < 3 then raise exception 'Room name must have at least 3 characters'; end if;
  if p_max_participants not between 1 and 1000 then raise exception 'Participant limit must be between 1 and 1000'; end if;
  
  -- Cho phép đề do chính giáo viên tạo HOẶC đề đã được giáo viên lưu về kho cá nhân
  if not exists (
    select 1 from public.exams e
    where e.id = p_exam_id and e.status = 'published'
    and (
      e.teacher_id = v_teacher_id
      or exists (
        select 1 from public.saved_exams se
        where se.exam_id = e.id and se.user_id = auth.uid()
      )
    )
  ) then
    raise exception 'Chỉ có thể tạo phòng từ đề đã xuất bản của bạn hoặc đề bạn đã lưu từ cộng đồng';
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

grant execute on function public.create_teacher_room(uuid, text, text, integer) to authenticated;
