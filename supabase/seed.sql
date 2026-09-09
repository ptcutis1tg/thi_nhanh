-- Demo catalog and sample data for Thi Nhanh.
-- Apply after 202608070001_exam_schema.sql.

-- 1. Teachers
insert into public.teachers (id, display_name, bio) values
  ('00000000-0000-4000-8000-000000000001', 'Thầy Nguyễn Văn A', 'Giáo viên Toán THPT Chuyên.'),
  ('00000000-0000-4000-8000-000000000002', 'Cô Lê Thị B', 'Giáo viên Vật lý THPT Quốc gia.'),
  ('00000000-0000-4000-8000-000000000003', 'Cô Trần Thị C', 'Giáo viên Tiếng Anh & IELTS 8.5.'),
  ('00000000-0000-4000-8000-000000000004', 'Cô Phạm Thị D', 'Giáo viên Hóa học THPT.');

-- 2. Exams
insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at) values
  ('10000000-0000-4000-8000-000000000001', 'DT100001', '00000000-0000-4000-8000-000000000001', 'Đề thi thử THPT Quốc gia môn Toán 2024', 'Luyện tập hàm số, mũ - logarit và xác suất.', 'Toán học', 'medium', 90, 'published', now() - interval '10 days'),
  ('10000000-0000-4000-8000-000000000002', 'DT100002', '00000000-0000-4000-8000-000000000002', 'Ôn tập Dao động cơ học - Vật lý 12', 'Củng cố các dạng bài dao động điều hòa.', 'Vật lý', 'medium', 50, 'published', now() - interval '7 days'),
  ('10000000-0000-4000-8000-000000000003', 'DT100003', '00000000-0000-4000-8000-000000000003', 'IELTS Mock Test - Listening & Reading', 'Đề luyện kỹ năng nghe và đọc.', 'Tiếng Anh', 'hard', 60, 'published', now() - interval '5 days'),
  ('10000000-0000-4000-8000-000000000004', 'DT100004', '00000000-0000-4000-8000-000000000004', 'Kiểm tra Hóa hữu cơ - Lớp 11', 'Ôn tập ankan, anken và ankin.', 'Hóa học', 'easy', 45, 'published', now() - interval '3 days'),
  ('10000000-0000-4000-8000-000000000005', 'DT100005', '00000000-0000-4000-8000-000000000001', 'Đề luyện Chuyên Toán - Đại số & Hình học', 'Các bài toán nâng cao luyện HSG.', 'Toán học', 'hard', 120, 'published', now() - interval '2 days'),
  ('10000000-0000-4000-8000-000000000006', 'DT100006', '00000000-0000-4000-8000-000000000002', 'Kiểm tra Điện xoay chiều - Vật lý 12', 'Tổng hợp kiến thức mạch RLC nối tiếp.', 'Vật lý', 'medium', 45, 'published', now() - interval '1 day');

-- 3. Questions
insert into public.questions (id, exam_id, position, body, explanation, points) values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 1, 'Đạo hàm của f(x) = x³ là gì?', 'Áp dụng quy tắc đạo hàm lũy thừa: (x^n)'' = n*x^(n-1).', 1),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 2, 'Xác suất của biến cố chắc chắn bằng bao nhiêu?', 'Biến cố chắc chắn luôn có xác suất P = 1.', 1),
  ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 1, 'Chu kì của con lắc lò xo phụ thuộc vào đại lượng nào?', 'Công thức chu kì T = 2π√(m/k).', 1),
  ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000002', 2, 'Trong dao động điều hòa, vận tốc đạt cực đại khi nào?', 'Vận tốc đạt giá trị cực đại khi vật đi qua vị trí cân bằng theo chiều dương.', 1),
  ('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000003', 1, 'Choose the correct option: She ___ to school every day.', 'Thì hiện tại đơn với ngôi thứ 3 số ít.', 1),
  ('20000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000003', 2, 'Which word is closest in meaning to “essential”?', 'Essential nghĩa là cần thiết, thiết yếu (necessary).', 1),
  ('20000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000004', 1, 'Công thức tổng quát của ankan là gì?', 'Ankan mạch hở có công thức chung CnH2n+2 (n >= 1).', 1),
  ('20000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000004', 2, 'Chất nào sau đây làm mất màu dung dịch brom?', 'Anken có liên kết đôi C=C phản ứng cộng với brom.', 1);

-- 4. Question Options
insert into public.question_options (question_id, position, body, is_correct) values
  ('20000000-0000-4000-8000-000000000001', 1, 'x²', false), ('20000000-0000-4000-8000-000000000001', 2, '3x²', true), ('20000000-0000-4000-8000-000000000001', 3, '3x', false), ('20000000-0000-4000-8000-000000000001', 4, 'x⁴/4', false),
  ('20000000-0000-4000-8000-000000000002', 1, '0', false), ('20000000-0000-4000-8000-000000000002', 2, '1/2', false), ('20000000-0000-4000-8000-000000000002', 3, '1', true), ('20000000-0000-4000-8000-000000000002', 4, 'Không xác định', false),
  ('20000000-0000-4000-8000-000000000003', 1, 'Biên độ và pha ban đầu', false), ('20000000-0000-4000-8000-000000000003', 2, 'Khối lượng và độ cứng lò xo', true), ('20000000-0000-4000-8000-000000000003', 3, 'Li độ ban đầu', false), ('20000000-0000-4000-8000-000000000003', 4, 'Thời điểm khảo sát', false),
  ('20000000-0000-4000-8000-000000000004', 1, 'Ở biên', false), ('20000000-0000-4000-8000-000000000004', 2, 'Ở vị trí cân bằng', true), ('20000000-0000-4000-8000-000000000004', 3, 'Khi gia tốc cực đại', false), ('20000000-0000-4000-8000-000000000004', 4, 'Mọi vị trí', false),
  ('20000000-0000-4000-8000-000000000005', 1, 'go', false), ('20000000-0000-4000-8000-000000000005', 2, 'goes', true), ('20000000-0000-4000-8000-000000000005', 3, 'going', false), ('20000000-0000-4000-8000-000000000005', 4, 'gone', false),
  ('20000000-0000-4000-8000-000000000006', 1, 'optional', false), ('20000000-0000-4000-8000-000000000006', 2, 'necessary', true), ('20000000-0000-4000-8000-000000000006', 3, 'ordinary', false), ('20000000-0000-4000-8000-000000000006', 4, 'temporary', false),
  ('20000000-0000-4000-8000-000000000007', 1, 'CnH2n', false), ('20000000-0000-4000-8000-000000000007', 2, 'CnH2n+2', true), ('20000000-0000-4000-8000-000000000007', 3, 'CnH2n-2', false), ('20000000-0000-4000-8000-000000000007', 4, 'CnH2n-6', false),
  ('20000000-0000-4000-8000-000000000008', 1, 'Metan', false), ('20000000-0000-4000-8000-000000000008', 2, 'Etan', false), ('20000000-0000-4000-8000-000000000008', 3, 'Eten', true), ('20000000-0000-4000-8000-000000000008', 4, 'Benzen', false);

-- 5. Exam Rooms
insert into public.rooms (id, code, exam_id, teacher_id, name, password_hash, status, max_participants, scheduled_start_at) values
  ('30000000-0000-4000-8000-000000000001', 'PT892341', '10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'Kiểm tra giữa kỳ môn Toán Học 10 - Lớp 10A1', null, 'waiting', 50, now() + interval '10 minutes'),
  ('30000000-0000-4000-8000-000000000002', 'PT200001', '10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000003', 'IELTS Mock Test - Ca tối hội trường A', null, 'live', 100, now() - interval '15 minutes'),
  ('30000000-0000-4000-8000-000000000003', 'PT200002', '10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002', 'Ôn tập Dao động cơ học - Lớp 12A1', null, 'waiting', 45, now() + interval '1 hour'),
  ('30000000-0000-4000-8000-000000000004', 'PT100001', '10000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000004', 'Kiểm tra Hóa hữu cơ - Lớp 11B2', null, 'closed', 40, now() - interval '2 days');

-- 6. Student Attempts & Results
insert into public.attempts (id, exam_id, room_id, guest_name, status, started_at, submitted_at, score) values
  ('40000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Trần Tuấn Anh', 'submitted', now() - interval '2 days', now() - interval '2 days' + interval '40 minutes', 9.5),
  ('40000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Lê Thị Bích', 'submitted', now() - interval '2 days', now() - interval '2 days' + interval '42 minutes', 8.8),
  ('40000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Phạm Văn Cường', 'submitted', now() - interval '2 days', now() - interval '2 days' + interval '45 minutes', 7.5),
  ('40000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000003', 'Nguyễn Thị Hoa', 'submitted', now() - interval '1 day', now() - interval '1 day' + interval '30 minutes', 10.0),
  ('40000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000002', 'Bùi Hoàng Long', 'submitted', now() - interval '5 hours', now() - interval '5 hours' + interval '55 minutes', 9.0),
  ('40000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000004', '30000000-0000-4000-8000-000000000004', 'Đỗ Minh Anh', 'submitted', now() - interval '2 days', now() - interval '2 days' + interval '35 minutes', 8.0);

