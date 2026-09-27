-- Migration: Revoke public access to user_otps table
-- Native Supabase Auth manages OTPs directly; public access must be removed.

drop policy if exists "Allow read write for user_otps" on public.user_otps;

-- Restrict all access so anonymous users cannot read or overwrite OTPs
create policy "No public access for user_otps" on public.user_otps
  for all using (false) with check (false);
