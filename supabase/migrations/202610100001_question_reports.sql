-- Student question reports and teacher resolution workflow.

create table if not exists public.question_reports (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  attempt_id uuid not null references public.attempts(id) on delete cascade,
  reporter_id uuid references auth.users(id) on delete set null,
  category text not null check (category in (
    'wrong_answer', 'unclear_question', 'typo', 'wrong_explanation', 'other'
  )),
  detail text,
  status text not null default 'pending' check (status in ('pending', 'resolved', 'dismissed')),
  teacher_note text,
  resolved_by uuid references auth.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (detail is null or char_length(trim(detail)) between 3 and 1000)
);

create index if not exists question_reports_exam_status_idx
  on public.question_reports (exam_id, status, created_at desc);
create index if not exists question_reports_question_idx
  on public.question_reports (question_id, created_at desc);

create unique index if not exists question_reports_attempt_question_category_uidx
  on public.question_reports (attempt_id, question_id, category);

alter table public.question_reports enable row level security;

drop policy if exists "reporters read own question reports" on public.question_reports;
create policy "reporters read own question reports"
  on public.question_reports for select
  using (reporter_id = auth.uid());

drop policy if exists "teachers read reports for own exams" on public.question_reports;
create policy "teachers read reports for own exams"
  on public.question_reports for select
  using (exists (
    select 1 from public.exams e
    join public.teachers t on t.id = e.teacher_id
    where e.id = question_reports.exam_id and t.owner_user_id = auth.uid()
  ));

create or replace function public.submit_question_report(
  p_attempt_id uuid,
  p_question_id uuid,
  p_category text,
  p_detail text default null,
  p_guest_token text default null
) returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_attempt public.attempts%rowtype;
  v_report_id uuid;
begin
  select * into v_attempt from public.attempts where id = p_attempt_id;
  if not found then raise exception 'Attempt not found'; end if;

  if v_attempt.user_id is not null then
    if auth.uid() is null or v_attempt.user_id <> auth.uid() then
      raise exception 'Not allowed to report from this attempt';
    end if;
  elsif p_guest_token is null or v_attempt.guest_access_token_hash is null
      or crypt(p_guest_token, v_attempt.guest_access_token_hash) <> v_attempt.guest_access_token_hash then
    raise exception 'Invalid guest token';
  end if;

  if not exists (
    select 1 from public.questions q
    where q.id = p_question_id and q.exam_id = v_attempt.exam_id
  ) then
    raise exception 'Question is not in this attempt';
  end if;

  if p_category not in ('wrong_answer', 'unclear_question', 'typo', 'wrong_explanation', 'other') then
    raise exception 'Invalid report category';
  end if;

  insert into public.question_reports (
    exam_id, question_id, attempt_id, reporter_id, category, detail
  ) values (
    v_attempt.exam_id, p_question_id, p_attempt_id, auth.uid(), p_category,
    nullif(trim(coalesce(p_detail, '')), '')
  )
  on conflict (attempt_id, question_id, category) do update
    set detail = excluded.detail,
        status = 'pending',
        teacher_note = null,
        resolved_by = null,
        resolved_at = null,
        updated_at = now()
  returning id into v_report_id;

  return v_report_id;
end;
$$;

create or replace function public.teacher_question_reports()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.id,
    'examId', r.exam_id,
    'examTitle', e.title,
    'questionId', r.question_id,
    'questionPosition', q.position,
    'questionBody', q.body,
    'category', r.category,
    'detail', coalesce(r.detail, ''),
    'status', r.status,
    'teacherNote', coalesce(r.teacher_note, ''),
    'createdAt', r.created_at,
    'resolvedAt', r.resolved_at
  ) order by (r.status = 'pending') desc, r.created_at desc), '[]'::jsonb)
  from public.question_reports r
  join public.exams e on e.id = r.exam_id
  join public.teachers t on t.id = e.teacher_id
  join public.questions q on q.id = r.question_id
  where t.owner_user_id = auth.uid();
$$;

create or replace function public.resolve_question_report(
  p_report_id uuid,
  p_status text,
  p_teacher_note text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_status not in ('resolved', 'dismissed') then
    raise exception 'Invalid resolution status';
  end if;

  update public.question_reports r
  set status = p_status,
      teacher_note = nullif(trim(coalesce(p_teacher_note, '')), ''),
      resolved_by = auth.uid(),
      resolved_at = now(),
      updated_at = now()
  where r.id = p_report_id
    and exists (
      select 1 from public.exams e
      join public.teachers t on t.id = e.teacher_id
      where e.id = r.exam_id and t.owner_user_id = auth.uid()
    );

  if not found then raise exception 'Report not found or not allowed'; end if;
end;
$$;

grant execute on function public.submit_question_report(uuid, uuid, text, text, text) to anon, authenticated;
grant execute on function public.teacher_question_reports() to authenticated;
grant execute on function public.resolve_question_report(uuid, text, text) to authenticated;
