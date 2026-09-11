-- Migration: 202609110001_hybrid_storage_and_8_subjects_seed.sql
-- Hybrid CQRS Exam Storage + 24 High Quality Exams Seed Across 8 Subjects

create extension if not exists pgcrypto;

-- ===========================================================================
-- 1. HYBRID CQRS SCHEMA ENHANCEMENT
-- ===========================================================================
alter table public.exams add column if not exists snapshot_payload jsonb;
create index if not exists idx_exams_snapshot_payload on public.exams using gin (snapshot_payload);

-- Function to generate a clean anti-cheat snapshot payload for an exam
create or replace function public.fn_rebuild_exam_snapshot(p_exam_id uuid)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_payload jsonb;
begin
  select jsonb_build_object(
    'id', e.id,
    'code', e.code,
    'title', e.title,
    'description', e.description,
    'subject', e.subject,
    'difficulty', e.difficulty,
    'duration_minutes', e.duration_minutes,
    'total_questions', count(q.id),
    'questions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', q_sub.id,
            'position', q_sub.position,
            'body', q_sub.body,
            'points', q_sub.points,
            'question_options', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'id', o.id,
                    'position', o.position,
                    'body', o.body
                  ) order by o.position
                )
                from public.question_options o
                where o.question_id = q_sub.id
              ),
              '[]'::jsonb
            ),
            'options', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'id', o.id,
                    'position', o.position,
                    'body', o.body
                  ) order by o.position
                )
                from public.question_options o
                where o.question_id = q_sub.id
              ),
              '[]'::jsonb
            )
          ) order by q_sub.position
        )
        from public.questions q_sub
        where q_sub.exam_id = e.id
      ),
      '[]'::jsonb
    )
  )
  into v_payload
  from public.exams e
  left join public.questions q on q.exam_id = e.id
  where e.id = p_exam_id
  group by e.id;

  update public.exams
  set snapshot_payload = v_payload
  where id = p_exam_id;

  return v_payload;
end;
$$;

-- Automated Trigger to keep snapshots synced
create or replace function public.fn_trigger_sync_exam_snapshot()
returns trigger
language plpgsql
security definer
as $$
declare
  v_exam_id uuid;
begin
  if tg_table_name = 'questions' then
    v_exam_id := coalesce(new.exam_id, old.exam_id);
  elsif tg_table_name = 'question_options' then
    select exam_id into v_exam_id
    from public.questions
    where id = coalesce(new.question_id, old.question_id);
  end if;

  if v_exam_id is not null then
    perform public.fn_rebuild_exam_snapshot(v_exam_id);
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_sync_exam_snapshot_questions on public.questions;
create trigger trg_sync_exam_snapshot_questions
after insert or update or delete on public.questions
for each row execute function public.fn_trigger_sync_exam_snapshot();

drop trigger if exists trg_sync_exam_snapshot_options on public.question_options;
create trigger trg_sync_exam_snapshot_options
after insert or update or delete on public.question_options
for each row execute function public.fn_trigger_sync_exam_snapshot();

-- ===========================================================================
-- 2. SPECIALIZED TEACHERS FOR 8 SUBJECTS
-- ===========================================================================
insert into public.teachers (id, display_name, bio)
values ('00000000-0000-4000-8000-000000000001', 'Thầy Nguyễn Văn A', 'Giáo viên Toán THPT Chuyên.')
on conflict (id) do update set display_name = excluded.display_name, bio = excluded.bio;
insert into public.teachers (id, display_name, bio)
values ('00000000-0000-4000-8000-000000000002', 'Cô Lê Thị B', 'Giáo viên Vật lý THPT Quốc gia.')
on conflict (id) do update set display_name = excluded.display_name, bio = excluded.bio;
insert into public.teachers (id, display_name, bio)
values ('00000000-0000-4000-8000-000000000003', 'Cô Trần Thị C', 'Giáo viên Tiếng Anh & IELTS 8.5.')
on conflict (id) do update set display_name = excluded.display_name, bio = excluded.bio;
insert into public.teachers (id, display_name, bio)
values ('00000000-0000-4000-8000-000000000004', 'Cô Phạm Thị D', 'Giáo viên Hóa học THPT.')
on conflict (id) do update set display_name = excluded.display_name, bio = excluded.bio;
insert into public.teachers (id, display_name, bio)
values ('00000000-0000-4000-8000-000000000005', 'Thầy Vũ Đình E', 'Giáo viên Sinh học THPT.')
on conflict (id) do update set display_name = excluded.display_name, bio = excluded.bio;
insert into public.teachers (id, display_name, bio)
values ('00000000-0000-4000-8000-000000000006', 'Thầy Hoàng Văn F', 'Giáo viên Lịch sử THPT.')
on conflict (id) do update set display_name = excluded.display_name, bio = excluded.bio;
insert into public.teachers (id, display_name, bio)
values ('00000000-0000-4000-8000-000000000007', 'Cô Đặng Thị G', 'Giáo viên Địa lý THPT.')
on conflict (id) do update set display_name = excluded.display_name, bio = excluded.bio;
insert into public.teachers (id, display_name, bio)
values ('00000000-0000-4000-8000-000000000008', 'Thầy Ngô Bá H', 'Giáo viên Tin học & Lập trình THPT.')
on conflict (id) do update set display_name = excluded.display_name, bio = excluded.bio;

-- ===========================================================================
-- 3. 24 HIGH QUALITY EXAMS (8 SUBJECTS X 3 EXAMS)
-- ===========================================================================
-- Exam #1: DT010101 - Toán học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000001', 'DT010101', '00000000-0000-4000-8000-000000000001', 'Toán 12 - Khảo sát hàm số & Ứng dụng đạo hàm (Đề 1)', 'Cực trị, tính đơn điệu, tiệm cận và giá trị lớn nhất - nhỏ nhất.', 'Toán học', 'medium', 45, 'published', now() - interval '24 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001', 1, 'Cho hàm số y = f(x) có f''(x) = x(x - 1)(x + 2)². Số điểm cực trị của hàm số là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000001', 1, '1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000002', '21000000-0000-4000-8000-000000000001', 2, '2', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000003', '21000000-0000-4000-8000-000000000001', 3, '3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000004', '21000000-0000-4000-8000-000000000001', 4, '4', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000001', 2, 'Hàm số y = -x³ + 3x² - 1 đồng biến trên khoảng nào sau đây?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000005', '21000000-0000-4000-8000-000000000002', 1, '(0; 2)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000006', '21000000-0000-4000-8000-000000000002', 2, '(-∞; 0)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000007', '21000000-0000-4000-8000-000000000002', 3, '(2; +∞)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000008', '21000000-0000-4000-8000-000000000002', 4, '(-∞; 2)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000003', '11000000-0000-4000-8000-000000000001', 3, 'Đường tiệm cận ngang của đồ thị hàm số y = (2x - 1) / (x + 3) là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000009', '21000000-0000-4000-8000-000000000003', 1, 'y = 2', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000010', '21000000-0000-4000-8000-000000000003', 2, 'x = -3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000011', '21000000-0000-4000-8000-000000000003', 3, 'y = -1/3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000012', '21000000-0000-4000-8000-000000000003', 4, 'x = 2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000004', '11000000-0000-4000-8000-000000000001', 4, 'Đồ thị hàm số y = x⁴ - 2x² + 3 có bao nhiêu điểm cực trị?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000013', '21000000-0000-4000-8000-000000000004', 1, '3', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000014', '21000000-0000-4000-8000-000000000004', 2, '1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000015', '21000000-0000-4000-8000-000000000004', 3, '2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000016', '21000000-0000-4000-8000-000000000004', 4, '0', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000005', '11000000-0000-4000-8000-000000000001', 5, 'Giá trị nhỏ nhất của hàm số f(x) = x³ - 3x + 2 trên đoạn [0; 2] là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000017', '21000000-0000-4000-8000-000000000005', 1, '0', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000018', '21000000-0000-4000-8000-000000000005', 2, '2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000019', '21000000-0000-4000-8000-000000000005', 3, '4', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000020', '21000000-0000-4000-8000-000000000005', 4, '-1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000006', '11000000-0000-4000-8000-000000000001', 6, 'Điểm cực đại của đồ thị hàm số y = x³ - 3x + 1 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000021', '21000000-0000-4000-8000-000000000006', 1, '(-1; 3)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000022', '21000000-0000-4000-8000-000000000006', 2, '(1; -1)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000023', '21000000-0000-4000-8000-000000000006', 3, '(0; 1)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000024', '21000000-0000-4000-8000-000000000006', 4, '(2; 3)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000007', '11000000-0000-4000-8000-000000000001', 7, 'Đường tiệm cận đứng của đồ thị hàm số y = (x + 1) / (x - 2) là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000025', '21000000-0000-4000-8000-000000000007', 1, 'x = 2', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000026', '21000000-0000-4000-8000-000000000007', 2, 'y = 1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000027', '21000000-0000-4000-8000-000000000007', 3, 'x = -1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000028', '21000000-0000-4000-8000-000000000007', 4, 'y = 2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000008', '11000000-0000-4000-8000-000000000001', 8, 'Số giao điểm của đồ thị hàm số y = x³ - 3x và trục hoành là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000029', '21000000-0000-4000-8000-000000000008', 1, '3', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000030', '21000000-0000-4000-8000-000000000008', 2, '1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000031', '21000000-0000-4000-8000-000000000008', 3, '2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000032', '21000000-0000-4000-8000-000000000008', 4, '0', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000009', '11000000-0000-4000-8000-000000000001', 9, 'Tiếp tuyến của đồ thị hàm số y = x³ - 3x + 2 tại điểm có hoành độ x = 0 có hệ số góc bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000033', '21000000-0000-4000-8000-000000000009', 1, '-3', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000034', '21000000-0000-4000-8000-000000000009', 2, '3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000035', '21000000-0000-4000-8000-000000000009', 3, '0', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000036', '21000000-0000-4000-8000-000000000009', 4, '2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000010', '11000000-0000-4000-8000-000000000001', 10, 'Hàm số nào sau đây luôn đồng biến trên tập xác định R?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000037', '21000000-0000-4000-8000-000000000010', 1, 'y = x³ + 3x - 1', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000038', '21000000-0000-4000-8000-000000000010', 2, 'y = x³ - 3x', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000039', '21000000-0000-4000-8000-000000000010', 3, 'y = x⁴ + 2x²', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000040', '21000000-0000-4000-8000-000000000010', 4, 'y = (x - 1)/(x + 1)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #2: DT010102 - Toán học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000002', 'DT010102', '00000000-0000-4000-8000-000000000001', 'Toán 12 - Nguyên hàm, Tích phân & Hình Oxyz (Đề 2)', 'Phương pháp tính tích phân, ứng dụng diện tích và tọa độ trong không gian.', 'Toán học', 'medium', 45, 'published', now() - interval '23 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000011', '11000000-0000-4000-8000-000000000002', 1, 'Họ nguyên hàm của hàm số f(x) = e^(2x) là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000041', '21000000-0000-4000-8000-000000000011', 1, '(1/2)e^(2x) + C', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000042', '21000000-0000-4000-8000-000000000011', 2, '2e^(2x) + C', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000043', '21000000-0000-4000-8000-000000000011', 3, 'e^(2x) + C', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000044', '21000000-0000-4000-8000-000000000011', 4, '(1/2)e^x + C', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000012', '11000000-0000-4000-8000-000000000002', 2, 'Tích phân từ 0 đến 1 của (2x + 1)dx bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000045', '21000000-0000-4000-8000-000000000012', 1, '2', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000046', '21000000-0000-4000-8000-000000000012', 2, '1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000047', '21000000-0000-4000-8000-000000000012', 3, '3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000048', '21000000-0000-4000-8000-000000000012', 4, '1/2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000013', '11000000-0000-4000-8000-000000000002', 3, 'Trong không gian Oxyz, hình chiếu vuông góc của điểm M(2; -1; 3) lên mặt phẳng (Oxy) là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000049', '21000000-0000-4000-8000-000000000013', 1, '(2; -1; 0)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000050', '21000000-0000-4000-8000-000000000013', 2, '(0; 0; 3)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000051', '21000000-0000-4000-8000-000000000013', 3, '(2; 0; 3)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000052', '21000000-0000-4000-8000-000000000013', 4, '(0; -1; 3)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000014', '11000000-0000-4000-8000-000000000002', 4, 'Mặt cầu (S): (x - 1)² + (y + 2)² + (z - 3)² = 16 có bán kính bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000053', '21000000-0000-4000-8000-000000000014', 1, '4', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000054', '21000000-0000-4000-8000-000000000014', 2, '16', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000055', '21000000-0000-4000-8000-000000000014', 3, '8', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000056', '21000000-0000-4000-8000-000000000014', 4, '2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000015', '11000000-0000-4000-8000-000000000002', 5, 'Vectơ pháp tuyến của mặt phẳng (P): 2x - 3y + z - 5 = 0 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000057', '21000000-0000-4000-8000-000000000015', 1, '(2; -3; 1)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000058', '21000000-0000-4000-8000-000000000015', 2, '(2; 3; 1)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000059', '21000000-0000-4000-8000-000000000015', 3, '(2; -3; -5)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000060', '21000000-0000-4000-8000-000000000015', 4, '(-3; 1; -5)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000016', '11000000-0000-4000-8000-000000000002', 6, 'Nguyên hàm của hàm số f(x) = cos(2x) là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000061', '21000000-0000-4000-8000-000000000016', 1, '(1/2)sin(2x) + C', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000062', '21000000-0000-4000-8000-000000000016', 2, '-sin(2x) + C', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000063', '21000000-0000-4000-8000-000000000016', 3, '2sin(2x) + C', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000064', '21000000-0000-4000-8000-000000000016', 4, '-(1/2)sin(2x) + C', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000017', '11000000-0000-4000-8000-000000000002', 7, 'Khoảng cách từ điểm M(1; 2; -3) đến mặt phẳng (P): x + 2y - 2z + 1 = 0 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000065', '21000000-0000-4000-8000-000000000017', 1, '4', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000066', '21000000-0000-4000-8000-000000000017', 2, '12', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000067', '21000000-0000-4000-8000-000000000017', 3, '3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000068', '21000000-0000-4000-8000-000000000017', 4, '2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000018', '11000000-0000-4000-8000-000000000002', 8, 'Diện tích hình phẳng giới hạn bởi đồ thị y = x² và đường thẳng y = 2x là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000069', '21000000-0000-4000-8000-000000000018', 1, '4/3', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000070', '21000000-0000-4000-8000-000000000018', 2, '2/3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000071', '21000000-0000-4000-8000-000000000018', 3, '1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000072', '21000000-0000-4000-8000-000000000018', 4, '2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000019', '11000000-0000-4000-8000-000000000002', 9, 'Trong không gian Oxyz, phương trình mặt phẳng đi qua O và nhận n=(1;-2;3) làm VTPT là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000073', '21000000-0000-4000-8000-000000000019', 1, 'x - 2y + 3z = 0', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000074', '21000000-0000-4000-8000-000000000019', 2, 'x - 2y + 3z + 1 = 0', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000075', '21000000-0000-4000-8000-000000000019', 3, 'x + 2y + 3z = 0', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000076', '21000000-0000-4000-8000-000000000019', 4, 'x - 2y - 3z = 0', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000020', '11000000-0000-4000-8000-000000000002', 10, 'Nếu ∫[1..2] f(x)dx = 3 và ∫[1..2] g(x)dx = 2 thì ∫[1..2] [f(x) - 2g(x)]dx bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000077', '21000000-0000-4000-8000-000000000020', 1, '-1', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000078', '21000000-0000-4000-8000-000000000020', 2, '1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000079', '21000000-0000-4000-8000-000000000020', 3, '7', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000080', '21000000-0000-4000-8000-000000000020', 4, '-4', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #3: DT010103 - Toán học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000003', 'DT010103', '00000000-0000-4000-8000-000000000001', 'Toán 12 - Mũ, Logarit, Số phức & Xác suất (Đề 3)', 'Phương trình mũ - logarit, tập hợp điểm số phức và bài toán đếm xác suất.', 'Toán học', 'hard', 50, 'published', now() - interval '22 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000021', '11000000-0000-4000-8000-000000000003', 1, 'Nghiệm của phương trình log₂(x - 1) = 3 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000081', '21000000-0000-4000-8000-000000000021', 1, 'x = 9', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000082', '21000000-0000-4000-8000-000000000021', 2, 'x = 7', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000083', '21000000-0000-4000-8000-000000000021', 3, 'x = 8', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000084', '21000000-0000-4000-8000-000000000021', 4, 'x = 10', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000022', '11000000-0000-4000-8000-000000000003', 2, 'Tập nghiệm của bất phương trình 3^(x - 2) < 9 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000085', '21000000-0000-4000-8000-000000000022', 1, '(-∞; 4)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000086', '21000000-0000-4000-8000-000000000022', 2, '(4; +∞)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000087', '21000000-0000-4000-8000-000000000022', 3, '(-∞; 3)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000088', '21000000-0000-4000-8000-000000000022', 4, '(3; +∞)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000023', '11000000-0000-4000-8000-000000000003', 3, 'Số phức z = 3 - 4i có phần ảo bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000089', '21000000-0000-4000-8000-000000000023', 1, '-4', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000090', '21000000-0000-4000-8000-000000000023', 2, '4', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000091', '21000000-0000-4000-8000-000000000023', 3, '3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000092', '21000000-0000-4000-8000-000000000023', 4, '-4i', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000024', '11000000-0000-4000-8000-000000000003', 4, 'Môđun của số phức z = 1 + 2i bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000093', '21000000-0000-4000-8000-000000000024', 1, '√5', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000094', '21000000-0000-4000-8000-000000000024', 2, '5', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000095', '21000000-0000-4000-8000-000000000024', 3, '3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000096', '21000000-0000-4000-8000-000000000024', 4, '√3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000025', '11000000-0000-4000-8000-000000000003', 5, 'Số phức liên hợp của z = 2 + 5i là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000097', '21000000-0000-4000-8000-000000000025', 1, '2 - 5i', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000098', '21000000-0000-4000-8000-000000000025', 2, '-2 + 5i', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000099', '21000000-0000-4000-8000-000000000025', 3, '-2 - 5i', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000100', '21000000-0000-4000-8000-000000000025', 4, '5 + 2i', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000026', '11000000-0000-4000-8000-000000000003', 6, 'Tập xác định của hàm số y = log₃(2x - 4) là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000101', '21000000-0000-4000-8000-000000000026', 1, '(2; +∞)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000102', '21000000-0000-4000-8000-000000000026', 2, '[2; +∞)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000103', '21000000-0000-4000-8000-000000000026', 3, 'R \ {2}', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000104', '21000000-0000-4000-8000-000000000026', 4, '(-∞; 2)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000027', '11000000-0000-4000-8000-000000000003', 7, 'Gieo một con súc sắc cân đối, đồng chất. Xác suất xuất hiện mặt chấm chẵn là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000105', '21000000-0000-4000-8000-000000000027', 1, '1/2', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000106', '21000000-0000-4000-8000-000000000027', 2, '1/3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000107', '21000000-0000-4000-8000-000000000027', 3, '1/6', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000108', '21000000-0000-4000-8000-000000000027', 4, '2/3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000028', '11000000-0000-4000-8000-000000000003', 8, 'Có bao nhiêu cách chọn 3 học sinh từ một nhóm gồm 10 học sinh?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000109', '21000000-0000-4000-8000-000000000028', 1, '120', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000110', '21000000-0000-4000-8000-000000000028', 2, '720', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000111', '21000000-0000-4000-8000-000000000028', 3, '30', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000112', '21000000-0000-4000-8000-000000000028', 4, '1000', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000029', '11000000-0000-4000-8000-000000000003', 9, 'Phương trình bậc hai z² + 4 = 0 có các nghiệm trên tập số phức là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000113', '21000000-0000-4000-8000-000000000029', 1, '±2i', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000114', '21000000-0000-4000-8000-000000000029', 2, '±2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000115', '21000000-0000-4000-8000-000000000029', 3, '±4i', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000116', '21000000-0000-4000-8000-000000000029', 4, '±4', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000030', '11000000-0000-4000-8000-000000000003', 10, 'Cho hai biến cố A và B độc lập. Biết P(A) = 0.4 và P(B) = 0.5. Xác suất P(A ∩ B) bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000117', '21000000-0000-4000-8000-000000000030', 1, '0.2', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000118', '21000000-0000-4000-8000-000000000030', 2, '0.9', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000119', '21000000-0000-4000-8000-000000000030', 3, '0.1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000120', '21000000-0000-4000-8000-000000000030', 4, '0.45', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #4: DT010201 - Vật lý
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000004', 'DT010201', '00000000-0000-4000-8000-000000000002', 'Vật lý 12 - Dao động cơ & Sóng cơ học (Đề 1)', 'Các đặc trưng con lắc lò xo, con lắc đơn và hiện tượng giao thoa sóng cơ.', 'Vật lý', 'medium', 45, 'published', now() - interval '21 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000031', '11000000-0000-4000-8000-000000000004', 1, 'Một vật dao động điều hòa với phương trình x = A cos(ωt + φ). Đại lượng ω được gọi là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000121', '21000000-0000-4000-8000-000000000031', 1, 'tần số góc', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000122', '21000000-0000-4000-8000-000000000031', 2, 'pha ban đầu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000123', '21000000-0000-4000-8000-000000000031', 3, 'chu kì', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000124', '21000000-0000-4000-8000-000000000031', 4, 'biên độ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000032', '11000000-0000-4000-8000-000000000004', 2, 'Vận tốc của chất điểm dao động điều hòa đạt cực đại khi chất điểm đi qua:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000125', '21000000-0000-4000-8000-000000000032', 1, 'vị trí cân bằng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000126', '21000000-0000-4000-8000-000000000032', 2, 'vị trí biên dương', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000127', '21000000-0000-4000-8000-000000000032', 3, 'vị trí biên âm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000128', '21000000-0000-4000-8000-000000000032', 4, 'vị trí có li độ x = A/2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000033', '11000000-0000-4000-8000-000000000004', 3, 'Gia tốc trong dao động điều hòa biến thiên:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000129', '21000000-0000-4000-8000-000000000033', 1, 'ngược pha so với li độ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000130', '21000000-0000-4000-8000-000000000033', 2, 'cùng pha so với li độ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000131', '21000000-0000-4000-8000-000000000033', 3, 'sớm pha π/2 so với li độ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000132', '21000000-0000-4000-8000-000000000033', 4, 'trễ pha π/2 so với li độ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000034', '11000000-0000-4000-8000-000000000004', 4, 'Chu kì của con lắc đơn dao động điều hòa có chiều dài l tại nơi có gia tốc g là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000133', '21000000-0000-4000-8000-000000000034', 1, 'T = 2π√(l/g)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000134', '21000000-0000-4000-8000-000000000034', 2, 'T = 2π√(g/l)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000135', '21000000-0000-4000-8000-000000000034', 3, 'T = (1/2π)√(l/g)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000136', '21000000-0000-4000-8000-000000000034', 4, 'T = √(l/g)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000035', '11000000-0000-4000-8000-000000000004', 5, 'Hiện tượng cộng hưởng cơ học xảy ra khi:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000137', '21000000-0000-4000-8000-000000000035', 1, 'tần số lực cưỡng bức bằng tần số dao động riêng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000138', '21000000-0000-4000-8000-000000000035', 2, 'biên độ lực cưỡng bức đạt cực đại', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000139', '21000000-0000-4000-8000-000000000035', 3, 'ma sát môi trường rất lớn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000140', '21000000-0000-4000-8000-000000000035', 4, 'chu kì lực cưỡng bức rất lớn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000036', '11000000-0000-4000-8000-000000000004', 6, 'Khoảng cách giữa hai điểm gần nhau nhất trên cùng một phương truyền sóng dao động cùng pha là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000141', '21000000-0000-4000-8000-000000000036', 1, 'một bước sóng λ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000142', '21000000-0000-4000-8000-000000000036', 2, 'nửa bước sóng λ/2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000143', '21000000-0000-4000-8000-000000000036', 3, 'hai bước sóng 2λ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000144', '21000000-0000-4000-8000-000000000036', 4, 'một phần tư bước sóng λ/4', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000037', '11000000-0000-4000-8000-000000000004', 7, 'Sóng âm truyền nhanh nhất trong môi trường nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000145', '21000000-0000-4000-8000-000000000037', 1, 'Chất rắn', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000146', '21000000-0000-4000-8000-000000000037', 2, 'Chất lỏng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000147', '21000000-0000-4000-8000-000000000037', 3, 'Chất khí', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000148', '21000000-0000-4000-8000-000000000037', 4, 'Chân không', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000038', '11000000-0000-4000-8000-000000000004', 8, 'Trong hiện tượng giao thoa sóng cơ của hai nguồn kết hợp cùng pha, cực đại giao thoa thỏa mãn:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000149', '21000000-0000-4000-8000-000000000038', 1, 'd2 - d1 = kλ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000150', '21000000-0000-4000-8000-000000000038', 2, 'd2 - d1 = (k + 0.5)λ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000151', '21000000-0000-4000-8000-000000000038', 3, 'd2 - d1 = kλ/2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000152', '21000000-0000-4000-8000-000000000038', 4, 'd2 - d1 = 2kλ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000039', '11000000-0000-4000-8000-000000000004', 9, 'Tại điểm phản xạ trên vật cản cố định, sóng phản xạ luôn:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000153', '21000000-0000-4000-8000-000000000039', 1, 'ngược pha với sóng tới', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000154', '21000000-0000-4000-8000-000000000039', 2, 'cùng pha với sóng tới', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000155', '21000000-0000-4000-8000-000000000039', 3, 'vuông pha với sóng tới', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000156', '21000000-0000-4000-8000-000000000039', 4, 'lệch pha π/4 với sóng tới', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000040', '11000000-0000-4000-8000-000000000004', 10, 'Điều kiện có sóng dừng trên dây hai đầu cố định với chiều dài L là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000157', '21000000-0000-4000-8000-000000000040', 1, 'L = k(λ/2)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000158', '21000000-0000-4000-8000-000000000040', 2, 'L = kλ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000159', '21000000-0000-4000-8000-000000000040', 3, 'L = (2k + 1)(λ/4)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000160', '21000000-0000-4000-8000-000000000040', 4, 'L = k(λ/4)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #5: DT010202 - Vật lý
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000005', 'DT010202', '00000000-0000-4000-8000-000000000002', 'Vật lý 12 - Dòng điện xoay chiều & Mạch RLC (Đề 2)', 'Tổng trở, định luật Ôm cho đoạn mạch RLC, cộng hưởng và máy biến áp.', 'Vật lý', 'medium', 45, 'published', now() - interval '20 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000041', '11000000-0000-4000-8000-000000000005', 1, 'Cường độ dòng điện hiệu dụng I liên hệ với cường độ cực đại I₀ theo công thức:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000161', '21000000-0000-4000-8000-000000000041', 1, 'I = I₀ / √2', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000162', '21000000-0000-4000-8000-000000000041', 2, 'I = I₀ √2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000163', '21000000-0000-4000-8000-000000000041', 3, 'I = 2I₀', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000164', '21000000-0000-4000-8000-000000000041', 4, 'I = I₀ / 2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000042', '11000000-0000-4000-8000-000000000005', 2, 'Đoạn mạch chỉ có điện trở thuần R thì điện áp hai đầu đoạn mạch:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000165', '21000000-0000-4000-8000-000000000042', 1, 'cùng pha với cường độ dòng điện', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000166', '21000000-0000-4000-8000-000000000042', 2, 'sớm pha π/2 so với dòng điện', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000167', '21000000-0000-4000-8000-000000000042', 3, 'trễ pha π/2 so với dòng điện', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000168', '21000000-0000-4000-8000-000000000042', 4, 'ngược pha với dòng điện', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000043', '11000000-0000-4000-8000-000000000005', 3, 'Cảm kháng của cuộn cảm thuần có độ tự cảm L đối với dòng điện tần số góc ω là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000169', '21000000-0000-4000-8000-000000000043', 1, 'Z_L = ωL', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000170', '21000000-0000-4000-8000-000000000043', 2, 'Z_L = 1/(ωL)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000171', '21000000-0000-4000-8000-000000000043', 3, 'Z_L = √(ωL)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000172', '21000000-0000-4000-8000-000000000043', 4, 'Z_L = ω/L', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000044', '11000000-0000-4000-8000-000000000005', 4, 'Dung kháng của tụ điện có điện dung C đối với dòng điện xoay chiều tần số góc ω là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000173', '21000000-0000-4000-8000-000000000044', 1, 'Z_C = 1/(ωC)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000174', '21000000-0000-4000-8000-000000000044', 2, 'Z_C = ωC', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000175', '21000000-0000-4000-8000-000000000044', 3, 'Z_C = √(ωC)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000176', '21000000-0000-4000-8000-000000000044', 4, 'Z_C = C/ω', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000045', '11000000-0000-4000-8000-000000000005', 5, 'Hiện tượng cộng hưởng điện trong mạch RLC nối tiếp xảy ra khi:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000177', '21000000-0000-4000-8000-000000000045', 1, 'ωL = 1/(ωC)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000178', '21000000-0000-4000-8000-000000000045', 2, 'ωL = ωC', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000179', '21000000-0000-4000-8000-000000000045', 3, 'R = ωL', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000180', '21000000-0000-4000-8000-000000000045', 4, 'R = 1/(ωC)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000046', '11000000-0000-4000-8000-000000000005', 6, 'Khi xảy ra hiện tượng cộng hưởng trong đoạn mạch RLC nối tiếp thì:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000181', '21000000-0000-4000-8000-000000000046', 1, 'hệ số công suất cosφ = 1', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000182', '21000000-0000-4000-8000-000000000046', 2, 'tổng trở Z đạt cực đại', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000183', '21000000-0000-4000-8000-000000000046', 3, 'cường độ dòng điện đạt cực tiểu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000184', '21000000-0000-4000-8000-000000000046', 4, 'điện áp hai đầu mạch trễ pha π/2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000047', '11000000-0000-4000-8000-000000000005', 7, 'Hệ số công suất của đoạn mạch RLC nối tiếp được tính bằng công thức:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000185', '21000000-0000-4000-8000-000000000047', 1, 'cosφ = R / Z', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000186', '21000000-0000-4000-8000-000000000047', 2, 'cosφ = Z / R', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000187', '21000000-0000-4000-8000-000000000047', 3, 'cosφ = (Z_L - Z_C) / R', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000188', '21000000-0000-4000-8000-000000000047', 4, 'cosφ = R / (Z_L - Z_C)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000048', '11000000-0000-4000-8000-000000000005', 8, 'Máy biến áp là thiết bị dùng để biến đổi:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000189', '21000000-0000-4000-8000-000000000048', 1, 'điện áp xoay chiều mà không đổi tần số', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000190', '21000000-0000-4000-8000-000000000048', 2, 'điện áp và tần số dòng xoay chiều', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000191', '21000000-0000-4000-8000-000000000048', 3, 'dòng điện xoay chiều thành một chiều', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000192', '21000000-0000-4000-8000-000000000048', 4, 'công suất dòng điện xoay chiều', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000049', '11000000-0000-4000-8000-000000000005', 9, 'Công suất tiêu thụ trong đoạn mạch xoay chiều được tính bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000193', '21000000-0000-4000-8000-000000000049', 1, 'P = U I cosφ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000194', '21000000-0000-4000-8000-000000000049', 2, 'P = U I sinφ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000195', '21000000-0000-4000-8000-000000000049', 3, 'P = U I', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000196', '21000000-0000-4000-8000-000000000049', 4, 'P = U² / R', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000050', '11000000-0000-4000-8000-000000000005', 10, 'Nguyên tắc hoạt động của máy phát điện xoay chiều dựa trên hiện tượng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000197', '21000000-0000-4000-8000-000000000050', 1, 'cảm ứng điện từ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000198', '21000000-0000-4000-8000-000000000050', 2, 'tự cảm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000199', '21000000-0000-4000-8000-000000000050', 3, 'quang điện', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000200', '21000000-0000-4000-8000-000000000050', 4, 'từ trường quay', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #6: DT010203 - Vật lý
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000006', 'DT010203', '00000000-0000-4000-8000-000000000002', 'Vật lý 12 - Sóng ánh sáng, Lượng tử & Hạt nhân (Đề 3)', 'Tán sắc, giao thoa ánh sáng, hiệu ứng quang điện và phản ứng hạt nhân.', 'Vật lý', 'hard', 50, 'published', now() - interval '19 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000051', '11000000-0000-4000-8000-000000000006', 1, 'Hiện tượng tán sắc ánh sáng xảy ra do chiết suất của môi trường:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000201', '21000000-0000-4000-8000-000000000051', 1, 'phụ thuộc vào màu sắc (bước sóng) ánh sáng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000202', '21000000-0000-4000-8000-000000000051', 2, 'luôn không đổi với mọi ánh sáng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000203', '21000000-0000-4000-8000-000000000051', 3, 'chỉ phụ thuộc vào góc tới', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000204', '21000000-0000-4000-8000-000000000051', 4, 'bằng 1 với mọi ánh sáng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000052', '11000000-0000-4000-8000-000000000006', 2, 'Trong thí nghiệm giao thoa Young, khoảng vân i được tính bằng công thức:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000205', '21000000-0000-4000-8000-000000000052', 1, 'i = λD / a', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000206', '21000000-0000-4000-8000-000000000052', 2, 'i = λa / D', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000207', '21000000-0000-4000-8000-000000000052', 3, 'i = aD / λ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000208', '21000000-0000-4000-8000-000000000052', 4, 'i = λ / (aD)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000053', '11000000-0000-4000-8000-000000000006', 3, 'Ánh sáng đơn sắc nào sau đây có bước sóng lớn nhất trong chân không?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000209', '21000000-0000-4000-8000-000000000053', 1, 'Ánh sáng đỏ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000210', '21000000-0000-4000-8000-000000000053', 2, 'Ánh sáng vàng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000211', '21000000-0000-4000-8000-000000000053', 3, 'Ánh sáng lam', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000212', '21000000-0000-4000-8000-000000000053', 4, 'Ánh sáng tím', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000054', '11000000-0000-4000-8000-000000000006', 4, 'Tia Rơnghen (tia X) có cùng bản chất với:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000213', '21000000-0000-4000-8000-000000000054', 1, 'sóng vô tuyến', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000214', '21000000-0000-4000-8000-000000000054', 2, 'tia anpha', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000215', '21000000-0000-4000-8000-000000000054', 3, 'tia bêta', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000216', '21000000-0000-4000-8000-000000000054', 4, 'dòng electron', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000055', '11000000-0000-4000-8000-000000000006', 5, 'Theo thuyết lượng tử ánh sáng, mỗi photon mang năng lượng bằng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000217', '21000000-0000-4000-8000-000000000055', 1, 'ε = hf', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000218', '21000000-0000-4000-8000-000000000055', 2, 'ε = h / f', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000219', '21000000-0000-4000-8000-000000000055', 3, 'ε = h c', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000220', '21000000-0000-4000-8000-000000000055', 4, 'ε = h λ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000056', '11000000-0000-4000-8000-000000000006', 6, 'Điều kiện xảy ra hiện tượng quang điện ngoài đối với một kim loại là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000221', '21000000-0000-4000-8000-000000000056', 1, 'λ ≤ λ₀', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000222', '21000000-0000-4000-8000-000000000056', 2, 'λ ≥ λ₀', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000223', '21000000-0000-4000-8000-000000000056', 3, 'λ > λ₀', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000224', '21000000-0000-4000-8000-000000000056', 4, 'f < f₀', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000057', '11000000-0000-4000-8000-000000000006', 7, 'Hạt nhân nguyên tử được cấu tạo từ các hạt nào sau đây?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000225', '21000000-0000-4000-8000-000000000057', 1, 'Proton và nơtron', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000226', '21000000-0000-4000-8000-000000000057', 2, 'Proton và electron', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000227', '21000000-0000-4000-8000-000000000057', 3, 'Electron và nơtron', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000228', '21000000-0000-4000-8000-000000000057', 4, 'Chỉ gồm proton', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000058', '11000000-0000-4000-8000-000000000006', 8, 'Số khối A của một hạt nhân nguyên tử là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000229', '21000000-0000-4000-8000-000000000058', 1, 'tổng số proton và nơtron', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000230', '21000000-0000-4000-8000-000000000058', 2, 'số nơtron', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000231', '21000000-0000-4000-8000-000000000058', 3, 'số proton', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000232', '21000000-0000-4000-8000-000000000058', 4, 'số electron', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000059', '11000000-0000-4000-8000-000000000006', 9, 'Hạt nhân bền vững nhất khi có đại lượng nào sau đây lớn nhất?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000233', '21000000-0000-4000-8000-000000000059', 1, 'Năng lượng liên kết riêng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000234', '21000000-0000-4000-8000-000000000059', 2, 'Năng lượng liên kết', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000235', '21000000-0000-4000-8000-000000000059', 3, 'Số khối A', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000236', '21000000-0000-4000-8000-000000000059', 4, 'Độ hụt khối', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000060', '11000000-0000-4000-8000-000000000006', 10, 'Chu kì bán rã T là khoảng thời gian sau đó số hạt nhân phóng xạ còn lại:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000237', '21000000-0000-4000-8000-000000000060', 1, '50% so với ban đầu', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000238', '21000000-0000-4000-8000-000000000060', 2, '25% so với ban đầu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000239', '21000000-0000-4000-8000-000000000060', 3, '75% so với ban đầu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000240', '21000000-0000-4000-8000-000000000060', 4, '0%', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #7: DT010301 - Hóa học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000007', 'DT010301', '00000000-0000-4000-8000-000000000004', 'Hóa học 12 - Este, Lipit & Cacbohiđrat (Đề 1)', 'Tính chất Este, chất béo, monosaccarit, đisaccarit và polisaccarit.', 'Hóa học', 'medium', 45, 'published', now() - interval '18 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000061', '11000000-0000-4000-8000-000000000007', 1, 'Công thức phân tử tổng quát của este no, đơn chức, mạch hở là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000241', '21000000-0000-4000-8000-000000000061', 1, 'CnH2nO2 (n ≥ 2)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000242', '21000000-0000-4000-8000-000000000061', 2, 'CnH2nO (n ≥ 1)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000243', '21000000-0000-4000-8000-000000000061', 3, 'CnH2n-2O2 (n ≥ 3)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000244', '21000000-0000-4000-8000-000000000061', 4, 'CnH2n+2O2 (n ≥ 2)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000062', '11000000-0000-4000-8000-000000000007', 2, 'Este etyl axetat có mùi thơm quả chín đặc trưng. Công thức phân tử của etyl axetat là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000245', '21000000-0000-4000-8000-000000000062', 1, 'CH3COOC2H5', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000246', '21000000-0000-4000-8000-000000000062', 2, 'HCOOCH3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000247', '21000000-0000-4000-8000-000000000062', 3, 'C2H5COOCH3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000248', '21000000-0000-4000-8000-000000000062', 4, 'CH3COOCH3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000063', '11000000-0000-4000-8000-000000000007', 3, 'Thủy phân hoàn toàn chất béo (triglyxerit) trong môi trường kiềm luôn thu được:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000249', '21000000-0000-4000-8000-000000000063', 1, 'glixerol và xà phòng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000250', '21000000-0000-4000-8000-000000000063', 2, 'ancol etylic và axit béo', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000251', '21000000-0000-4000-8000-000000000063', 3, 'etylen glycol và muối', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000252', '21000000-0000-4000-8000-000000000063', 4, 'glixerol và anđehit', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000064', '11000000-0000-4000-8000-000000000007', 4, 'Chất nào sau đây thuộc loại đisaccarit?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000253', '21000000-0000-4000-8000-000000000064', 1, 'Saccarozơ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000254', '21000000-0000-4000-8000-000000000064', 2, 'Glucozơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000255', '21000000-0000-4000-8000-000000000064', 3, 'Fructozơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000256', '21000000-0000-4000-8000-000000000064', 4, 'Tinh bột', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000065', '11000000-0000-4000-8000-000000000007', 5, 'Chất nào sau đây tác dụng với dung dịch AgNO3 trong NH3 sinh ra kết tủa bạc sáng bóng?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000257', '21000000-0000-4000-8000-000000000065', 1, 'Glucozơ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000258', '21000000-0000-4000-8000-000000000065', 2, 'Saccarozơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000259', '21000000-0000-4000-8000-000000000065', 3, 'Xenlulozơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000260', '21000000-0000-4000-8000-000000000065', 4, 'Tinh bột', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000066', '11000000-0000-4000-8000-000000000007', 6, 'Thuốc thử dùng để nhận biết tinh bột bằng phản ứng tạo màu xanh tím là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000261', '21000000-0000-4000-8000-000000000066', 1, 'Dung dịch iot', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000262', '21000000-0000-4000-8000-000000000066', 2, 'Dung dịch Cu(OH)2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000263', '21000000-0000-4000-8000-000000000066', 3, 'Dung dịch AgNO3/NH3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000264', '21000000-0000-4000-8000-000000000066', 4, 'Quỳ tím', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000067', '11000000-0000-4000-8000-000000000007', 7, 'Thủy phân este CH3COOCH3 trong dung dịch NaOH đun nóng tạo ra sản phẩm gồm:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000265', '21000000-0000-4000-8000-000000000067', 1, 'CH3COONa và CH3OH', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000266', '21000000-0000-4000-8000-000000000067', 2, 'HCOONa và C2H5OH', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000267', '21000000-0000-4000-8000-000000000067', 3, 'CH3COOH và CH3ONa', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000268', '21000000-0000-4000-8000-000000000067', 4, 'C2H5COONa và H2O', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000068', '11000000-0000-4000-8000-000000000007', 8, 'Chất nào sau đây không tan trong nước lạnh nhưng tan trong nước nóng tạo hồ tinh bột?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000269', '21000000-0000-4000-8000-000000000068', 1, 'Tinh bột', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000270', '21000000-0000-4000-8000-000000000068', 2, 'Glucozơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000271', '21000000-0000-4000-8000-000000000068', 3, 'Saccarozơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000272', '21000000-0000-4000-8000-000000000068', 4, 'Fructozơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000069', '11000000-0000-4000-8000-000000000007', 9, 'Chất béo lỏng (dầu thực vật) chuyển hóa thành chất béo rắn (bơ nhân tạo) nhờ phản ứng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000273', '21000000-0000-4000-8000-000000000069', 1, 'Hiđro hóa', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000274', '21000000-0000-4000-8000-000000000069', 2, 'Xà phòng hóa', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000275', '21000000-0000-4000-8000-000000000069', 3, 'Thủy phân', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000276', '21000000-0000-4000-8000-000000000069', 4, 'Trùng hợp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000070', '11000000-0000-4000-8000-000000000007', 10, 'Thành phần chính tạo nên màng tế bào thực vật và có nhiều trong bông nõn là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000277', '21000000-0000-4000-8000-000000000070', 1, 'Xenlulozơ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000278', '21000000-0000-4000-8000-000000000070', 2, 'Tinh bột', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000279', '21000000-0000-4000-8000-000000000070', 3, 'Saccarozơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000280', '21000000-0000-4000-8000-000000000070', 4, 'Protein', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #8: DT010302 - Hóa học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000008', 'DT010302', '00000000-0000-4000-8000-000000000004', 'Hóa học 12 - Kim loại kiềm, kiềm thổ & Nhôm (Đề 2)', 'Vị trí trong bảng tuần hoàn, tính khử mạnh, hợp chất Al2O3, Al(OH)3 và nước cứng.', 'Hóa học', 'medium', 45, 'published', now() - interval '17 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000071', '11000000-0000-4000-8000-000000000008', 1, 'Kim loại nào sau đây thuộc nhóm kim loại kiềm (nhóm IA)?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000281', '21000000-0000-4000-8000-000000000071', 1, 'Natri (Na)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000282', '21000000-0000-4000-8000-000000000071', 2, 'Canxi (Ca)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000283', '21000000-0000-4000-8000-000000000071', 3, 'Nhôm (Al)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000284', '21000000-0000-4000-8000-000000000071', 4, 'Đồng (Cu)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000072', '11000000-0000-4000-8000-000000000008', 2, 'Kim loại kiềm mềm, dẫn điện tốt và có khối lượng riêng nhỏ. Trong tự nhiên chúng tồn tại dưới dạng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000285', '21000000-0000-4000-8000-000000000072', 1, 'Hợp chất', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000286', '21000000-0000-4000-8000-000000000072', 2, 'Đơn chất tự do', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000287', '21000000-0000-4000-8000-000000000072', 3, 'Khí', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000288', '21000000-0000-4000-8000-000000000072', 4, 'Quặng kim loại tự do', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000073', '11000000-0000-4000-8000-000000000008', 3, 'Để bảo quản kim loại natri trong phòng thí nghiệm, người ta ngâm chìm nó trong:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000289', '21000000-0000-4000-8000-000000000073', 1, 'Dầu hỏa', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000290', '21000000-0000-4000-8000-000000000073', 2, 'Nước cất', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000291', '21000000-0000-4000-8000-000000000073', 3, 'Cồn 90 độ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000292', '21000000-0000-4000-8000-000000000073', 4, 'Dung dịch axit HCl', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000074', '11000000-0000-4000-8000-000000000008', 4, 'Kim loại kiềm thổ có cấu hình electron lớp ngoài cùng là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000293', '21000000-0000-4000-8000-000000000074', 1, 'ns²', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000294', '21000000-0000-4000-8000-000000000074', 2, 'ns¹', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000295', '21000000-0000-4000-8000-000000000074', 3, 'ns²np¹', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000296', '21000000-0000-4000-8000-000000000074', 4, 'ns²np²', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000075', '11000000-0000-4000-8000-000000000008', 5, 'Hợp chất Al(OH)3 có tính chất hóa học nổi bật là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000297', '21000000-0000-4000-8000-000000000075', 1, 'Tính lưỡng tính', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000298', '21000000-0000-4000-8000-000000000075', 2, 'Chỉ có tính bazơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000299', '21000000-0000-4000-8000-000000000075', 3, 'Chỉ có tính axit', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000300', '21000000-0000-4000-8000-000000000075', 4, 'Tính khử mạnh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000076', '11000000-0000-4000-8000-000000000008', 6, 'Nước cứng là nước có chứa nhiều ion nào sau đây?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000301', '21000000-0000-4000-8000-000000000076', 1, 'Ca²⁺ và Mg²⁺', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000302', '21000000-0000-4000-8000-000000000076', 2, 'Na⁺ và K⁺', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000303', '21000000-0000-4000-8000-000000000076', 3, 'Fe²⁺ và Cu²⁺', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000304', '21000000-0000-4000-8000-000000000076', 4, 'Al³⁺ và H⁺', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000077', '11000000-0000-4000-8000-000000000008', 7, 'Kim loại nhôm bị thụ động hóa (không tan) trong dung dịch axit nào đặc, nguội?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000305', '21000000-0000-4000-8000-000000000077', 1, 'HNO3 đặc, nguội', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000306', '21000000-0000-4000-8000-000000000077', 2, 'HCl loãng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000307', '21000000-0000-4000-8000-000000000077', 3, 'H2SO4 loãng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000308', '21000000-0000-4000-8000-000000000077', 4, 'CH3COOH', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000078', '11000000-0000-4000-8000-000000000008', 8, 'Quặng bôxit là nguyên liệu chính để sản xuất nhôm trong công nghiệp có thành phần chủ yếu là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000309', '21000000-0000-4000-8000-000000000078', 1, 'Al2O3.2H2O', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000310', '21000000-0000-4000-8000-000000000078', 2, 'Fe2O3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000311', '21000000-0000-4000-8000-000000000078', 3, 'CaCO3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000312', '21000000-0000-4000-8000-000000000078', 4, 'CuFeS2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000079', '11000000-0000-4000-8000-000000000008', 9, 'Hiện tượng xảy ra khi sục khí CO2 từ từ đến dư vào dung dịch Ca(OH)2 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000313', '21000000-0000-4000-8000-000000000079', 1, 'Xuất hiện kết tủa trắng, sau đó kết tủa tan dần', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000314', '21000000-0000-4000-8000-000000000079', 2, 'Không có hiện tượng gì', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000315', '21000000-0000-4000-8000-000000000079', 3, 'Chỉ xuất hiện kết tủa và không tan', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000316', '21000000-0000-4000-8000-000000000079', 4, 'Dung dịch chuyển sang màu hồng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000080', '11000000-0000-4000-8000-000000000008', 10, 'Để làm mềm nước cứng tạm thời, phương pháp đơn giản nhất là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000317', '21000000-0000-4000-8000-000000000080', 1, 'Đun sôi nước', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000318', '21000000-0000-4000-8000-000000000080', 2, 'Thêm axit HCl', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000319', '21000000-0000-4000-8000-000000000080', 3, 'Thêm dung dịch NaCl', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000320', '21000000-0000-4000-8000-000000000080', 4, 'Lọc qua than hoạt tính', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #9: DT010303 - Hóa học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000009', 'DT010303', '00000000-0000-4000-8000-000000000004', 'Hóa học 12 - Tổng hợp Hóa học Vô cơ & Hữu cơ (Đề 3)', 'Polime, amin, amino axit, protein, sắt, crom và nhận biết hóa chất.', 'Hóa học', 'hard', 50, 'published', now() - interval '16 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000081', '11000000-0000-4000-8000-000000000009', 1, 'Chất nào sau đây là amin bậc một?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000321', '21000000-0000-4000-8000-000000000081', 1, 'CH3NH2', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000322', '21000000-0000-4000-8000-000000000081', 2, '(CH3)2NH', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000323', '21000000-0000-4000-8000-000000000081', 3, '(CH3)3N', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000324', '21000000-0000-4000-8000-000000000081', 4, 'CH3NHCH2CH3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000082', '11000000-0000-4000-8000-000000000009', 2, 'Dung dịch anilin trong nước không làm đổi màu quỳ tím do anilin có:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000325', '21000000-0000-4000-8000-000000000082', 1, 'Tính bazơ rất yếu', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000326', '21000000-0000-4000-8000-000000000082', 2, 'Tính axit mạnh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000327', '21000000-0000-4000-8000-000000000082', 3, 'Tính lưỡng tính', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000328', '21000000-0000-4000-8000-000000000082', 4, 'Tính oxi hóa mạnh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000083', '11000000-0000-4000-8000-000000000009', 3, 'Amino axit là hợp chất hữu cơ tạp chức có chứa đồng thời hai nhóm chức là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000329', '21000000-0000-4000-8000-000000000083', 1, '-NH2 và -COOH', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000330', '21000000-0000-4000-8000-000000000083', 2, '-OH và -CHO', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000331', '21000000-0000-4000-8000-000000000083', 3, '-NH2 và -OH', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000332', '21000000-0000-4000-8000-000000000083', 4, '-COOH và -CHO', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000084', '11000000-0000-4000-8000-000000000009', 4, 'Chất nào sau đây là amino axit đơn giản nhất?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000333', '21000000-0000-4000-8000-000000000084', 1, 'Glyxin', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000334', '21000000-0000-4000-8000-000000000084', 2, 'Alanin', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000335', '21000000-0000-4000-8000-000000000084', 3, 'Valin', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000336', '21000000-0000-4000-8000-000000000084', 4, 'Axit glutamic', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000085', '11000000-0000-4000-8000-000000000009', 5, 'Polime nào sau đây được điều chế bằng phản ứng trùng ngưng?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000337', '21000000-0000-4000-8000-000000000085', 1, 'Nilon-6,6', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000338', '21000000-0000-4000-8000-000000000085', 2, 'Polietilen (PE)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000339', '21000000-0000-4000-8000-000000000085', 3, 'Poli(vinyl clorua) (PVC)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000340', '21000000-0000-4000-8000-000000000085', 4, 'Cao su buna', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000086', '11000000-0000-4000-8000-000000000009', 6, 'Kim loại nào sau đây có độ cứng lớn nhất trong tất cả các kim loại?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000341', '21000000-0000-4000-8000-000000000086', 1, 'Crom (Cr)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000342', '21000000-0000-4000-8000-000000000086', 2, 'Kim cương', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000343', '21000000-0000-4000-8000-000000000086', 3, 'Sắt (Fe)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000344', '21000000-0000-4000-8000-000000000086', 4, 'Vonfram (W)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000087', '11000000-0000-4000-8000-000000000009', 7, 'Quặng manhetit có thành phần chính là oxit sắt nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000345', '21000000-0000-4000-8000-000000000087', 1, 'Fe3O4', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000346', '21000000-0000-4000-8000-000000000087', 2, 'Fe2O3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000347', '21000000-0000-4000-8000-000000000087', 3, 'FeO', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000348', '21000000-0000-4000-8000-000000000087', 4, 'FeCO3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000088', '11000000-0000-4000-8000-000000000009', 8, 'Để nhận biết ion Fe³⁺ trong dung dịch, thuốc thử thuận tiện nhất là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000349', '21000000-0000-4000-8000-000000000088', 1, 'Dung dịch kiềm NaOH', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000350', '21000000-0000-4000-8000-000000000088', 2, 'Khí CO2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000351', '21000000-0000-4000-8000-000000000088', 3, 'Dung dịch BaCl2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000352', '21000000-0000-4000-8000-000000000088', 4, 'Dung dịch NaNO3', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000089', '11000000-0000-4000-8000-000000000009', 9, 'Hợp chất Fe(OH)2 có màu gì khi mới kết tủa?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000353', '21000000-0000-4000-8000-000000000089', 1, 'Trắng xanh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000354', '21000000-0000-4000-8000-000000000089', 2, 'Nâu đỏ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000355', '21000000-0000-4000-8000-000000000089', 3, 'Vàng nhạt', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000356', '21000000-0000-4000-8000-000000000089', 4, 'Đen', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000090', '11000000-0000-4000-8000-000000000009', 10, 'Ăn mòn điện hóa học phát sinh dòng điện khi có hai điện cực khác chất tiếp xúc với:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000357', '21000000-0000-4000-8000-000000000090', 1, 'Dung dịch chất điện li', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000358', '21000000-0000-4000-8000-000000000090', 2, 'Khí trơ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000359', '21000000-0000-4000-8000-000000000090', 3, 'Chân không', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000360', '21000000-0000-4000-8000-000000000090', 4, 'Dầu nhờn cách điện', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #10: DT010401 - Sinh học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000010', 'DT010401', '00000000-0000-4000-8000-000000000005', 'Sinh học 12 - Cơ chế di truyền & Biến dị cấp phân tử (Đề 1)', 'Cấu trúc ADN, ARN, quá trình nhân đôi, phiên mã, dịch mã và đột biến gen.', 'Sinh học', 'medium', 45, 'published', now() - interval '15 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000091', '11000000-0000-4000-8000-000000000010', 1, 'Đơn phân cấu tạo nên phân tử ADN là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000361', '21000000-0000-4000-8000-000000000091', 1, 'Nuclêôtit (A, T, G, X)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000362', '21000000-0000-4000-8000-000000000091', 2, 'Axit amin', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000363', '21000000-0000-4000-8000-000000000091', 3, 'Axit béo', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000364', '21000000-0000-4000-8000-000000000091', 4, 'Monosaccarit', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000092', '11000000-0000-4000-8000-000000000010', 2, 'Trong quá trình nhân đôi ADN, enzim nào đóng vai trò chính tổng hợp mạch mới?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000365', '21000000-0000-4000-8000-000000000092', 1, 'ADN polimeraza', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000366', '21000000-0000-4000-8000-000000000092', 2, 'ARN polimeraza', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000367', '21000000-0000-4000-8000-000000000092', 3, 'Ligaza', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000368', '21000000-0000-4000-8000-000000000092', 4, 'Helicaza', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000093', '11000000-0000-4000-8000-000000000010', 3, 'Bộ ba mở đầu trên phân tử mARN quy định axit amin Metionin ở sinh vật nhân thực là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000369', '21000000-0000-4000-8000-000000000093', 1, '5''AUG3''', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000370', '21000000-0000-4000-8000-000000000093', 2, '5''UAA3''', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000371', '21000000-0000-4000-8000-000000000093', 3, '5''UAG3''', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000372', '21000000-0000-4000-8000-000000000093', 4, '5''UGA3''', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000094', '11000000-0000-4000-8000-000000000010', 4, 'Quá trình tổng hợp phân tử mARN dựa trên khuôn mẫu ADN được gọi là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000373', '21000000-0000-4000-8000-000000000094', 1, 'Phiên mã', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000374', '21000000-0000-4000-8000-000000000094', 2, 'Dịch mã', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000375', '21000000-0000-4000-8000-000000000094', 3, 'Nhân đôi', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000376', '21000000-0000-4000-8000-000000000094', 4, 'Tự sao', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000095', '11000000-0000-4000-8000-000000000010', 5, 'Quá trình dịch mã (tổng hợp chuỗi polipeptit) diễn ra ở bào quan nào trong tế bào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000377', '21000000-0000-4000-8000-000000000095', 1, 'Ribôxôm', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000378', '21000000-0000-4000-8000-000000000095', 2, 'Nhân tế bào', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000379', '21000000-0000-4000-8000-000000000095', 3, 'Ti thể', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000380', '21000000-0000-4000-8000-000000000095', 4, 'Không bào', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000096', '11000000-0000-4000-8000-000000000010', 6, 'Dạng đột biến điểm nào sau đây làm thay đổi nhiều axit amin nhất trong chuỗi polipeptit?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000381', '21000000-0000-4000-8000-000000000096', 1, 'Mất hoặc thêm 1 cặp nuclêôtit', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000382', '21000000-0000-4000-8000-000000000096', 2, 'Thay thế 1 cặp nuclêôtit cùng loại', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000383', '21000000-0000-4000-8000-000000000096', 3, 'Đảo vị trí 2 nuclêôtit', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000384', '21000000-0000-4000-8000-000000000096', 4, 'Thay thế 1 cặp A-T bằng T-A', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000097', '11000000-0000-4000-8000-000000000010', 7, 'Mã di truyền có tính thoái hóa nghĩa là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000385', '21000000-0000-4000-8000-000000000097', 1, 'Nhiều bộ ba khác nhau cùng mã hóa cho một axit amin', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000386', '21000000-0000-4000-8000-000000000097', 2, 'Một bộ ba mã hóa cho nhiều axit amin', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000387', '21000000-0000-4000-8000-000000000097', 3, 'Mọi loài đều dùng chung một bộ mã di truyền', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000388', '21000000-0000-4000-8000-000000000097', 4, 'Bộ ba được đọc liên tục không gối lên nhau', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000098', '11000000-0000-4000-8000-000000000010', 8, 'Một phân tử tARN có bộ ba đối mã (anticodon) là 3''UAX5'' sẽ khớp với codon nào trên mARN?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000389', '21000000-0000-4000-8000-000000000098', 1, '5''AUG3''', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000390', '21000000-0000-4000-8000-000000000098', 2, '5''AUG5''', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000391', '21000000-0000-4000-8000-000000000098', 3, '3''AUG5''', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000392', '21000000-0000-4000-8000-000000000098', 4, '5''UAG3''', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000099', '11000000-0000-4000-8000-000000000010', 9, 'Đơn vị cấu trúc cơ bản của nhiễm sắc thể ở sinh vật nhân thực là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000393', '21000000-0000-4000-8000-000000000099', 1, 'Nuclêôxôm', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000394', '21000000-0000-4000-8000-000000000099', 2, 'Crômatit', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000395', '21000000-0000-4000-8000-000000000099', 3, 'Centromere', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000396', '21000000-0000-4000-8000-000000000099', 4, 'Gen', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000100', '11000000-0000-4000-8000-000000000010', 10, 'Đột biến mất đoạn nhiễm sắc thể thường gây hậu quả gì đối với sinh vật?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000397', '21000000-0000-4000-8000-000000000100', 1, 'Làm giảm sức sống hoặc gây chết', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000398', '21000000-0000-4000-8000-000000000100', 2, 'Làm tăng cường biểu hiện tính trạng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000399', '21000000-0000-4000-8000-000000000100', 3, 'Không gây ảnh hưởng gì', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000400', '21000000-0000-4000-8000-000000000100', 4, 'Tạo ra loài mới ngay lập tức', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #11: DT010402 - Sinh học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000011', 'DT010402', '00000000-0000-4000-8000-000000000005', 'Sinh học 12 - Quy luật di truyền & Di truyền học người (Đề 2)', 'Các quy luật Mendel, tương tác gen, liên kết hoán vị gen và bệnh tật di truyền.', 'Sinh học', 'medium', 45, 'published', now() - interval '14 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000101', '11000000-0000-4000-8000-000000000011', 1, 'Theo quy luật phân ly của Mendel, phép lai Aa x Aa cho tỉ lệ phân ly kiểu hình ở F1 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000401', '21000000-0000-4000-8000-000000000101', 1, '3 trội : 1 lặn', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000402', '21000000-0000-4000-8000-000000000101', 2, '1 trội : 1 lặn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000403', '21000000-0000-4000-8000-000000000101', 3, '100% trội', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000404', '21000000-0000-4000-8000-000000000101', 4, '1 trội : 2 trung gian : 1 lặn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000102', '11000000-0000-4000-8000-000000000011', 2, 'Cơ thể có kiểu gen AaBb giảm phân bình thường tạo ra tối đa bao nhiêu loại giao tử?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000405', '21000000-0000-4000-8000-000000000102', 1, '4 loại', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000406', '21000000-0000-4000-8000-000000000102', 2, '2 loại', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000407', '21000000-0000-4000-8000-000000000102', 3, '8 loại', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000408', '21000000-0000-4000-8000-000000000102', 4, '1 loại', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000103', '11000000-0000-4000-8000-000000000011', 3, 'Phép lai phân tích là phép lai giữa cá thể mang kiểu hình trội với cá thể mang kiểu gen:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000409', '21000000-0000-4000-8000-000000000103', 1, 'Đồng hợp lặn', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000410', '21000000-0000-4000-8000-000000000103', 2, 'Đồng hợp trội', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000411', '21000000-0000-4000-8000-000000000103', 3, 'Dị hợp tử', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000412', '21000000-0000-4000-8000-000000000103', 4, 'Bất kỳ kiểu gen nào', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000104', '11000000-0000-4000-8000-000000000011', 4, 'Hiện tượng hoán vị gen xảy ra do sự trao đổi chéo giữa các crômatit tại kỳ nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000413', '21000000-0000-4000-8000-000000000104', 1, 'Kỳ đầu của giảm phân I', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000414', '21000000-0000-4000-8000-000000000104', 2, 'Kỳ giữa của giảm phân I', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000415', '21000000-0000-4000-8000-000000000104', 3, 'Kỳ đầu của giảm phân II', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000416', '21000000-0000-4000-8000-000000000104', 4, 'Kỳ sau của nguyên phân', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000105', '11000000-0000-4000-8000-000000000011', 5, 'Tần số hoán vị gen (f) không vượt quá giá trị nào sau đây?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000417', '21000000-0000-4000-8000-000000000105', 1, '50%', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000418', '21000000-0000-4000-8000-000000000105', 2, '100%', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000419', '21000000-0000-4000-8000-000000000105', 3, '25%', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000420', '21000000-0000-4000-8000-000000000105', 4, '75%', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000106', '11000000-0000-4000-8000-000000000011', 6, 'Bệnh mù màu và bệnh máu khó đông ở người do gen lặn nằm trên nhiễm sắc thể nào quy định?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000421', '21000000-0000-4000-8000-000000000106', 1, 'Nhiễm sắc thể giới tính X (không có alen trên Y)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000422', '21000000-0000-4000-8000-000000000106', 2, 'Nhiễm sắc thể thường', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000423', '21000000-0000-4000-8000-000000000106', 3, 'Nhiễm sắc thể giới tính Y', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000424', '21000000-0000-4000-8000-000000000106', 4, 'Gen trong ti thể', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000107', '11000000-0000-4000-8000-000000000011', 7, 'Hội chứng Đao ở người là dạng đột biến số lượng nhiễm sắc thể nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000425', '21000000-0000-4000-8000-000000000107', 1, 'Thừa 1 nhiễm sắc thể ở cặp số 21 (Thể ba 2n+1)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000426', '21000000-0000-4000-8000-000000000107', 2, 'Mất 1 nhiễm sắc thể giới tính X (XO)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000427', '21000000-0000-4000-8000-000000000107', 3, 'Có 3 nhiễm sắc thể giới tính (XXY)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000428', '21000000-0000-4000-8000-000000000107', 4, 'Thừa 1 nhiễm sắc thể ở cặp số 13', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000108', '11000000-0000-4000-8000-000000000011', 8, 'Phương pháp nghiên cứu phả hệ ở người có vai trò gì?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000429', '21000000-0000-4000-8000-000000000108', 1, 'Xác định tính trạng là trội hay lặn, do gen trên NST thường hay NST giới tính', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000430', '21000000-0000-4000-8000-000000000108', 2, 'Tạo ra các dòng thuần chủng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000431', '21000000-0000-4000-8000-000000000108', 3, 'Gây đột biến định hướng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000432', '21000000-0000-4000-8000-000000000108', 4, 'Nhân bản vô tính người', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000109', '11000000-0000-4000-8000-000000000011', 9, 'Ở đậu Hà Lan, gen A quy định hạt vàng trội hoàn toàn so với a hạt xanh. Phép lai Aa x aa cho F1 có tỉ lệ kiểu hình:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000433', '21000000-0000-4000-8000-000000000109', 1, '1 hạt vàng : 1 hạt xanh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000434', '21000000-0000-4000-8000-000000000109', 2, '3 hạt vàng : 1 hạt xanh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000435', '21000000-0000-4000-8000-000000000109', 3, '100% hạt vàng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000436', '21000000-0000-4000-8000-000000000109', 4, '100% hạt xanh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000110', '11000000-0000-4000-8000-000000000011', 10, 'Nhóm máu hệ ABO ở người do 3 alen Iᴬ, Iᴮ, Iᴼ quy định. Có tối đa bao nhiêu kiểu gen quy định nhóm máu?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000437', '21000000-0000-4000-8000-000000000110', 1, '6 kiểu gen', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000438', '21000000-0000-4000-8000-000000000110', 2, '4 kiểu gen', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000439', '21000000-0000-4000-8000-000000000110', 3, '3 kiểu gen', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000440', '21000000-0000-4000-8000-000000000110', 4, '9 kiểu gen', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #12: DT010403 - Sinh học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000012', 'DT010403', '00000000-0000-4000-8000-000000000005', 'Sinh học 12 - Di truyền quần thể & Hệ sinh thái (Đề 3)', 'Định luật Hardy-Weinberg, các nhân tố tiến hóa, chuỗi và lưới thức ăn.', 'Sinh học', 'hard', 50, 'published', now() - interval '13 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000111', '11000000-0000-4000-8000-000000000012', 1, 'Một quần thể cân bằng di truyền theo định luật Hardy-Weinberg có cấu trúc kiểu gen thỏa mãn công thức:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000441', '21000000-0000-4000-8000-000000000111', 1, 'p² AA + 2pq Aa + q² aa = 1', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000442', '21000000-0000-4000-8000-000000000111', 2, 'p² AA + pq Aa + q² aa = 1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000443', '21000000-0000-4000-8000-000000000111', 3, 'p AA + q aa = 1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000444', '21000000-0000-4000-8000-000000000111', 4, '2p AA + 2q aa = 1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000112', '11000000-0000-4000-8000-000000000012', 2, 'Nhân tố tiến hóa nào sau đây định hướng quá trình tiến hóa?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000445', '21000000-0000-4000-8000-000000000112', 1, 'Chọn lọc tự nhiên', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000446', '21000000-0000-4000-8000-000000000112', 2, 'Đột biến gen', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000447', '21000000-0000-4000-8000-000000000112', 3, 'Giao phối không ngẫu nhiên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000448', '21000000-0000-4000-8000-000000000112', 4, 'Yếu tố ngẫu nhiên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000113', '11000000-0000-4000-8000-000000000012', 3, 'Giao phối không ngẫu nhiên (tự phối, giao phối gần) làm cho quần thể có xu hướng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000449', '21000000-0000-4000-8000-000000000113', 1, 'Tăng tỉ lệ đồng hợp, giảm tỉ lệ dị hợp', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000450', '21000000-0000-4000-8000-000000000113', 2, 'Tăng tỉ lệ dị hợp, giảm tỉ lệ đồng hợp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000451', '21000000-0000-4000-8000-000000000113', 3, 'Tần số alen thay đổi nhanh chóng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000452', '21000000-0000-4000-8000-000000000113', 4, 'Làm xuất hiện các alen hoàn toàn mới', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000114', '11000000-0000-4000-8000-000000000012', 4, 'Nhân tố tiến hóa nào có thể đưa thêm alen mới vào trong quần thể?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000453', '21000000-0000-4000-8000-000000000114', 1, 'Đột biến gen và di - nhập gen', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000454', '21000000-0000-4000-8000-000000000114', 2, 'Chọn lọc tự nhiên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000455', '21000000-0000-4000-8000-000000000114', 3, 'Giao phối ngẫu nhiên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000456', '21000000-0000-4000-8000-000000000114', 4, 'Yếu tố ngẫu nhiên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000115', '11000000-0000-4000-8000-000000000012', 5, 'Tập hợp các sinh vật cùng loài, cùng sống trong một không gian và thời gian xác định được gọi là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000457', '21000000-0000-4000-8000-000000000115', 1, 'Quần thể sinh vật', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000458', '21000000-0000-4000-8000-000000000115', 2, 'Quần xã sinh vật', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000459', '21000000-0000-4000-8000-000000000115', 3, 'Hệ sinh thái', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000460', '21000000-0000-4000-8000-000000000115', 4, 'Sinh quyển', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000116', '11000000-0000-4000-8000-000000000012', 6, 'Mối quan hệ giữa hai loài trong đó cả hai cùng có lợi và nhất thiết phải có nhau gọi là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000461', '21000000-0000-4000-8000-000000000116', 1, 'Cộng sinh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000462', '21000000-0000-4000-8000-000000000116', 2, 'Hợp tác', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000463', '21000000-0000-4000-8000-000000000116', 3, 'Hội sinh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000464', '21000000-0000-4000-8000-000000000116', 4, 'Ký sinh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000117', '11000000-0000-4000-8000-000000000012', 7, 'Trong một chuỗi thức ăn, sinh vật nào luôn đứng ở bậc dinh dưỡng cấp 1?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000465', '21000000-0000-4000-8000-000000000117', 1, 'Sinh vật sản xuất (thực vật quang hợp)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000466', '21000000-0000-4000-8000-000000000117', 2, 'Sinh vật tiêu thụ bậc 1', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000467', '21000000-0000-4000-8000-000000000117', 3, 'Sinh vật tiêu thụ bậc 2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000468', '21000000-0000-4000-8000-000000000117', 4, 'Sinh vật phân giải', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000118', '11000000-0000-4000-8000-000000000012', 8, 'Hiệu suất sinh thái giữa các bậc dinh dưỡng liền kề trong hệ sinh thái thường xấp xỉ khoảng:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000469', '21000000-0000-4000-8000-000000000118', 1, '10%', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000470', '21000000-0000-4000-8000-000000000118', 2, '50%', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000471', '21000000-0000-4000-8000-000000000118', 3, '100%', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000472', '21000000-0000-4000-8000-000000000118', 4, '1%', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000119', '11000000-0000-4000-8000-000000000012', 9, 'Hệ sinh thái nào sau đây có độ đa dạng sinh học và lưới thức ăn phức tạp nhất?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000473', '21000000-0000-4000-8000-000000000119', 1, 'Rừng mưa nhiệt đới', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000474', '21000000-0000-4000-8000-000000000119', 2, 'Đồng rêu hàn đới', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000475', '21000000-0000-4000-8000-000000000119', 3, 'Sa mạc khô hạn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000476', '21000000-0000-4000-8000-000000000119', 4, 'Hệ sinh thái nông nghiệp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000120', '11000000-0000-4000-8000-000000000012', 10, 'Hiện tượng số lượng cá thể của quần thể dao động quanh mức cân bằng do các yếu tố môi trường gọi là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000477', '21000000-0000-4000-8000-000000000120', 1, 'Khống chế sinh học', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000478', '21000000-0000-4000-8000-000000000120', 2, 'Cạnh tranh cùng loài', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000479', '21000000-0000-4000-8000-000000000120', 3, 'Diệt vong quần thể', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000480', '21000000-0000-4000-8000-000000000120', 4, 'Thoái hóa giống', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #13: DT010501 - Tiếng Anh
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000013', 'DT010501', '00000000-0000-4000-8000-000000000003', 'Tiếng Anh - English Grammar Mastery (Đề 1)', 'Tenses, passive voice, conditionals, relative clauses and reported speech.', 'Tiếng Anh', 'medium', 45, 'published', now() - interval '12 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000121', '11000000-0000-4000-8000-000000000013', 1, 'By the time we arrived at the cinema, the movie ______.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000481', '21000000-0000-4000-8000-000000000121', 1, 'had already started', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000482', '21000000-0000-4000-8000-000000000121', 2, 'already started', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000483', '21000000-0000-4000-8000-000000000121', 3, 'has already started', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000484', '21000000-0000-4000-8000-000000000121', 4, 'was starting', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000122', '11000000-0000-4000-8000-000000000013', 2, 'If I ______ you, I would take that opportunity immediately.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000485', '21000000-0000-4000-8000-000000000122', 1, 'were', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000486', '21000000-0000-4000-8000-000000000122', 2, 'am', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000487', '21000000-0000-4000-8000-000000000122', 3, 'will be', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000488', '21000000-0000-4000-8000-000000000122', 4, 'had been', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000123', '11000000-0000-4000-8000-000000000013', 3, 'The bridge ______ by the end of next month according to the plan.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000489', '21000000-0000-4000-8000-000000000123', 1, 'will have been completed', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000490', '21000000-0000-4000-8000-000000000123', 2, 'is completed', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000491', '21000000-0000-4000-8000-000000000123', 3, 'has completed', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000492', '21000000-0000-4000-8000-000000000123', 4, 'will complete', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000124', '11000000-0000-4000-8000-000000000013', 4, 'The woman ______ lives next door is a famous university professor.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000493', '21000000-0000-4000-8000-000000000124', 1, 'who', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000494', '21000000-0000-4000-8000-000000000124', 2, 'whom', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000495', '21000000-0000-4000-8000-000000000124', 3, 'which', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000496', '21000000-0000-4000-8000-000000000124', 4, 'whose', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000125', '11000000-0000-4000-8000-000000000013', 5, 'She asked me where I ______ from.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000497', '21000000-0000-4000-8000-000000000125', 1, 'came', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000498', '21000000-0000-4000-8000-000000000125', 2, 'come', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000499', '21000000-0000-4000-8000-000000000125', 3, 'have come', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000500', '21000000-0000-4000-8000-000000000125', 4, 'coming', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000126', '11000000-0000-4000-8000-000000000013', 6, 'I wish I ______ enough money to buy that laptop right now.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000501', '21000000-0000-4000-8000-000000000126', 1, 'had', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000502', '21000000-0000-4000-8000-000000000126', 2, 'have', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000503', '21000000-0000-4000-8000-000000000126', 3, 'will have', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000504', '21000000-0000-4000-8000-000000000126', 4, 'have had', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000127', '11000000-0000-4000-8000-000000000013', 7, 'Hardly ______ into the room when the phone began ringing.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000505', '21000000-0000-4000-8000-000000000127', 1, 'had he entered', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000506', '21000000-0000-4000-8000-000000000127', 2, 'he entered', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000507', '21000000-0000-4000-8000-000000000127', 3, 'did he enter', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000508', '21000000-0000-4000-8000-000000000127', 4, 'he had entered', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000128', '11000000-0000-4000-8000-000000000013', 8, 'Neither the teacher nor the students ______ satisfied with the exam results.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000509', '21000000-0000-4000-8000-000000000128', 1, 'were', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000510', '21000000-0000-4000-8000-000000000128', 2, 'was', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000511', '21000000-0000-4000-8000-000000000128', 3, 'is', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000512', '21000000-0000-4000-8000-000000000128', 4, 'be', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000129', '11000000-0000-4000-8000-000000000013', 9, 'You had better ______ a doctor before your illness gets worse.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000513', '21000000-0000-4000-8000-000000000129', 1, 'see', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000514', '21000000-0000-4000-8000-000000000129', 2, 'to see', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000515', '21000000-0000-4000-8000-000000000129', 3, 'seeing', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000516', '21000000-0000-4000-8000-000000000129', 4, 'saw', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000130', '11000000-0000-4000-8000-000000000013', 10, 'Despite ______ very tired, she managed to finish the assignment before midnight.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000517', '21000000-0000-4000-8000-000000000130', 1, 'being', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000518', '21000000-0000-4000-8000-000000000130', 2, 'she was', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000519', '21000000-0000-4000-8000-000000000130', 3, 'be', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000520', '21000000-0000-4000-8000-000000000130', 4, 'been', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #14: DT010502 - Tiếng Anh
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000014', 'DT010502', '00000000-0000-4000-8000-000000000003', 'Tiếng Anh - Vocabulary & Collocations (Đề 2)', 'Academic vocabulary, phrasal verbs, idioms and standard collocations.', 'Tiếng Anh', 'medium', 45, 'published', now() - interval '11 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000131', '11000000-0000-4000-8000-000000000014', 1, 'The company has decided to ______ off 200 workers due to financial difficulties.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000521', '21000000-0000-4000-8000-000000000131', 1, 'lay', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000522', '21000000-0000-4000-8000-000000000131', 2, 'put', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000523', '21000000-0000-4000-8000-000000000131', 3, 'take', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000524', '21000000-0000-4000-8000-000000000131', 4, 'give', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000132', '11000000-0000-4000-8000-000000000014', 2, 'It is crucial that students take ______ of modern technology in their learning.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000525', '21000000-0000-4000-8000-000000000132', 1, 'advantage', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000526', '21000000-0000-4000-8000-000000000132', 2, 'chance', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000527', '21000000-0000-4000-8000-000000000132', 3, 'opportunity', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000528', '21000000-0000-4000-8000-000000000132', 4, 'effect', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000133', '11000000-0000-4000-8000-000000000014', 3, 'The government is making every effort to ______ the standard of living.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000529', '21000000-0000-4000-8000-000000000133', 1, 'raise', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000530', '21000000-0000-4000-8000-000000000133', 2, 'rise', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000531', '21000000-0000-4000-8000-000000000133', 3, 'arise', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000532', '21000000-0000-4000-8000-000000000133', 4, 'lift', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000134', '11000000-0000-4000-8000-000000000014', 4, 'He succeeded in passing the entrance exam with ______ colors.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000533', '21000000-0000-4000-8000-000000000134', 1, 'flying', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000534', '21000000-0000-4000-8000-000000000134', 2, 'shining', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000535', '21000000-0000-4000-8000-000000000134', 3, 'bright', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000536', '21000000-0000-4000-8000-000000000134', 4, 'glaring', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000135', '11000000-0000-4000-8000-000000000014', 5, 'Environmentalists are concerned about the rapid ______ of natural resources.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000537', '21000000-0000-4000-8000-000000000135', 1, 'depletion', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000538', '21000000-0000-4000-8000-000000000135', 2, 'destruction', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000539', '21000000-0000-4000-8000-000000000135', 3, 'pollution', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000540', '21000000-0000-4000-8000-000000000135', 4, 'expansion', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000136', '11000000-0000-4000-8000-000000000014', 6, 'She has an impressive ______ of English idioms and proverbs.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000541', '21000000-0000-4000-8000-000000000136', 1, 'command', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000542', '21000000-0000-4000-8000-000000000136', 2, 'skill', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000543', '21000000-0000-4000-8000-000000000136', 3, 'ability', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000544', '21000000-0000-4000-8000-000000000136', 4, 'master', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000137', '11000000-0000-4000-8000-000000000014', 7, 'Can you please ______ an eye on my luggage while I go to the restroom?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000545', '21000000-0000-4000-8000-000000000137', 1, 'keep', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000546', '21000000-0000-4000-8000-000000000137', 2, 'hold', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000547', '21000000-0000-4000-8000-000000000137', 3, 'put', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000548', '21000000-0000-4000-8000-000000000137', 4, 'give', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000138', '11000000-0000-4000-8000-000000000014', 8, 'Artificial intelligence is expected to play a ______ role in future healthcare.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000549', '21000000-0000-4000-8000-000000000138', 1, 'pivotal', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000550', '21000000-0000-4000-8000-000000000138', 2, 'trivial', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000551', '21000000-0000-4000-8000-000000000138', 3, 'remote', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000552', '21000000-0000-4000-8000-000000000138', 4, 'vague', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000139', '11000000-0000-4000-8000-000000000014', 9, 'The team had to call ______ the outdoor match because of heavy rain.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000553', '21000000-0000-4000-8000-000000000139', 1, 'off', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000554', '21000000-0000-4000-8000-000000000139', 2, 'out', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000555', '21000000-0000-4000-8000-000000000139', 3, 'up', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000556', '21000000-0000-4000-8000-000000000139', 4, 'on', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000140', '11000000-0000-4000-8000-000000000014', 10, 'I couldn''t help ______ when he slipped on the banana peel.', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000557', '21000000-0000-4000-8000-000000000140', 1, 'laughing', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000558', '21000000-0000-4000-8000-000000000140', 2, 'to laugh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000559', '21000000-0000-4000-8000-000000000140', 3, 'laugh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000560', '21000000-0000-4000-8000-000000000140', 4, 'laughed', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #15: DT010503 - Tiếng Anh
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000015', 'DT010503', '00000000-0000-4000-8000-000000000003', 'Tiếng Anh - Error Identification & Transformations (Đề 3)', 'Tìm lỗi sai trong câu, viết lại câu đồng nghĩa và liên từ nâng cao.', 'Tiếng Anh', 'hard', 50, 'published', now() - interval '10 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000141', '11000000-0000-4000-8000-000000000015', 1, 'Find the mistake: ''The number of students attending the workshop have increased significantly.''', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000561', '21000000-0000-4000-8000-000000000141', 1, 'have -> has', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000562', '21000000-0000-4000-8000-000000000141', 2, 'attending -> attended', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000563', '21000000-0000-4000-8000-000000000141', 3, 'The -> A', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000564', '21000000-0000-4000-8000-000000000141', 4, 'significantly -> significant', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000142', '11000000-0000-4000-8000-000000000015', 2, 'Find the mistake: ''Much people believe that exercise contributes to longevity.''', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000565', '21000000-0000-4000-8000-000000000142', 1, 'Much -> Many', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000566', '21000000-0000-4000-8000-000000000142', 2, 'believe -> believes', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000567', '21000000-0000-4000-8000-000000000142', 3, 'contributes -> contributing', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000568', '21000000-0000-4000-8000-000000000142', 4, 'to -> for', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000143', '11000000-0000-4000-8000-000000000015', 3, '''It was not necessary for you to bring an umbrella.'' means:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000569', '21000000-0000-4000-8000-000000000143', 1, 'You needn''t have brought an umbrella.', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000570', '21000000-0000-4000-8000-000000000143', 2, 'You shouldn''t bring an umbrella.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000571', '21000000-0000-4000-8000-000000000143', 3, 'You must have brought an umbrella.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000572', '21000000-0000-4000-8000-000000000143', 4, 'You can''t bring an umbrella.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000144', '11000000-0000-4000-8000-000000000015', 4, '''I haven''t eaten sushi for three months.'' means:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000573', '21000000-0000-4000-8000-000000000144', 1, 'The last time I ate sushi was three months ago.', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000574', '21000000-0000-4000-8000-000000000144', 2, 'I have eaten sushi three times in my life.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000575', '21000000-0000-4000-8000-000000000144', 3, 'I will eat sushi in three months.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000576', '21000000-0000-4000-8000-000000000144', 4, 'I had eaten sushi for three months.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000145', '11000000-0000-4000-8000-000000000015', 5, 'Find the mistake: ''She is so intelligent that she can solve this complicated problem easily.''', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000577', '21000000-0000-4000-8000-000000000145', 1, 'No mistake (sentence is correct)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000578', '21000000-0000-4000-8000-000000000145', 2, 'so -> such', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000579', '21000000-0000-4000-8000-000000000145', 3, 'easily -> easy', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000580', '21000000-0000-4000-8000-000000000145', 4, 'that -> which', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000146', '11000000-0000-4000-8000-000000000015', 6, '''No sooner had he left the house than it started raining.'' means:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000581', '21000000-0000-4000-8000-000000000146', 1, 'As soon as he left the house, it started raining.', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000582', '21000000-0000-4000-8000-000000000146', 2, 'He left the house after it rained.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000583', '21000000-0000-4000-8000-000000000146', 3, 'It had rained before he left.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000584', '21000000-0000-4000-8000-000000000146', 4, 'He stayed inside because of rain.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000147', '11000000-0000-4000-8000-000000000015', 7, 'Find the mistake: ''He suggested to go to the beach this weekend.''', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000585', '21000000-0000-4000-8000-000000000147', 1, 'to go -> going', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000586', '21000000-0000-4000-8000-000000000147', 2, 'He -> Him', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000587', '21000000-0000-4000-8000-000000000147', 3, 'the beach -> beach', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000588', '21000000-0000-4000-8000-000000000147', 4, 'this weekend -> on this weekend', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000148', '11000000-0000-4000-8000-000000000015', 8, '''Because of his bad health, he had to retire early.'' means:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000589', '21000000-0000-4000-8000-000000000148', 1, 'Because he was in bad health, he had to retire early.', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000590', '21000000-0000-4000-8000-000000000148', 2, 'Although his health was bad, he retired early.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000591', '21000000-0000-4000-8000-000000000148', 3, 'Despite retiring early, his health was good.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000592', '21000000-0000-4000-8000-000000000148', 4, 'He retired early so that his health became worse.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000149', '11000000-0000-4000-8000-000000000015', 9, 'Find the mistake: ''Every teacher and student are responsible for keeping the classroom tidy.''', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000593', '21000000-0000-4000-8000-000000000149', 1, 'are -> is', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000594', '21000000-0000-4000-8000-000000000149', 2, 'responsible for -> responsible to', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000595', '21000000-0000-4000-8000-000000000149', 3, 'keeping -> keep', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000596', '21000000-0000-4000-8000-000000000149', 4, 'tidy -> tidily', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000150', '11000000-0000-4000-8000-000000000015', 10, '''I regret telling him the secret.'' means:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000597', '21000000-0000-4000-8000-000000000150', 1, 'I wish I hadn''t told him the secret.', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000598', '21000000-0000-4000-8000-000000000150', 2, 'I am glad that I told him the secret.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000599', '21000000-0000-4000-8000-000000000150', 3, 'I will never tell him the secret.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000600', '21000000-0000-4000-8000-000000000150', 4, 'I didn''t tell him the secret.', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #16: DT010601 - Lịch sử
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000016', 'DT010601', '00000000-0000-4000-8000-000000000006', 'Lịch sử 12 - Lịch sử Việt Nam giai đoạn 1930 - 1954 (Đề 1)', 'Thành lập Đảng, Phong trào 1930-1931, Cách mạng tháng Tám và Chiến thắng Điện Biên Phủ.', 'Lịch sử', 'medium', 45, 'published', now() - interval '9 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000151', '11000000-0000-4000-8000-000000000016', 1, 'Đảng Cộng sản Việt Nam được thành lập vào ngày tháng năm nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000601', '21000000-0000-4000-8000-000000000151', 1, '3/2/1930', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000602', '21000000-0000-4000-8000-000000000151', 2, '2/9/1945', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000603', '21000000-0000-4000-8000-000000000151', 3, '19/8/1945', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000604', '21000000-0000-4000-8000-000000000151', 4, '22/12/1944', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000152', '11000000-0000-4000-8000-000000000016', 2, 'Hội nghị hợp nhất các tổ chức cộng sản đầu năm 1930 do ai chủ trì?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000605', '21000000-0000-4000-8000-000000000152', 1, 'Nguyễn Ái Quốc', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000606', '21000000-0000-4000-8000-000000000152', 2, 'Trần Phú', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000607', '21000000-0000-4000-8000-000000000152', 3, 'Lê Hồng Phong', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000608', '21000000-0000-4000-8000-000000000152', 4, 'Hà Huy Tập', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000153', '11000000-0000-4000-8000-000000000016', 3, 'Đỉnh cao của phong trào cách mạng 1930 - 1931 ở Việt Nam là sự ra đời của:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000609', '21000000-0000-4000-8000-000000000153', 1, 'Chính quyền Xô viết Nghệ - Tĩnh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000610', '21000000-0000-4000-8000-000000000153', 2, 'Mặt trận Việt Minh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000611', '21000000-0000-4000-8000-000000000153', 3, 'Đội Việt Nam Tuyên truyền Giải phóng quân', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000612', '21000000-0000-4000-8000-000000000153', 4, 'Tổng bộ Việt Minh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000154', '11000000-0000-4000-8000-000000000016', 4, 'Tổng khởi nghĩa tháng Tám năm 1945 giành thắng lợi hoàn toàn trong cả nước trong khoảng thời gian:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000613', '21000000-0000-4000-8000-000000000154', 1, 'Khoảng 15 ngày (từ 14 đến 28/8/1945)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000614', '21000000-0000-4000-8000-000000000154', 2, 'Một tháng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000615', '21000000-0000-4000-8000-000000000154', 3, 'Hai tháng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000616', '21000000-0000-4000-8000-000000000154', 4, 'Ba ngày', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000155', '11000000-0000-4000-8000-000000000016', 5, 'Chủ tịch Hồ Chí Minh đọc bản Tuyên ngôn Độc lập tại Quảng trường Ba Đình vào ngày:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000617', '21000000-0000-4000-8000-000000000155', 1, '2/9/1945', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000618', '21000000-0000-4000-8000-000000000155', 2, '19/8/1945', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000619', '21000000-0000-4000-8000-000000000155', 3, '30/4/1975', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000620', '21000000-0000-4000-8000-000000000155', 4, '22/12/1944', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000156', '11000000-0000-4000-8000-000000000016', 6, 'Sau Cách mạng tháng Tám 1945, nước Việt Nam Dân chủ Cộng hòa đứng trước những khó khăn nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000621', '21000000-0000-4000-8000-000000000156', 1, 'Giặc đói, giặc dốt và giặc ngoại xâm (''Ngàn cân treo sợi tóc'')', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000622', '21000000-0000-4000-8000-000000000156', 2, 'Chỉ có khó khăn về tài chính', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000623', '21000000-0000-4000-8000-000000000156', 3, 'Chỉ có nạn đói ở miền Bắc', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000624', '21000000-0000-4000-8000-000000000156', 4, 'Bị cấm vận kinh tế hoàn toàn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000157', '11000000-0000-4000-8000-000000000016', 7, 'Chiến dịch nào của quân và dân ta đã giành thế chủ động trên chiến trường chính Bắc Bộ năm 1950?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000625', '21000000-0000-4000-8000-000000000157', 1, 'Chiến dịch Biên giới Thu - Đông 1950', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000626', '21000000-0000-4000-8000-000000000157', 2, 'Chiến dịch Việt Bắc 1947', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000627', '21000000-0000-4000-8000-000000000157', 3, 'Chiến dịch Tây Bắc 1952', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000628', '21000000-0000-4000-8000-000000000157', 4, 'Chiến dịch Điện Biên Phủ 1954', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000158', '11000000-0000-4000-8000-000000000016', 8, 'Khẩu hiệu nổi tiếng của phong trào diệt giặc dốt sau năm 1945 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000629', '21000000-0000-4000-8000-000000000158', 1, 'Bình dân học vụ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000630', '21000000-0000-4000-8000-000000000158', 2, 'Hũ gạo cứu đói', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000631', '21000000-0000-4000-8000-000000000158', 3, 'Tuần lễ vàng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000632', '21000000-0000-4000-8000-000000000158', 4, 'Tăng gia sản xuất', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000159', '11000000-0000-4000-8000-000000000016', 9, 'Chiến thắng quân sự lớn nhất của ta kết thúc thắng lợi cuộc kháng chiến chống Pháp là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000633', '21000000-0000-4000-8000-000000000159', 1, 'Chiến dịch Điện Biên Phủ (1954)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000634', '21000000-0000-4000-8000-000000000159', 2, 'Chiến dịch Việt Bắc (1947)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000635', '21000000-0000-4000-8000-000000000159', 3, 'Chiến dịch Thượng Lào (1953)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000636', '21000000-0000-4000-8000-000000000159', 4, 'Trận Đông Khê (1950)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000160', '11000000-0000-4000-8000-000000000016', 10, 'Hiệp định Giơ-ne-vơ năm 1954 về Đông Dương công nhận các quyền dân tộc cơ bản của Việt Nam gồm:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000637', '21000000-0000-4000-8000-000000000160', 1, 'Độc lập, chủ quyền, thống nhất và toàn vẹn lãnh thổ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000638', '21000000-0000-4000-8000-000000000160', 2, 'Tự do thương mại và phát triển kinh tế', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000639', '21000000-0000-4000-8000-000000000160', 3, 'Thành lập chính phủ liên hiệp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000640', '21000000-0000-4000-8000-000000000160', 4, 'Gia nhập Khối Liên hiệp Pháp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #17: DT010602 - Lịch sử
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000017', 'DT010602', '00000000-0000-4000-8000-000000000006', 'Lịch sử 12 - Lịch sử Việt Nam giai đoạn 1954 - 1975 (Đề 2)', 'Phong trào Đồng Khởi, đánh bại các chiến lược chiến tranh của Mỹ và Đại thắng mùa Xuân 1975.', 'Lịch sử', 'medium', 45, 'published', now() - interval '8 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000161', '11000000-0000-4000-8000-000000000017', 1, 'Phong trào ''Đồng khởi'' (1959 - 1960) nổ ra tiêu biểu nhất và mở đầu ở tỉnh nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000641', '21000000-0000-4000-8000-000000000161', 1, 'Bến Tre', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000642', '21000000-0000-4000-8000-000000000161', 2, 'Quảng Nam', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000643', '21000000-0000-4000-8000-000000000161', 3, 'Tây Ninh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000644', '21000000-0000-4000-8000-000000000161', 4, 'Bình Định', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000162', '11000000-0000-4000-8000-000000000017', 2, 'Chiến lược ''Chiến tranh đặc biệt'' (1961 - 1965) của Mỹ ở miền Nam thực hiện bằng công thức nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000645', '21000000-0000-4000-8000-000000000162', 1, 'Quân đội Sài Gòn + Cố vấn, vũ khí, phương tiện chiến tranh của Mỹ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000646', '21000000-0000-4000-8000-000000000162', 2, 'Quân viễn chinh Mỹ trực tiếp tham chiến', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000647', '21000000-0000-4000-8000-000000000162', 3, 'Quân đồng minh của Mỹ giữ vai trò nòng cốt', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000648', '21000000-0000-4000-8000-000000000162', 4, 'Quân đội Sài Gòn tự tác chiến hoàn toàn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000163', '11000000-0000-4000-8000-000000000017', 3, 'Chiến thắng quân sự nào của quân dân miền Nam đã mở đầu cho cao trào ''Tìm Mỹ mà đánh, lùng ngụy mà diệt''?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000649', '21000000-0000-4000-8000-000000000163', 1, 'Chiến thắng Vạn Tường (Quảng Ngãi, 1965)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000650', '21000000-0000-4000-8000-000000000163', 2, 'Chiến thắng Ấp Bắc (Mỹ Tho, 1963)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000651', '21000000-0000-4000-8000-000000000163', 3, 'Chiến thắng Ba Gia (1965)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000652', '21000000-0000-4000-8000-000000000163', 4, 'Chiến dịch Tây Nguyên (1975)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000164', '11000000-0000-4000-8000-000000000017', 4, 'Cuộc Tổng tiến công và nổi dậy Xuân Mậu Thân 1968 đã buộc Mỹ phải:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000653', '21000000-0000-4000-8000-000000000164', 1, 'Tuyên bố ''phi Mỹ hóa'' chiến tranh và ngồi vào bàn đàm phán Paris', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000654', '21000000-0000-4000-8000-000000000164', 2, 'Ký ngay Hiệp định Paris', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000655', '21000000-0000-4000-8000-000000000164', 3, 'Rút toàn bộ quân về nước ngay lập tức', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000656', '21000000-0000-4000-8000-000000000164', 4, 'Mở rộng chiến tranh ra toàn Đông Dương', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000165', '11000000-0000-4000-8000-000000000017', 5, 'Thắng lợi nào được coi là trận ''Điện Biên Phủ trên không'' buộc Mỹ phải ký Hiệp định Paris năm 1973?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000657', '21000000-0000-4000-8000-000000000165', 1, 'Đánh bại cuộc tập kích đường không bằng B52 vào Hà Nội, Hải Phòng (1972)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000658', '21000000-0000-4000-8000-000000000165', 2, 'Chiến dịch Đường 9 - Nam Lào (1971)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000659', '21000000-0000-4000-8000-000000000165', 3, 'Chiến thắng Khe Sanh (1968)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000660', '21000000-0000-4000-8000-000000000165', 4, 'Trận Ấp Bắc (1963)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000166', '11000000-0000-4000-8000-000000000017', 6, 'Theo Hiệp định Paris (1973), điều khoản quan trọng nhất tạo thời cơ giải phóng miền Nam là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000661', '21000000-0000-4000-8000-000000000166', 1, 'Mỹ và các nước cam kết tôn trọng độc lập của VN và Mỹ rút hết quân viễn chinh về nước', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000662', '21000000-0000-4000-8000-000000000166', 2, 'Thực hiện ngừng bắn và chia đôi đất nước', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000663', '21000000-0000-4000-8000-000000000166', 3, 'Tổng tuyển cử tự do dưới sự giám sát quốc tế', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000664', '21000000-0000-4000-8000-000000000166', 4, 'Mỹ bồi thường chiến tranh ngay', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000167', '11000000-0000-4000-8000-000000000017', 7, 'Địa bàn mở đầu cho cuộc Tổng tiến công và nổi dậy mùa Xuân năm 1975 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000665', '21000000-0000-4000-8000-000000000167', 1, 'Chiến dịch Tây Nguyên', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000666', '21000000-0000-4000-8000-000000000167', 2, 'Chiến dịch Huế - Đà Nẵng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000667', '21000000-0000-4000-8000-000000000167', 3, 'Chiến dịch Hồ Chí Minh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000668', '21000000-0000-4000-8000-000000000167', 4, 'Chiến dịch Đường 14 - Phước Long', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000168', '11000000-0000-4000-8000-000000000017', 8, 'Trận then chốt mở màn thắng lợi rực rỡ trong Chiến dịch Tây Nguyên năm 1975 là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000669', '21000000-0000-4000-8000-000000000168', 1, 'Buôn Ma Thuột', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000670', '21000000-0000-4000-8000-000000000168', 2, 'Kon Tum', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000671', '21000000-0000-4000-8000-000000000168', 3, 'Pleiku', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000672', '21000000-0000-4000-8000-000000000168', 4, 'Gia Lai', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000169', '11000000-0000-4000-8000-000000000017', 9, 'Chiến dịch giải phóng Sài Gòn - Gia Định năm 1975 được Bộ Chính trị đặt tên là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000673', '21000000-0000-4000-8000-000000000169', 1, 'Chiến dịch Hồ Chí Minh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000674', '21000000-0000-4000-8000-000000000169', 2, 'Chiến dịch Giải phóng miền Nam', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000675', '21000000-0000-4000-8000-000000000169', 3, 'Chiến dịch Quang Trung', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000676', '21000000-0000-4000-8000-000000000169', 4, 'Chiến dịch Điện Biên Phủ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000170', '11000000-0000-4000-8000-000000000017', 10, 'Thời khắc lịch sử đánh dấu thắng lợi hoàn toàn của Chiến dịch Hồ Chí Minh là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000677', '21000000-0000-4000-8000-000000000170', 1, '11h30 ngày 30/4/1975, cờ cách mạng tung bay trên nóc Dinh Độc Lập', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000678', '21000000-0000-4000-8000-000000000170', 2, '17h00 ngày 26/4/1975', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000679', '21000000-0000-4000-8000-000000000170', 3, '10h45 ngày 30/4/1975', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000680', '21000000-0000-4000-8000-000000000170', 4, '24h00 ngày 1/5/1975', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #18: DT010603 - Lịch sử
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000018', 'DT010603', '00000000-0000-4000-8000-000000000006', 'Lịch sử 12 - Lịch sử Thế giới Hiện đại 1945 đến nay (Đề 3)', 'Trật tự hai cực Ianta, Liên Hợp Quốc, Chiến tranh Lạnh, ASEAN và cách mạng KHCN.', 'Lịch sử', 'hard', 50, 'published', now() - interval '7 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000171', '11000000-0000-4000-8000-000000000018', 1, 'Hội nghị Ianta (tháng 2/1945) có sự tham gia của nguyên thủ ba cường quốc là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000681', '21000000-0000-4000-8000-000000000171', 1, 'Liên Xô, Mỹ, Anh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000682', '21000000-0000-4000-8000-000000000171', 2, 'Mỹ, Anh, Pháp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000683', '21000000-0000-4000-8000-000000000171', 3, 'Liên Xô, Trung Quốc, Mỹ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000684', '21000000-0000-4000-8000-000000000171', 4, 'Mỹ, Đức, Nhật', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000172', '11000000-0000-4000-8000-000000000018', 2, 'Mục đích lớn nhất của tổ chức Liên Hợp Quốc (thành lập năm 1945) là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000685', '21000000-0000-4000-8000-000000000172', 1, 'Duy trì hòa bình và an ninh thế giới', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000686', '21000000-0000-4000-8000-000000000172', 2, 'Thúc đẩy tự do thương mại toàn cầu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000687', '21000000-0000-4000-8000-000000000172', 3, 'Xóa bỏ nghèo đói ở các nước thuộc địa', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000688', '21000000-0000-4000-8000-000000000172', 4, 'Hỗ trợ tài chính cho các nước tư bản', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000173', '11000000-0000-4000-8000-000000000018', 3, 'Cơ quan giữ vai trò trọng yếu trong việc duy trì hòa bình và an ninh quốc tế của LHQ là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000689', '21000000-0000-4000-8000-000000000173', 1, 'Hội đồng Bảo an', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000690', '21000000-0000-4000-8000-000000000173', 2, 'Đại hội đồng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000691', '21000000-0000-4000-8000-000000000173', 3, 'Tòa án Quốc tế', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000692', '21000000-0000-4000-8000-000000000173', 4, 'Ban Thư ký', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000174', '11000000-0000-4000-8000-000000000018', 4, 'Chiến tranh Lạnh (1947 - 1989) là tình trạng đối đầu căng thẳng giữa hai phe do hai nước nào đứng đầu?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000693', '21000000-0000-4000-8000-000000000174', 1, 'Mỹ và Liên Xô', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000694', '21000000-0000-4000-8000-000000000174', 2, 'Mỹ và Trung Quốc', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000695', '21000000-0000-4000-8000-000000000174', 3, 'Anh và Pháp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000696', '21000000-0000-4000-8000-000000000174', 4, 'Liên Xô và Đức', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000175', '11000000-0000-4000-8000-000000000018', 5, 'Kế hoạch Mác-san (1947) của Mỹ nhằm mục đích gì đối với các nước Tây Âu?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000697', '21000000-0000-4000-8000-000000000175', 1, 'Phục hồi kinh tế và khống chế các nước Tây Âu', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000698', '21000000-0000-4000-8000-000000000175', 2, 'Viện trợ nhân đạo vô điều kiện', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000699', '21000000-0000-4000-8000-000000000175', 3, 'Chống lại chủ nghĩa phát xít', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000700', '21000000-0000-4000-8000-000000000175', 4, 'Xây dựng bức tường Berlin', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000176', '11000000-0000-4000-8000-000000000018', 6, 'Năm 1960 được lịch sử ghi nhận là ''Năm châu Phi'' vì sự kiện nổi bật nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000701', '21000000-0000-4000-8000-000000000176', 1, '17 quốc gia châu Phi tuyên bố độc lập', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000702', '21000000-0000-4000-8000-000000000176', 2, 'Toàn bộ châu Phi xóa bỏ chủ nghĩa thực dân', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000703', '21000000-0000-4000-8000-000000000176', 3, 'Liên minh châu Phi (AU) được thành lập', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000704', '21000000-0000-4000-8000-000000000176', 4, 'Chấm dứt nạn phân biệt chủng tộc', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000177', '11000000-0000-4000-8000-000000000018', 7, 'Hiệp hội các quốc gia Đông Nam Á (ASEAN) được thành lập vào năm nào tại Băng Cốc?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000705', '21000000-0000-4000-8000-000000000177', 1, 'Năm 1967', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000706', '21000000-0000-4000-8000-000000000177', 2, 'Năm 1945', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000707', '21000000-0000-4000-8000-000000000177', 3, 'Năm 1975', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000708', '21000000-0000-4000-8000-000000000177', 4, 'Năm 1995', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000178', '11000000-0000-4000-8000-000000000018', 8, 'Việt Nam chính thức trở thành thành viên thứ 7 của tổ chức ASEAN vào năm nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000709', '21000000-0000-4000-8000-000000000178', 1, 'Năm 1995', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000710', '21000000-0000-4000-8000-000000000178', 2, 'Năm 1990', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000711', '21000000-0000-4000-8000-000000000178', 3, 'Năm 1997', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000712', '21000000-0000-4000-8000-000000000178', 4, 'Năm 2000', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000179', '11000000-0000-4000-8000-000000000018', 9, 'Xu thế chủ đạo của quan hệ quốc tế sau khi Chiến tranh Lạnh chấm dứt là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000713', '21000000-0000-4000-8000-000000000179', 1, 'Hòa hoãn, hợp tác và cùng phát triển', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000714', '21000000-0000-4000-8000-000000000179', 2, 'Tiếp tục chạy đua vũ trang quyết liệt', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000715', '21000000-0000-4000-8000-000000000179', 3, 'Hình thành các khối liên minh quân sự mới', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000716', '21000000-0000-4000-8000-000000000179', 4, 'Xảy ra chiến tranh thế giới thứ ba', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000180', '11000000-0000-4000-8000-000000000018', 10, 'Đặc trưng cơ bản nhất của cuộc cách mạng khoa học - công nghệ hiện đại là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000717', '21000000-0000-4000-8000-000000000180', 1, 'Khoa học trở thành lực lượng sản xuất trực tiếp', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000718', '21000000-0000-4000-8000-000000000180', 2, 'Máy hơi nước được ứng dụng rộng rãi', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000719', '21000000-0000-4000-8000-000000000180', 3, 'Năng lượng hóa thạch chiếm ưu thế', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000720', '21000000-0000-4000-8000-000000000180', 4, 'Sản xuất nông nghiệp là trọng tâm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #19: DT010701 - Địa lý
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000019', 'DT010701', '00000000-0000-4000-8000-000000000007', 'Địa lý 12 - Địa lý Tự nhiên Việt Nam (Đề 1)', 'Vị trí địa lý, đặc điểm khí hậu nhiệt đới ẩm gió mùa, địa hình và tài nguyên thiên nhiên.', 'Địa lý', 'medium', 45, 'published', now() - interval '6 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000181', '11000000-0000-4000-8000-000000000019', 1, 'Lãnh thổ Việt Nam nằm trọn vẹn trong vùng đới khí hậu nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000721', '21000000-0000-4000-8000-000000000181', 1, 'Nội chí tuyến Bắc bán cầu', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000722', '21000000-0000-4000-8000-000000000181', 2, 'Cận xích đạo Nam bán cầu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000723', '21000000-0000-4000-8000-000000000181', 3, 'Ôn đới lục địa', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000724', '21000000-0000-4000-8000-000000000181', 4, 'Cận nhiệt đới hải dương', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000182', '11000000-0000-4000-8000-000000000019', 2, 'Đặc điểm nổi bật của địa hình Việt Nam là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000725', '21000000-0000-4000-8000-000000000182', 1, 'Đồi núi chiếm 3/4 diện tích lãnh thổ, chủ yếu là đồi núi thấp', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000726', '21000000-0000-4000-8000-000000000182', 2, 'Đồng bằng chiếm phần lớn diện tích', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000727', '21000000-0000-4000-8000-000000000182', 3, 'Đồi núi cao trên 2000m chiếm ưu thế', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000728', '21000000-0000-4000-8000-000000000182', 4, 'Địa hình bằng phẳng từ Bắc vào Nam', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000183', '11000000-0000-4000-8000-000000000019', 3, 'Gió mùa mùa đông (gió mùa Đông Bắc) hoạt động chủ yếu ở khu vực nào của nước ta?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000729', '21000000-0000-4000-8000-000000000183', 1, 'Miền Bắc (từ dãy Bạch Mã trở ra)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000730', '21000000-0000-4000-8000-000000000183', 2, 'Toàn bộ lãnh thổ nước ta', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000731', '21000000-0000-4000-8000-000000000183', 3, 'Chỉ vùng núi Tây Bắc', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000732', '21000000-0000-4000-8000-000000000183', 4, 'Nam Bộ và Tây Nguyên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000184', '11000000-0000-4000-8000-000000000019', 4, 'Thiên nhiên nước ta có sự phân hóa sâu sắc theo các hướng nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000733', '21000000-0000-4000-8000-000000000184', 1, 'Bắc - Nam, Đông - Tây và theo độ cao', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000734', '21000000-0000-4000-8000-000000000184', 2, 'Chỉ theo hướng Đông - Tây', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000735', '21000000-0000-4000-8000-000000000184', 3, 'Chỉ theo độ cao địa hình', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000736', '21000000-0000-4000-8000-000000000184', 4, 'Chỉ theo mùa khô và mùa mưa', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000185', '11000000-0000-4000-8000-000000000019', 5, 'Đặc điểm nào sau đây chứng minh tính chất nhiệt đới của khí hậu nước ta?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000737', '21000000-0000-4000-8000-000000000185', 1, 'Tổng bức xạ lớn, nhiệt độ trung bình năm trên 20°C (trừ vùng núi cao)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000738', '21000000-0000-4000-8000-000000000185', 2, 'Lượng mưa cả năm dưới 500mm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000739', '21000000-0000-4000-8000-000000000185', 3, 'Có mùa đông lạnh có tuyết rơi khắp nơi', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000740', '21000000-0000-4000-8000-000000000185', 4, 'Biên độ nhiệt năm rất nhỏ ở miền Bắc', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000186', '11000000-0000-4000-8000-000000000019', 6, 'Dãy núi nào đóng vai trò là ranh giới khí hậu tự nhiên giữa miền Bắc và miền Nam nước ta?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000741', '21000000-0000-4000-8000-000000000186', 1, 'Dãy Bạch Mã', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000742', '21000000-0000-4000-8000-000000000186', 2, 'Dãy Hoàng Liên Sơn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000743', '21000000-0000-4000-8000-000000000186', 3, 'Dãy Trường Sơn Bắc', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000744', '21000000-0000-4000-8000-000000000186', 4, 'Dãy Hoành Sơn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000187', '11000000-0000-4000-8000-000000000019', 7, 'Sông ngòi nước ta có đặc điểm nổi bật là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000745', '21000000-0000-4000-8000-000000000187', 1, 'Mạng lưới sông ngòi dày đặc, nhiều nước, giàu phù sa', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000746', '21000000-0000-4000-8000-000000000187', 2, 'Ít sông, lòng sông hẹp và ngắn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000747', '21000000-0000-4000-8000-000000000187', 3, 'Chế độ nước điều hòa quanh năm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000748', '21000000-0000-4000-8000-000000000187', 4, 'Sông ngòi đóng băng vào mùa đông', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000188', '11000000-0000-4000-8000-000000000019', 8, 'Hệ sinh thái rừng nguyên sinh đặc trưng cho vùng khí hậu nhiệt đới ẩm gió mùa nước ta là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000749', '21000000-0000-4000-8000-000000000188', 1, 'Rừng rậm nhiệt đới ẩm lá rộng thường xanh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000750', '21000000-0000-4000-8000-000000000188', 2, 'Rừng ngập mặn ven biển', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000751', '21000000-0000-4000-8000-000000000188', 3, 'Rừng lá kim ôn đới', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000752', '21000000-0000-4000-8000-000000000188', 4, 'Rừng rụng lá mùa khô (khộp)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000189', '11000000-0000-4000-8000-000000000019', 9, 'Đất feralit ở vùng đồi núi nước ta thường có màu đỏ vàng do sự tích tụ của:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000753', '21000000-0000-4000-8000-000000000189', 1, 'Hợp chất oxit sắt và nhôm (Fe2O3, Al2O3)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000754', '21000000-0000-4000-8000-000000000189', 2, 'Mùn hữu cơ giàu đạm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000755', '21000000-0000-4000-8000-000000000189', 3, 'Muối cacbonat canxi', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000756', '21000000-0000-4000-8000-000000000189', 4, 'Phù sa mới bồi đắp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000190', '11000000-0000-4000-8000-000000000019', 10, 'Thiên tai nào sau đây diễn ra thường xuyên và gây thiệt hại nặng nề nhất cho vùng ven biển miền Trung?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000757', '21000000-0000-4000-8000-000000000190', 1, 'Bão và áp thấp nhiệt đới', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000758', '21000000-0000-4000-8000-000000000190', 2, 'Động đất mạnh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000759', '21000000-0000-4000-8000-000000000190', 3, 'Sạt lở đất do băng tan', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000760', '21000000-0000-4000-8000-000000000190', 4, 'Núi lửa phun trào', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #20: DT010702 - Địa lý
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000020', 'DT010702', '00000000-0000-4000-8000-000000000007', 'Địa lý 12 - Dân cư & Các ngành Kinh tế Việt Nam (Đề 2)', 'Cơ cấu dân số, chuyển dịch cơ cấu ngành kinh tế nông nghiệp, công nghiệp, dịch vụ.', 'Địa lý', 'medium', 45, 'published', now() - interval '5 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000191', '11000000-0000-4000-8000-000000000020', 1, 'Đặc điểm dân số nổi bật của nước ta hiện nay là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000761', '21000000-0000-4000-8000-000000000191', 1, 'Quy mô dân số đông, nhiều thành phần dân tộc, cơ cấu dân số vàng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000762', '21000000-0000-4000-8000-000000000191', 2, 'Dân số ít và đang suy giảm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000763', '21000000-0000-4000-8000-000000000191', 3, 'Tỉ lệ gia tăng dân số tự nhiên rất cao trên 3%', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000764', '21000000-0000-4000-8000-000000000191', 4, 'Dân cư tập trung chủ yếu ở miền núi', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000192', '11000000-0000-4000-8000-000000000020', 2, 'Quá trình đô thị hóa ở nước ta hiện nay có đặc điểm là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000765', '21000000-0000-4000-8000-000000000192', 1, 'Tỉ lệ dân thành thị tăng nhanh nhưng còn thấp so với khu vực', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000766', '21000000-0000-4000-8000-000000000192', 2, 'Diễn ra rất sớm và đồng đều khắp các tỉnh', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000767', '21000000-0000-4000-8000-000000000192', 3, 'Không có sự phân hóa giữa các vùng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000768', '21000000-0000-4000-8000-000000000192', 4, 'Dân cư chuyển hết từ thành thị về nông thôn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000193', '11000000-0000-4000-8000-000000000020', 3, 'Xu hướng chuyển dịch cơ cấu kinh tế theo ngành ở nước ta là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000769', '21000000-0000-4000-8000-000000000193', 1, 'Giảm tỉ trọng nông-lâm-ngư nghiệp, tăng tỉ trọng công nghiệp và dịch vụ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000770', '21000000-0000-4000-8000-000000000193', 2, 'Tăng mạnh tỉ trọng nông nghiệp thuần túy', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000771', '21000000-0000-4000-8000-000000000193', 3, 'Giảm tỉ trọng ngành công nghiệp chế biến', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000772', '21000000-0000-4000-8000-000000000193', 4, 'Duy trì nguyên vẹn tỉ trọng các ngành', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000194', '11000000-0000-4000-8000-000000000020', 4, 'Hai vùng trọng điểm sản xuất lúa lớn nhất của cả nước là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000773', '21000000-0000-4000-8000-000000000194', 1, 'Đồng bằng sông Cửu Long và Đồng bằng sông Hồng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000774', '21000000-0000-4000-8000-000000000194', 2, 'Đồng bằng sông Hồng và Duyên hải miền Trung', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000775', '21000000-0000-4000-8000-000000000194', 3, 'Đồng bằng sông Cửu Long và Đông Nam Bộ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000776', '21000000-0000-4000-8000-000000000194', 4, 'Tây Nguyên và Trung du Bắc Bộ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000195', '11000000-0000-4000-8000-000000000020', 5, 'Ngành chăn nuôi lợn và gia cầm phát triển mạnh nhất ở vùng nào sau đây?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000777', '21000000-0000-4000-8000-000000000195', 1, 'Các vùng đồng bằng ven biển và gần các đô thị lớn', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000778', '21000000-0000-4000-8000-000000000195', 2, 'Vùng núi cao Tây Bắc', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000779', '21000000-0000-4000-8000-000000000195', 3, 'Vùng đồi núi Trường Sơn Nam', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000780', '21000000-0000-4000-8000-000000000195', 4, 'Vùng cao nguyên đá Hà Giang', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000196', '11000000-0000-4000-8000-000000000020', 6, 'Vùng dẫn đầu cả nước về diện tích và sản lượng cây công nghiệp lâu năm (cà phê, cao su) là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000781', '21000000-0000-4000-8000-000000000196', 1, 'Tây Nguyên và Đông Nam Bộ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000782', '21000000-0000-4000-8000-000000000196', 2, 'Đồng bằng sông Hồng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000783', '21000000-0000-4000-8000-000000000196', 3, 'Bắc Trung Bộ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000784', '21000000-0000-4000-8000-000000000196', 4, 'Trung du và miền núi Bắc Bộ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000197', '11000000-0000-4000-8000-000000000020', 7, 'Ngành công nghiệp năng lượng nào phát triển mạnh nhất ở vùng biển Bà Rịa - Vũng Tàu?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000785', '21000000-0000-4000-8000-000000000197', 1, 'Khai thác dầu mỏ và khí đốt tự nhiên', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000786', '21000000-0000-4000-8000-000000000197', 2, 'Thủy điện', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000787', '21000000-0000-4000-8000-000000000197', 3, 'Nhiệt điện than', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000788', '21000000-0000-4000-8000-000000000197', 4, 'Năng lượng gió trên bờ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000198', '11000000-0000-4000-8000-000000000020', 8, 'Đâu là tam giác tăng trưởng kinh tế trọng điểm của miền Bắc?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000789', '21000000-0000-4000-8000-000000000198', 1, 'Hà Nội - Hải Phòng - Quảng Ninh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000790', '21000000-0000-4000-8000-000000000198', 2, 'Hà Nội - Nam Định - Ninh Bình', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000791', '21000000-0000-4000-8000-000000000198', 3, 'Hà Nội - Thái Nguyên - Bắc Giang', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000792', '21000000-0000-4000-8000-000000000198', 4, 'Hải Phòng - Hải Dương - Hưng Yên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000199', '11000000-0000-4000-8000-000000000020', 9, 'Tuyến giao thông đường bộ huyết mạch xuyên suốt từ Bắc vào Nam của nước ta là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000793', '21000000-0000-4000-8000-000000000199', 1, 'Quốc lộ 1A và Đường Hồ Chí Minh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000794', '21000000-0000-4000-8000-000000000199', 2, 'Quốc lộ 5', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000795', '21000000-0000-4000-8000-000000000199', 3, 'Quốc lộ 6', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000796', '21000000-0000-4000-8000-000000000199', 4, 'Quốc lộ 2', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000200', '11000000-0000-4000-8000-000000000020', 10, 'Ngành kinh tế biển nào sau đây phát triển nhanh và đóng góp nguồn thu ngoại tệ lớn cho du lịch nước ta?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000797', '21000000-0000-4000-8000-000000000200', 1, 'Du lịch biển - đảo', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000798', '21000000-0000-4000-8000-000000000200', 2, 'Đánh bắt cá mập', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000799', '21000000-0000-4000-8000-000000000200', 3, 'Khai thác san hô làm đồ mỹ nghệ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000800', '21000000-0000-4000-8000-000000000200', 4, 'Khai thác cát vàng xuất khẩu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #21: DT010703 - Địa lý
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000021', 'DT010703', '00000000-0000-4000-8000-000000000007', 'Địa lý 12 - Địa lý Các vùng Kinh tế Trọng điểm (Đề 3)', 'Thế mạnh và hạn chế phát triển của ĐB Sông Hồng, Tây Nguyên, Đông Nam Bộ, ĐB Sông Cửu Long.', 'Địa lý', 'hard', 50, 'published', now() - interval '4 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000201', '11000000-0000-4000-8000-000000000021', 1, 'Thế mạnh tự nhiên hàng đầu để phát triển nông nghiệp ở Đồng bằng sông Hồng là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000801', '21000000-0000-4000-8000-000000000201', 1, 'Đất phù sa màu mỡ và nguồn nước dồi dào từ hệ thống sông Hồng, sông Thái Bình', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000802', '21000000-0000-4000-8000-000000000201', 2, 'Diện tích đất đỏ bazan rộng lớn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000803', '21000000-0000-4000-8000-000000000201', 3, 'Khí hậu khô hạn thích hợp trồng cây họ đậu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000804', '21000000-0000-4000-8000-000000000201', 4, 'Nhiều đồng cỏ tự nhiên quy mô lớn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000202', '11000000-0000-4000-8000-000000000021', 2, 'Khó khăn lớn nhất về tự nhiên đối với sản xuất nông nghiệp ở Tây Nguyên trong mùa khô là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000805', '21000000-0000-4000-8000-000000000202', 1, 'Thiếu nước tưới nghiêm trọng và nguy cơ cháy rừng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000806', '21000000-0000-4000-8000-000000000202', 2, 'Bão lụt thường xuyên tàn phá', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000807', '21000000-0000-4000-8000-000000000202', 3, 'Hiện tượng ngập úng trên diện rộng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000808', '21000000-0000-4000-8000-000000000202', 4, 'Rét đậm rét hại kéo dài', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000203', '11000000-0000-4000-8000-000000000021', 3, 'Cây công nghiệp lâu năm số một của vùng Tây Nguyên về diện tích và sản lượng xuất khẩu là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000809', '21000000-0000-4000-8000-000000000203', 1, 'Cây cà phê', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000810', '21000000-0000-4000-8000-000000000203', 2, 'Cây chè búp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000811', '21000000-0000-4000-8000-000000000203', 3, 'Cây dừa', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000812', '21000000-0000-4000-8000-000000000203', 4, 'Cây bông vải', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000204', '11000000-0000-4000-8000-000000000021', 4, 'Vùng kinh tế nào sau đây dẫn đầu cả nước về giá trị sản xuất công nghiệp và thu hút vốn FDI?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000813', '21000000-0000-4000-8000-000000000204', 1, 'Đông Nam Bộ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000814', '21000000-0000-4000-8000-000000000204', 2, 'Tây Nguyên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000815', '21000000-0000-4000-8000-000000000204', 3, 'Trung du và miền núi Bắc Bộ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000816', '21000000-0000-4000-8000-000000000204', 4, 'Đồng bằng sông Cửu Long', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000205', '11000000-0000-4000-8000-000000000021', 5, 'Thành phố nào là đầu tàu kinh tế, trung tâm công nghiệp, tài chính lớn nhất của vùng Đông Nam Bộ?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000817', '21000000-0000-4000-8000-000000000205', 1, 'Thành phố Hồ Chí Minh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000818', '21000000-0000-4000-8000-000000000205', 2, 'Thành phố Biên Hòa', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000819', '21000000-0000-4000-8000-000000000205', 3, 'Thành phố Thủ Dầu Một', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000820', '21000000-0000-4000-8000-000000000205', 4, 'Thành phố Vũng Tàu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000206', '11000000-0000-4000-8000-000000000021', 6, 'Thách thức lớn nhất đối với phát triển nông nghiệp ở Đồng bằng sông Cửu Long hiện nay là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000821', '21000000-0000-4000-8000-000000000206', 1, 'Xâm nhập mặn, hạn hán và sạt lở bờ sông trong mùa khô', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000822', '21000000-0000-4000-8000-000000000206', 2, 'Đất đai khô cằn sỏi đá', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000823', '21000000-0000-4000-8000-000000000206', 3, 'Bão nhiệt đới đổ bộ liên tục quanh năm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000824', '21000000-0000-4000-8000-000000000206', 4, 'Thiếu hụt trầm trọng nguồn lao động', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000207', '11000000-0000-4000-8000-000000000021', 7, 'Mô hình kinh tế thích ứng với biến đổi khí hậu đang được khuyến khích nhân rộng ở ĐBSCL là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000825', '21000000-0000-4000-8000-000000000207', 1, 'Mô hình xen canh tôm - lúa, rừng - tôm ngập mặn', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000826', '21000000-0000-4000-8000-000000000207', 2, 'Đắp đê ngăn toàn bộ nước lũ biển', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000827', '21000000-0000-4000-8000-000000000207', 3, 'Chuyển hết diện tích lúa sang trồng cao su', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000828', '21000000-0000-4000-8000-000000000207', 4, 'Khai thác tối đa nguồn nước ngầm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000208', '11000000-0000-4000-8000-000000000021', 8, 'Thế mạnh phát triển công nghiệp nổi trội của vùng Trung du và miền núi Bắc Bộ là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000829', '21000000-0000-4000-8000-000000000208', 1, 'Khai thác khoáng sản và phát triển thủy điện', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000830', '21000000-0000-4000-8000-000000000208', 2, 'Khai thác dầu khí thềm lục địa', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000831', '21000000-0000-4000-8000-000000000208', 3, 'Sản xuất hàng tiêu dùng và dệt may xuất khẩu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000832', '21000000-0000-4000-8000-000000000208', 4, 'Đóng mới tàu biển tải trọng lớn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000209', '11000000-0000-4000-8000-000000000021', 9, 'Vịnh biển nước sâu nào ở vùng Duyên hải Nam Trung Bộ có điều kiện lý tưởng xây dựng cảng trung chuyển quốc tế?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000833', '21000000-0000-4000-8000-000000000209', 1, 'Vịnh Vân Phong (Khánh Hòa)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000834', '21000000-0000-4000-8000-000000000209', 2, 'Vịnh Hạ Long (Quảng Ninh)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000835', '21000000-0000-4000-8000-000000000209', 3, 'Vịnh Diễn Châu (Nghệ An)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000836', '21000000-0000-4000-8000-000000000209', 4, 'Vịnh Gành Hào (Cà Mau)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000210', '11000000-0000-4000-8000-000000000021', 10, 'Ý nghĩa chiến lược về an ninh quốc phòng và kinh tế của các đảo, quần đảo nước ta là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000837', '21000000-0000-4000-8000-000000000210', 1, 'Khẳng định chủ quyền biển đảo, khai thác nguồn lợi hải sản và dầu khí thềm lục địa', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000838', '21000000-0000-4000-8000-000000000210', 2, 'Chỉ phục vụ xây dựng ngọn hải đăng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000839', '21000000-0000-4000-8000-000000000210', 3, 'Làm bãi thử nghiệm vũ khí', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000840', '21000000-0000-4000-8000-000000000210', 4, 'Không có giá trị kinh tế đáng kể', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #22: DT010801 - Tin học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000022', 'DT010801', '00000000-0000-4000-8000-000000000008', 'Tin học - Cơ sở Lập trình & Thuật toán (Đề 1)', 'Biến, kiểu dữ liệu, cấu trúc rẽ nhánh, vòng lặp, đệ quy và độ phức tạp thuật toán.', 'Tin học', 'medium', 45, 'published', now() - interval '3 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000211', '11000000-0000-4000-8000-000000000022', 1, 'Trong lập trình, biến (variable) là gì?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000841', '21000000-0000-4000-8000-000000000211', 1, 'Một vùng nhớ được đặt tên để lưu trữ giá trị có thể thay đổi trong chương trình', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000842', '21000000-0000-4000-8000-000000000211', 2, 'Một hằng số không bao giờ thay đổi', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000843', '21000000-0000-4000-8000-000000000211', 3, 'Một câu lệnh điều khiển luồng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000844', '21000000-0000-4000-8000-000000000211', 4, 'Một thiết bị phần cứng của máy tính', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000212', '11000000-0000-4000-8000-000000000022', 2, 'Kiểu dữ liệu nào sau đây dùng để lưu trữ các giá trị đúng/sai (True/False)?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000845', '21000000-0000-4000-8000-000000000212', 1, 'Boolean (bool)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000846', '21000000-0000-4000-8000-000000000212', 2, 'Integer (int)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000847', '21000000-0000-4000-8000-000000000212', 3, 'Float', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000848', '21000000-0000-4000-8000-000000000212', 4, 'String (str)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000213', '11000000-0000-4000-8000-000000000022', 3, 'Thuật toán tìm kiếm nhị phân (Binary Search) đòi hỏi mảng dữ liệu đầu vào phải:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000849', '21000000-0000-4000-8000-000000000213', 1, 'Đã được sắp xếp theo thứ tự', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000850', '21000000-0000-4000-8000-000000000213', 2, 'Có số lượng phần tử là số chẵn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000851', '21000000-0000-4000-8000-000000000213', 3, 'Chứa toàn số nguyên dương', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000852', '21000000-0000-4000-8000-000000000213', 4, 'Không được có giá trị trùng nhau', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000214', '11000000-0000-4000-8000-000000000022', 4, 'Độ phức tạp thời gian trung bình của thuật toán tìm kiếm nhị phân trên mảng N phần tử là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000853', '21000000-0000-4000-8000-000000000214', 1, 'O(log N)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000854', '21000000-0000-4000-8000-000000000214', 2, 'O(N)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000855', '21000000-0000-4000-8000-000000000214', 3, 'O(N²)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000856', '21000000-0000-4000-8000-000000000214', 4, 'O(1)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000215', '11000000-0000-4000-8000-000000000022', 5, 'Thuật toán sắp xếp nào sau đây có độ phức tạp trung bình tốt nhất O(N log N)?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000857', '21000000-0000-4000-8000-000000000215', 1, 'Quick Sort', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000858', '21000000-0000-4000-8000-000000000215', 2, 'Bubble Sort', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000859', '21000000-0000-4000-8000-000000000215', 3, 'Insertion Sort', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000860', '21000000-0000-4000-8000-000000000215', 4, 'Selection Sort', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000216', '11000000-0000-4000-8000-000000000022', 6, 'Hàm đệ quy (recursive function) là hàm:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000861', '21000000-0000-4000-8000-000000000216', 1, 'Tự gọi lại chính nó với điều kiện dừng xác định', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000862', '21000000-0000-4000-8000-000000000216', 2, 'Không bao giờ trả về giá trị', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000863', '21000000-0000-4000-8000-000000000216', 3, 'Chạy vô hạn không dừng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000864', '21000000-0000-4000-8000-000000000216', 4, 'Chỉ gọi các hàm thư viện có sẵn', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000217', '11000000-0000-4000-8000-000000000022', 7, 'Cấu trúc dữ liệu nào hoạt động theo nguyên lý LIFO (Last In First Out - Vào sau ra trước)?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000865', '21000000-0000-4000-8000-000000000217', 1, 'Ngăn xếp (Stack)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000866', '21000000-0000-4000-8000-000000000217', 2, 'Hàng đợi (Queue)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000867', '21000000-0000-4000-8000-000000000217', 3, 'Danh sách liên kết', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000868', '21000000-0000-4000-8000-000000000217', 4, 'Mảng một chiều', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000218', '11000000-0000-4000-8000-000000000022', 8, 'Cấu trúc dữ liệu nào hoạt động theo nguyên lý FIFO (First In First Out - Vào trước ra trước)?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000869', '21000000-0000-4000-8000-000000000218', 1, 'Hàng đợi (Queue)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000870', '21000000-0000-4000-8000-000000000218', 2, 'Ngăn xếp (Stack)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000871', '21000000-0000-4000-8000-000000000218', 3, 'Cây nhị phân', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000872', '21000000-0000-4000-8000-000000000218', 4, 'Đồ thị', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000219', '11000000-0000-4000-8000-000000000022', 9, 'Đoạn mã sau thực hiện bao nhiêu lần vòng lặp: for i in range(1, 10, 2)?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000873', '21000000-0000-4000-8000-000000000219', 1, '5 lần (các giá trị 1, 3, 5, 7, 9)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000874', '21000000-0000-4000-8000-000000000219', 2, '10 lần', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000875', '21000000-0000-4000-8000-000000000219', 3, '4 lần', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000876', '21000000-0000-4000-8000-000000000219', 4, '9 lần', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000220', '11000000-0000-4000-8000-000000000022', 10, 'Lỗi nào xảy ra khi chương trình chia một số cho 0?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000877', '21000000-0000-4000-8000-000000000220', 1, 'Runtime Error (ZeroDivisionError)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000878', '21000000-0000-4000-8000-000000000220', 2, 'Syntax Error (Lỗi cú pháp)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000879', '21000000-0000-4000-8000-000000000220', 3, 'Compilation Error', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000880', '21000000-0000-4000-8000-000000000220', 4, 'Logical Error', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #23: DT010802 - Tin học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000023', 'DT010802', '00000000-0000-4000-8000-000000000008', 'Tin học - Cơ sở Dữ liệu & Ngôn ngữ SQL (Đề 2)', 'Mô hình quan hệ, khóa chính, khóa ngoại, câu lệnh SELECT, JOIN, GROUP BY và INDEX.', 'Tin học', 'medium', 45, 'published', now() - interval '2 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000221', '11000000-0000-4000-8000-000000000023', 1, 'Trong hệ quản trị CSDL quan hệ (RDBMS), Khóa chính (Primary Key) có đặc điểm là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000881', '21000000-0000-4000-8000-000000000221', 1, 'Giá trị duy nhất và không được phép chứa giá trị NULL', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000882', '21000000-0000-4000-8000-000000000221', 2, 'Có thể trùng lặp giữa các dòng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000883', '21000000-0000-4000-8000-000000000221', 3, 'Phải là kiểu chuỗi ký tự', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000884', '21000000-0000-4000-8000-000000000221', 4, 'Chỉ được phép có 1 cột duy nhất', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000222', '11000000-0000-4000-8000-000000000023', 2, 'Khóa ngoại (Foreign Key) dùng để làm gì?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000885', '21000000-0000-4000-8000-000000000222', 1, 'Tạo liên kết tham chiếu giữa hai bảng để đảm bảo toàn vẹn dữ liệu', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000886', '21000000-0000-4000-8000-000000000222', 2, 'Tăng tốc độ truy vấn dữ liệu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000887', '21000000-0000-4000-8000-000000000222', 3, 'Bảo mật mật khẩu người dùng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000888', '21000000-0000-4000-8000-000000000222', 4, 'Tự động sao lưu cơ sở dữ liệu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000223', '11000000-0000-4000-8000-000000000023', 3, 'Câu lệnh SQL nào dùng để truy vấn dữ liệu từ bảng?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000889', '21000000-0000-4000-8000-000000000223', 1, 'SELECT', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000890', '21000000-0000-4000-8000-000000000223', 2, 'UPDATE', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000891', '21000000-0000-4000-8000-000000000223', 3, 'INSERT', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000892', '21000000-0000-4000-8000-000000000223', 4, 'DELETE', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000224', '11000000-0000-4000-8000-000000000023', 4, 'Mệnh đề nào trong SQL dùng để lọc dữ liệu theo điều kiện?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000893', '21000000-0000-4000-8000-000000000224', 1, 'WHERE', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000894', '21000000-0000-4000-8000-000000000224', 2, 'ORDER BY', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000895', '21000000-0000-4000-8000-000000000224', 3, 'GROUP BY', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000896', '21000000-0000-4000-8000-000000000224', 4, 'LIMIT', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000225', '11000000-0000-4000-8000-000000000023', 5, 'Loại JOIN nào trong SQL trả về tất cả các hàng khi có sự khớp dữ liệu ở cả hai bảng?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000897', '21000000-0000-4000-8000-000000000225', 1, 'INNER JOIN', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000898', '21000000-0000-4000-8000-000000000225', 2, 'LEFT JOIN', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000899', '21000000-0000-4000-8000-000000000225', 3, 'RIGHT JOIN', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000900', '21000000-0000-4000-8000-000000000225', 4, 'FULL JOIN', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000226', '11000000-0000-4000-8000-000000000023', 6, 'Mệnh đề GROUP BY thường đi kèm với hàm tổng hợp nào sau đây?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000901', '21000000-0000-4000-8000-000000000226', 1, 'COUNT, SUM, AVG', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000902', '21000000-0000-4000-8000-000000000226', 2, 'LIKE, BETWEEN', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000903', '21000000-0000-4000-8000-000000000226', 3, 'DROP, ALTER', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000904', '21000000-0000-4000-8000-000000000226', 4, 'CREATE, TRUNCATE', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000227', '11000000-0000-4000-8000-000000000023', 7, 'Mục đích chính của việc tạo Chỉ mục (INDEX) trong bảng cơ sở dữ liệu là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000905', '21000000-0000-4000-8000-000000000227', 1, 'Tăng tốc độ tìm kiếm và lọc dữ liệu của các câu lệnh SELECT', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000906', '21000000-0000-4000-8000-000000000227', 2, 'Tiết kiệm dung lượng ổ cứng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000907', '21000000-0000-4000-8000-000000000227', 3, 'Mã hóa dữ liệu nhạy cảm', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000908', '21000000-0000-4000-8000-000000000227', 4, 'Xóa bớt các dòng trùng lặp', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000228', '11000000-0000-4000-8000-000000000023', 8, 'Lệnh nào trong SQL dùng để xóa toàn bộ dữ liệu trong bảng một cách nhanh chóng mà không xóa cấu trúc bảng?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000909', '21000000-0000-4000-8000-000000000228', 1, 'TRUNCATE TABLE', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000910', '21000000-0000-4000-8000-000000000228', 2, 'DROP TABLE', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000911', '21000000-0000-4000-8000-000000000228', 3, 'ALTER TABLE', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000912', '21000000-0000-4000-8000-000000000228', 4, 'REMOVE TABLE', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000229', '11000000-0000-4000-8000-000000000023', 9, 'Tính chất ACID trong giao dịch (Transaction) của CSDL đại diện cho:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000913', '21000000-0000-4000-8000-000000000229', 1, 'Atomicity, Consistency, Isolation, Durability', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000914', '21000000-0000-4000-8000-000000000229', 2, 'Access, Control, Index, Data', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000915', '21000000-0000-4000-8000-000000000229', 3, 'Auto, Cache, Insert, Delete', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000916', '21000000-0000-4000-8000-000000000229', 4, 'Async, Connect, Interface, Database', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000230', '11000000-0000-4000-8000-000000000023', 10, 'Định dạng dữ liệu JSONB trong PostgreSQL có ưu điểm vượt trội gì so với JSON thông thường?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000917', '21000000-0000-4000-8000-000000000230', 1, 'Được lưu dưới dạng nhị phân đã phân tích cú pháp, hỗ trợ đánh chỉ mục GIN truy vấn cực nhanh', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000918', '21000000-0000-4000-8000-000000000230', 2, 'Tốn ít dung lượng hơn 10 lần', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000919', '21000000-0000-4000-8000-000000000230', 3, 'Tự động đổi tên các cột', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000920', '21000000-0000-4000-8000-000000000230', 4, 'Chỉ chứa được số nguyên', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- Exam #24: DT010803 - Tin học
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at)
values ('11000000-0000-4000-8000-000000000024', 'DT010803', '00000000-0000-4000-8000-000000000008', 'Tin học - Mạng máy tính & An toàn Thông tin (Đề 3)', 'Mô hình OSI/TCP-IP, giao thức HTTP/HTTPS, DNS, mã hóa đối xứng/bất đối xứng và tường lửa.', 'Tin học', 'hard', 50, 'published', now() - interval '1 days')
on conflict (code) do update set title = excluded.title, description = excluded.description, subject = excluded.subject, duration_minutes = excluded.duration_minutes, status = 'published';
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000231', '11000000-0000-4000-8000-000000000024', 1, 'Mô hình tham chiếu OSI chuẩn bao gồm bao nhiêu tầng?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000921', '21000000-0000-4000-8000-000000000231', 1, '7 tầng', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000922', '21000000-0000-4000-8000-000000000231', 2, '4 tầng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000923', '21000000-0000-4000-8000-000000000231', 3, '5 tầng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000924', '21000000-0000-4000-8000-000000000231', 4, '6 tầng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000232', '11000000-0000-4000-8000-000000000024', 2, 'Giao thức nào sau đây hoạt động ở tầng Ứng dụng (Application Layer)?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000925', '21000000-0000-4000-8000-000000000232', 1, 'HTTP / HTTPS', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000926', '21000000-0000-4000-8000-000000000232', 2, 'TCP', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000927', '21000000-0000-4000-8000-000000000232', 3, 'IP', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000928', '21000000-0000-4000-8000-000000000232', 4, 'Ethernet', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000233', '11000000-0000-4000-8000-000000000024', 3, 'Hệ thống phân giải tên miền (DNS) có nhiệm vụ chính là:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000929', '21000000-0000-4000-8000-000000000233', 1, 'Chuyển đổi tên miền (domain) thành địa chỉ IP máy chủ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000930', '21000000-0000-4000-8000-000000000233', 2, 'Mã hóa đường truyền Internet', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000931', '21000000-0000-4000-8000-000000000233', 3, 'Cấp phát địa chỉ IP tự động cho máy tính', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000932', '21000000-0000-4000-8000-000000000233', 4, 'Chặn các trang web độc hại', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000234', '11000000-0000-4000-8000-000000000024', 4, 'Giao thức HTTPS khác biệt cơ bản với HTTP nhờ điều gì?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000933', '21000000-0000-4000-8000-000000000234', 1, 'HTTPS được mã hóa an toàn bằng giao thức TLS/SSL', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000934', '21000000-0000-4000-8000-000000000234', 2, 'HTTPS có tốc độ tải nhanh hơn gấp 10 lần', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000935', '21000000-0000-4000-8000-000000000234', 3, 'HTTPS không cần thông qua mạng Internet', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000936', '21000000-0000-4000-8000-000000000234', 4, 'HTTPS chỉ chạy trên trình duyệt di động', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000235', '11000000-0000-4000-8000-000000000024', 5, 'Địa chỉ IPv4 tiêu chuẩn có độ dài bao nhiêu bit?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000937', '21000000-0000-4000-8000-000000000235', 1, '32 bit (gồm 4 octet)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000938', '21000000-0000-4000-8000-000000000235', 2, '64 bit', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000939', '21000000-0000-4000-8000-000000000235', 3, '128 bit', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000940', '21000000-0000-4000-8000-000000000235', 4, '16 bit', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000236', '11000000-0000-4000-8000-000000000024', 6, 'Mã hóa bất đối xứng (Asymmetric Encryption) sử dụng cặp khóa nào?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000941', '21000000-0000-4000-8000-000000000236', 1, 'Khóa công khai (Public Key) và Khóa bí mật (Private Key)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000942', '21000000-0000-4000-8000-000000000236', 2, 'Một khóa duy nhất dùng chung', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000943', '21000000-0000-4000-8000-000000000236', 3, 'Hai khóa công khai giống hệt nhau', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000944', '21000000-0000-4000-8000-000000000236', 4, 'Khóa mã hóa ngẫu nhiên không thể giải mã', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000237', '11000000-0000-4000-8000-000000000024', 7, 'Tường lửa (Firewall) trong hệ thống mạng máy tính có chức năng gì?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000945', '21000000-0000-4000-8000-000000000237', 1, 'Kiểm soát và lọc lưu lượng mạng ra vào dựa trên các quy tắc bảo mật xác định', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000946', '21000000-0000-4000-8000-000000000237', 2, 'Diệt sạch virus trên ổ cứng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000947', '21000000-0000-4000-8000-000000000237', 3, 'Tăng tốc độ băng thông đường truyền', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000948', '21000000-0000-4000-8000-000000000237', 4, 'Thay thế card mạng của máy tính', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000238', '11000000-0000-4000-8000-000000000024', 8, 'Cuộc tấn công từ chối dịch vụ phân tán (DDoS) nhằm mục đích gì?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000949', '21000000-0000-4000-8000-000000000238', 1, 'Làm tràn ngập lưu lượng khiến máy chủ bị quá tải và ngưng trệ dịch vụ', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000950', '21000000-0000-4000-8000-000000000238', 2, 'Đánh cắp mật khẩu ngân hàng của người dùng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000951', '21000000-0000-4000-8000-000000000238', 3, 'Chèn mã độc tống tiền vào ổ cứng', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000952', '21000000-0000-4000-8000-000000000238', 4, 'Sửa đổi nội dung cơ sở dữ liệu', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000239', '11000000-0000-4000-8000-000000000024', 9, 'Cơ chế xác thực đa yếu tố (MFA / 2FA) giúp tăng cường bảo mật tài khoản bằng cách:', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000953', '21000000-0000-4000-8000-000000000239', 1, 'Yêu cầu ít nhất hai bằng chứng xác thực khác nhau (ví dụ: mật khẩu + mã OTP)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000954', '21000000-0000-4000-8000-000000000239', 2, 'Yêu cầu đổi mật khẩu 5 phút một lần', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000955', '21000000-0000-4000-8000-000000000239', 3, 'Chỉ cho phép đăng nhập từ một địa chỉ IP duy nhất', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000956', '21000000-0000-4000-8000-000000000239', 4, 'Tự động ghi nhớ mật khẩu trên máy tính lạ', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.questions (id, exam_id, position, body, points)
values ('21000000-0000-4000-8000-000000000240', '11000000-0000-4000-8000-000000000024', 10, 'Giao thức mạng nào đảm bảo việc truyền tải gói tin tin cậy, có xác nhận bắt tay 3 bước (3-way handshake)?', 1.00)
on conflict (exam_id, position) do update set body = excluded.body, points = excluded.points;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000957', '21000000-0000-4000-8000-000000000240', 1, 'TCP (Transmission Control Protocol)', true)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000958', '21000000-0000-4000-8000-000000000240', 2, 'UDP (User Datagram Protocol)', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000959', '21000000-0000-4000-8000-000000000240', 3, 'ICMP', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;
insert into public.question_options (id, question_id, position, body, is_correct)
values ('31000000-0000-4000-8000-000000000960', '21000000-0000-4000-8000-000000000240', 4, 'ARP', false)
on conflict (question_id, position) do update set body = excluded.body, is_correct = excluded.is_correct;

-- ===========================================================================
-- 4. HYDRATE SNAPSHOT PAYLOADS FOR ALL EXAMS
-- ===========================================================================
do $$
declare
  r record;
begin
  for r in select id from public.exams loop
    perform public.fn_rebuild_exam_snapshot(r.id);
  end loop;
end;
$$;
