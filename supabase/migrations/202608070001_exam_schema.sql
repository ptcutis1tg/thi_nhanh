-- Thi Nhanh core assessment schema.
-- Run this in Supabase SQL editor or via `supabase db push`.
-- No project URL, publishable key, or service-role key belongs in this file.

create extension if not exists pgcrypto;

create type public.exam_difficulty as enum ('easy', 'medium', 'hard');
create type public.exam_status as enum ('draft', 'published', 'archived');
create type public.room_status as enum ('waiting', 'live', 'closed');
create type public.attempt_status as enum ('in_progress', 'submitted', 'expired');

create table public.teachers (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid unique references auth.users(id) on delete set null,
  display_name text not null check (char_length(trim(display_name)) between 2 and 120),
  bio text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.exams (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^DT[0-9]{6}$'),
  teacher_id uuid not null references public.teachers(id) on delete restrict,
  title text not null check (char_length(trim(title)) between 3 and 240),
  description text,
  subject text not null,
  difficulty public.exam_difficulty not null default 'medium',
  duration_minutes integer not null check (duration_minutes between 1 and 360),
  status public.exam_status not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((status = 'published') = (published_at is not null))
);

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  position integer not null check (position > 0),
  body text not null,
  explanation text,
  points numeric(6, 2) not null default 1 check (points > 0),
  created_at timestamptz not null default now(),
  unique (exam_id, position)
);

create table public.question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  position integer not null check (position between 1 and 8),
  body text not null,
  is_correct boolean not null default false,
  unique (question_id, position)
);

create unique index question_options_one_correct_answer
  on public.question_options (question_id) where is_correct;

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^PT[0-9]{6}$'),
  exam_id uuid not null references public.exams(id) on delete restrict,
  teacher_id uuid not null references public.teachers(id) on delete restrict,
  name text not null check (char_length(trim(name)) between 3 and 160),
  password_hash text,
  status public.room_status not null default 'waiting',
  max_participants integer check (max_participants between 1 and 1000),
  scheduled_start_at timestamptz,
  started_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  check (closed_at is null or started_at is not null)
);

create table public.attempts (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete restrict,
  room_id uuid references public.rooms(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  guest_name text,
  status public.attempt_status not null default 'in_progress',
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  score numeric(8, 2),
  check (user_id is not null or guest_name is not null),
  check (submitted_at is null or submitted_at >= started_at)
);

create table public.attempt_answers (
  attempt_id uuid not null references public.attempts(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete restrict,
  selected_option_id uuid references public.question_options(id) on delete set null,
  answered_at timestamptz not null default now(),
  primary key (attempt_id, question_id)
);

create index exams_browse_index on public.exams (status, subject, published_at desc);
create index questions_exam_index on public.questions (exam_id, position);
create index rooms_browse_index on public.rooms (status, scheduled_start_at desc);
create index attempts_user_index on public.attempts (user_id, started_at desc);

-- A deliberately narrow browse surface. Direct reads of `rooms` are forbidden
-- because that table contains password hashes.
create view public.room_summaries
with (security_invoker = false) as
select
  r.id,
  r.code,
  r.exam_id,
  r.teacher_id,
  r.name,
  r.status,
  r.max_participants,
  r.scheduled_start_at,
  r.created_at,
  (r.password_hash is not null) as is_password_protected
from public.rooms r;

grant select on public.room_summaries to anon, authenticated;

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger exams_set_updated_at before update on public.exams
for each row execute function public.set_updated_at();

alter table public.teachers enable row level security;
alter table public.exams enable row level security;
alter table public.questions enable row level security;
alter table public.question_options enable row level security;
alter table public.rooms enable row level security;
alter table public.attempts enable row level security;
alter table public.attempt_answers enable row level security;

create policy "teachers are public" on public.teachers for select using (true);
create policy "published exams are public" on public.exams for select using (status = 'published');
create policy "users read their own attempts" on public.attempts for select using (user_id = auth.uid());
create policy "users create their own attempts" on public.attempts for insert with check (user_id = auth.uid());
create policy "users update active own attempts" on public.attempts for update using (user_id = auth.uid() and status = 'in_progress');
create policy "users read their own answers" on public.attempt_answers for select using (
  exists (select 1 from public.attempts a where a.id = attempt_id and a.user_id = auth.uid())
);
create policy "users write their own answers" on public.attempt_answers for insert with check (
  exists (select 1 from public.attempts a where a.id = attempt_id and a.user_id = auth.uid() and a.status = 'in_progress')
);
create policy "users update their own answers" on public.attempt_answers for update using (
  exists (select 1 from public.attempts a where a.id = attempt_id and a.user_id = auth.uid() and a.status = 'in_progress')
);

-- `questions` and `question_options` intentionally have no student SELECT policy.
-- Fetch a sanitized exam payload and submit answers through authenticated RPC/Edge
-- Functions; never send `is_correct`, `explanation`, or `password_hash` to clients.
