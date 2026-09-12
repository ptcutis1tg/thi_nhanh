-- Migration: Bổ sung chính sách INSERT cho profiles và cờ xem trước của tác giả

-- 1. Bổ sung policy INSERT cho bảng profiles
drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile" on public.profiles
  for insert with check (id = auth.uid());

-- 2. Bổ sung policy DELETE cho profiles nếu cần
drop policy if exists "users delete own profile" on public.profiles;
create policy "users delete own profile" on public.profiles
  for delete using (id = auth.uid());

-- 3. Bổ sung cột is_author_preview trên attempts nếu chưa có
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'attempts' and column_name = 'is_author_preview'
  ) then
    alter table public.attempts add column is_author_preview boolean not null default false;
  end if;
end $$;

-- 4. Đảm bảo ensure_current_teacher cấp quyền tác giả an toàn cho mọi tài khoản
create or replace function public.ensure_current_teacher()
returns uuid language plpgsql security definer set search_path = public as $$
declare v_teacher_id uuid; v_name text;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  select id into v_teacher_id from public.teachers where owner_user_id = auth.uid();
  if v_teacher_id is not null then return v_teacher_id; end if;
  select coalesce(nullif(trim(display_name), ''), nullif(trim(auth.jwt() ->> 'email'), ''), 'Thành viên')
    into v_name from public.profiles where id = auth.uid();
  insert into public.teachers (owner_user_id, display_name)
  values (auth.uid(), coalesce(v_name, 'Thành viên')) returning id into v_teacher_id;
  return v_teacher_id;
end;
$$;
