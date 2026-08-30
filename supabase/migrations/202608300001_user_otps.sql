-- Migration: Create user_otps table for OTP code storage and verification
-- Run this in Supabase SQL editor or via `supabase db push`

create table if not exists public.user_otps (
  email text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  otp_code text not null check (otp_code ~ '^[0-9]{6}$'),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_otps enable row level security;

-- Policies for public.user_otps
create policy "Allow read write for user_otps" on public.user_otps
  for all using (true) with check (true);
