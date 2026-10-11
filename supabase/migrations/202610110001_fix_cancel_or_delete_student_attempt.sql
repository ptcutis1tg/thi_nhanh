-- Migration: 202610110001_fix_cancel_or_delete_student_attempt.sql
-- Cho phép học sinh xóa hoặc hủy bài thi dở dang của chính mình

-- 1. Bổ sung policy DELETE cho attempts dở dang
drop policy if exists "allow deleting own in_progress attempts" on public.attempts;
create policy "allow deleting own in_progress attempts" on public.attempts
  for delete
  using (
    status = 'in_progress' and (
      (auth.uid() is not null and auth.uid() = user_id) or
      (guest_name is not null)
    )
  );

-- 2. RPC an toàn hủy hoặc xóa bài thi dở dang
create or replace function public.cancel_or_delete_student_attempt(p_attempt_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt public.attempts%rowtype;
begin
  select * into v_attempt from public.attempts where id = p_attempt_id;
  if not found then
    return false;
  end if;

  -- Chỉ cho phép hủy bài nếu là in_progress
  if v_attempt.status != 'in_progress' then
    return false;
  end if;

  -- Kiểm tra quyền
  if v_user_id is not null and v_attempt.user_id is not null and v_attempt.user_id != v_user_id then
    return false;
  end if;

  -- Xóa attempt_answers liên quan (nếu có)
  delete from public.attempt_answers where attempt_id = p_attempt_id;

  -- Cố gắng xóa attempt
  delete from public.attempts where id = p_attempt_id;
  
  return true;
exception
  when others then
    -- Fallback cập nhật sang expired nếu không xóa được
    update public.attempts
    set status = 'expired', submitted_at = now()
    where id = p_attempt_id;
    return true;
end;
$$;

grant execute on function public.cancel_or_delete_student_attempt(uuid) to anon, authenticated;
