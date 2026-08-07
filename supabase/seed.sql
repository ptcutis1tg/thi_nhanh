-- Demo catalog only. These rows are safe to publish; no credential or plain-text
-- room password is included. Apply after 202608070001_exam_schema.sql.

insert into public.teachers (id, display_name, bio) values
  ('00000000-0000-4000-8000-000000000001', 'Thầy Nguyễn Văn A', 'Giáo viên Toán THPT.'),
  ('00000000-0000-4000-8000-000000000002', 'Cô Lê Thị B', 'Giáo viên Vật lý THPT.'),
  ('00000000-0000-4000-8000-000000000003', 'Cô Trần Thị B', 'Giáo viên Tiếng Anh và IELTS.'),
  ('00000000-0000-4000-8000-000000000004', 'Cô Phạm Thị D', 'Giáo viên Hóa học THPT.');

insert into public.exams (id, code, teacher_id, title, description, subject, difficulty, duration_minutes, status, published_at) values
  ('10000000-0000-4000-8000-000000000001', 'DT100001', '00000000-0000-4000-8000-000000000001', 'Đề thi thử THPT Quốc gia môn Toán 2024', 'Luyện tập hàm số, mũ - logarit và xác suất.', 'Toán học', 'medium', 90, 'published', now()),
  ('10000000-0000-4000-8000-000000000002', 'DT100002', '00000000-0000-4000-8000-000000000002', 'Ôn tập Dao động cơ học - Vật lý 12', 'Củng cố các dạng bài dao động điều hòa.', 'Vật lý', 'medium', 50, 'published', now()),
  ('10000000-0000-4000-8000-000000000003', 'DT100003', '00000000-0000-4000-8000-000000000003', 'IELTS Mock Test - Listening & Reading', 'Đề luyện kỹ năng nghe và đọc.', 'Tiếng Anh', 'hard', 60, 'published', now()),
  ('10000000-0000-4000-8000-000000000004', 'DT100004', '00000000-0000-4000-8000-000000000004', 'Kiểm tra Hóa hữu cơ - Lớp 11', 'Ôn tập ankan, anken và ankin.', 'Hóa học', 'easy', 45, 'published', now());

insert into public.questions (id, exam_id, position, body, explanation, points) values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 1, 'Đạo hàm của f(x) = x³ là gì?', 'Áp dụng quy tắc đạo hàm lũy thừa.', 1),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 2, 'Xác suất của biến cố chắc chắn bằng bao nhiêu?', 'Biến cố chắc chắn luôn xảy ra.', 1),
  ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 1, 'Chu kì của con lắc lò xo phụ thuộc vào đại lượng nào?', 'T = 2π√(m/k).', 1),
  ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000002', 2, 'Trong dao động điều hòa, vận tốc đạt cực đại khi nào?', 'Vận tốc có độ lớn cực đại tại vị trí cân bằng.', 1),
  ('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000003', 1, 'Choose the correct word: She ___ to school every day.', 'Thì hiện tại đơn với chủ ngữ she.', 1),
  ('20000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000003', 2, 'Which word is closest in meaning to “essential”?', 'Essential means necessary.', 1),
  ('20000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000004', 1, 'Công thức tổng quát của ankan là gì?', 'Ankan mạch hở có công thức CnH2n+2.', 1),
  ('20000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000004', 2, 'Chất nào sau đây làm mất màu dung dịch brom?', 'Anken có liên kết đôi C=C.', 1);

insert into public.question_options (question_id, position, body, is_correct) values
  ('20000000-0000-4000-8000-000000000001', 1, 'x²', false), ('20000000-0000-4000-8000-000000000001', 2, '3x²', true), ('20000000-0000-4000-8000-000000000001', 3, '3x', false), ('20000000-0000-4000-8000-000000000001', 4, 'x⁴/4', false),
  ('20000000-0000-4000-8000-000000000002', 1, '0', false), ('20000000-0000-4000-8000-000000000002', 2, '1/2', false), ('20000000-0000-4000-8000-000000000002', 3, '1', true), ('20000000-0000-4000-8000-000000000002', 4, 'Không xác định', false),
  ('20000000-0000-4000-8000-000000000003', 1, 'Biên độ và pha ban đầu', false), ('20000000-0000-4000-8000-000000000003', 2, 'Khối lượng và độ cứng lò xo', true), ('20000000-0000-4000-8000-000000000003', 3, 'Li độ ban đầu', false), ('20000000-0000-4000-8000-000000000003', 4, 'Thời điểm khảo sát', false),
  ('20000000-0000-4000-8000-000000000004', 1, 'Ở biên', false), ('20000000-0000-4000-8000-000000000004', 2, 'Ở vị trí cân bằng', true), ('20000000-0000-4000-8000-000000000004', 3, 'Khi gia tốc cực đại', false), ('20000000-0000-4000-8000-000000000004', 4, 'Mọi vị trí', false),
  ('20000000-0000-4000-8000-000000000005', 1, 'go', false), ('20000000-0000-4000-8000-000000000005', 2, 'goes', true), ('20000000-0000-4000-8000-000000000005', 3, 'going', false), ('20000000-0000-4000-8000-000000000005', 4, 'gone', false),
  ('20000000-0000-4000-8000-000000000006', 1, 'optional', false), ('20000000-0000-4000-8000-000000000006', 2, 'necessary', true), ('20000000-0000-4000-8000-000000000006', 3, 'ordinary', false), ('20000000-0000-4000-8000-000000000006', 4, 'temporary', false),
  ('20000000-0000-4000-8000-000000000007', 1, 'CnH2n', false), ('20000000-0000-4000-8000-000000000007', 2, 'CnH2n+2', true), ('20000000-0000-4000-8000-000000000007', 3, 'CnH2n-2', false), ('20000000-0000-4000-8000-000000000007', 4, 'CnH2n-6', false),
  ('20000000-0000-4000-8000-000000000008', 1, 'Metan', false), ('20000000-0000-4000-8000-000000000008', 2, 'Etan', false), ('20000000-0000-4000-8000-000000000008', 3, 'Eten', true), ('20000000-0000-4000-8000-000000000008', 4, 'Benzen', false);

insert into public.rooms (code, exam_id, teacher_id, name, password_hash, status, max_participants) values
  ('PT200001', '10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000003', 'IELTS Mock Test - Ca tối', null, 'waiting', 100),
  ('PT200002', '10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002', 'Ôn tập Dao động cơ học - Lớp 12A1', null, 'waiting', 45);
