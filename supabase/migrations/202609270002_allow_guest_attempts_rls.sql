-- ==============================================================================
-- Migration: 202609270002_allow_guest_attempts_rls.sql
-- Mục đích: Cho phép cả người dùng đăng nhập và khách (guest) nộp bài thi
--           Khắc phục triệt để lỗi PostgrestException 42501 (RLS policy violation)
-- ==============================================================================

-- 1. Nới lỏng ràng buộc check token khách để cho phép nộp bài trực tiếp với guest_name
alter table public.attempts drop constraint if exists attempts_guest_token_required;
alter table public.attempts add constraint attempts_guest_token_required
  check (user_id is not null or guest_name is not null or guest_access_token_hash is not null);

-- 2. Cập nhật RLS Policy cho INSERT trên public.attempts
drop policy if exists "users create their own attempts" on public.attempts;
drop policy if exists "allow creating attempts" on public.attempts;
create policy "allow creating attempts" on public.attempts
  for insert with check (
    (user_id is not null and user_id = auth.uid())
    or
    (user_id is null and (guest_name is not null or guest_access_token_hash is not null))
  );

-- 3. Cập nhật RLS Policy cho UPDATE trên public.attempts
drop policy if exists "users update active own attempts" on public.attempts;
drop policy if exists "allow updating active attempts" on public.attempts;
create policy "allow updating active attempts" on public.attempts
  for update using (
    (user_id is not null and user_id = auth.uid() and status = 'in_progress')
    or
    (user_id is null and status = 'in_progress')
  );

-- 4. Cập nhật RLS Policy cho SELECT trên public.attempts
drop policy if exists "users read their own attempts" on public.attempts;
drop policy if exists "allow reading attempts" on public.attempts;
create policy "allow reading attempts" on public.attempts
  for select using (
    (user_id is not null and user_id = auth.uid())
    or
    (user_id is null)
    or
    (exists (select 1 from public.exams e where e.id = attempts.exam_id and e.teacher_id in (
      select t.id from public.teachers t where t.owner_user_id = auth.uid()
    )))
  );
