# Bản Thiết Kế Kiến Trúc: Lưu Đề Thi Cộng Đồng & Xem Chi Tiết Câu Hỏi Với Quick-Jump Navigator

- **Ngày ban hành:** 2026-10-09
- **Phiên bản:** 1.0.0
- **Trạng thái:** Bản thảo đã thống nhất (Pending User Review)
- **Tác giả:** Antigravity Pairing Assistant & User

---

## 1. Bối Cảnh & Mục Tiêu Nghiệp Vụ

### 1.1. Vấn đề thực tế
- Trước đây, khi một giáo viên hoặc người tổ chức thi muốn mở phòng thi trực tiếp (`CreateRoomScreen`), hệ thống chỉ cho phép chọn từ những đề thi do chính tài khoản đó tạo ra (`e.teacher_id = public.ensure_current_teacher()`).
- Khi giáo viên tìm kiếm trên trang Tìm kiếm (`SearchScreen`) và thấy một đề thi công khai rất hay của đồng nghiệp hoặc cộng đồng, họ không có cách nào để sử dụng đề thi đó tổ chức thi cho học sinh của mình.
- Màn hình Chi tiết đề thi (`ExamDetailScreen`) trước đây chỉ hiển thị tóm tắt thông số và nút "Bắt đầu tự luyện", thiếu hoàn toàn khả năng xem trước nội dung các câu hỏi, đáp án và lời giải chi tiết trước khi quyết định lưu hoặc làm bài.

### 1.2. Giải pháp kiến trúc giải quyết mâu thuẫn trùng lặp (Zero Duplication)
- **Mâu thuẫn:** Nếu nhân bản (clone) đề thi và xuất bản ngay thành đề của người lưu, trang Tìm kiếm công khai sẽ bị tràn ngập các bản sao trùng lặp 100% nội dung. Nếu nhân bản thành bản nháp (draft), người dùng lại không thể mở phòng thi được vì quy tắc phòng thi yêu cầu đề `published`.
- **Giải pháp tối ưu:** Sử dụng **cơ chế Lưu tham chiếu có quyền Host (Host-Authorized Bookmark)** qua bảng `public.saved_exams`:
  - Không nhân bản dữ liệu, không sinh đề rác trên trang Tìm kiếm.
  - Người dùng bấm "Lưu đề" sẽ được cấp quyền hợp pháp để chọn đề đó trong danh sách Tạo phòng thi (`CreateRoomScreen`).
  - Tác giả gốc của đề thi vẫn được ghi nhận rõ ràng, minh bạch bản quyền.

---

## 2. Thiết Kế Cơ Sở Dữ Liệu & Phân Quyền Backend (Supabase)

### 2.1. Migration Bảng `public.saved_exams`
```sql
-- Migration: 202610090001_saved_exams_and_host_permission.sql

create table if not exists public.saved_exams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, exam_id)
);

alter table public.saved_exams enable row level security;

-- RLS: Người dùng có toàn quyền xem, thêm, xóa đề đã lưu của chính mình
create policy "users can manage their own saved exams"
on public.saved_exams
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Cho phép đọc đề đã lưu công khai nếu cần
create policy "users can view their saved exams"
on public.saved_exams
for select
to authenticated
using (auth.uid() = user_id);
```

### 2.2. Nâng Cấp Hàm Tạo Phòng Thi (`public.create_teacher_room`)
Mở rộng điều kiện kiểm tra đề hợp lệ trong `public.create_teacher_room`:
```sql
create or replace function public.create_teacher_room(
  p_exam_id uuid, p_name text, p_password text default null, p_max_participants integer default 50
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_teacher_id uuid; v_room public.rooms;
begin
  v_teacher_id := public.ensure_current_teacher();
  if char_length(trim(p_name)) < 3 then raise exception 'Room name must have at least 3 characters'; end if;
  if p_max_participants not between 1 and 1000 then raise exception 'Participant limit must be between 1 and 1000'; end if;
  
  -- Cho phép đề do chính giáo viên tạo HOẶC đề đã được giáo viên lưu về kho cá nhân
  if not exists (
    select 1 from public.exams e
    where e.id = p_exam_id and e.status = 'published'
    and (
      e.teacher_id = v_teacher_id
      or exists (
        select 1 from public.saved_exams se
        where se.exam_id = e.id and se.user_id = auth.uid()
      )
    )
  ) then
    raise exception 'Chỉ có thể tạo phòng từ đề đã xuất bản của bạn hoặc đề bạn đã lưu từ cộng đồng';
  end if;

  insert into public.rooms (code, exam_id, teacher_id, name, password_hash, max_participants)
  values (
    public.next_room_code(), p_exam_id, v_teacher_id, trim(p_name),
    case when nullif(trim(coalesce(p_password, '')), '') is null then null else extensions.crypt(p_password, extensions.gen_salt('bf')) end,
    p_max_participants
  ) returning * into v_room;
  
  return jsonb_build_object('id', v_room.id, 'code', v_room.code, 'name', v_room.name, 'status', v_room.status);
end;
$$;
```

---

## 3. Thiết Kế Tầng Dịch Vụ & Repository (`lib/core/repositories/`)

### 3.1. `SavedExamRepository`
- File: `lib/core/repositories/saved_exam_repository.dart`
- Phương thức chính:
  - `Future<bool> isExamSaved(String examId)`: Kiểm tra xem đề thi đã được người dùng lưu hay chưa.
  - `Future<bool> toggleSaveExam(String examId)`: Lưu hoặc Hủy lưu đề thi. Trả về trạng thái `isSaved` sau khi toggle.
  - `Future<List<TeacherExamSummary>> getSavedExams()`: Lấy danh sách tóm tắt toàn bộ đề thi đã lưu của người dùng (kèm tác giả, số câu, thời lượng).
  - Có cơ chế bộ nhớ đệm cục bộ (`Set<String> _cachedSavedIds`) và fallback offline an toàn khi chạy unit tests.

### 3.2. Cập nhật `TeacherExamRepository` & `CreateRoomScreen`
- Cung cấp phương thức `Future<List<TeacherExamSummary>> allAvailableForRoom()` kết hợp cả `summaries()` (đề của tôi) và `getSavedExams()` (đề đã lưu).

---

## 4. Thiết Kế Giao Diện Chi Tiết Đề Thi (`ExamDetailScreen`)

### 4.1. Phần 1: Hero & Thao Tác Tổng Quan (Phần thấy đầu tiên)
- **Thẻ Tóm Tắt Đề Thi (`_ExamSummaryCard`):**
  - Tiêu đề đề thi cỡ lớn nổi bật, thẻ môn học (`AppTheme.primary`), mã đề `#DTxxxxxx`, số câu hỏi, thời gian làm bài, tên tác giả giáo viên.
- **Bảng Thao Tác Hành Động (`_ActionPanel`):**
  - **Nút 1 — "Bắt đầu tự luyện"** (Nút Primary màu tím): Bắt đầu làm bài thi tự do qua `AssessmentRepository.beginPractice()`.
  - **Nút 2 — "Thêm vào yêu thích"** (Nút Outlined trái tim): Đánh dấu yêu thích bài thi.
  - **Nút 3 — "Lưu đề" / "Đã lưu"** (Nút Outlined / Solid biểu tượng Bookmark):
    - Khi chưa lưu: Hiển thị icon `bookmark_border_rounded`, chữ *"Lưu đề"*. Bấm vào sẽ gọi `SavedExamRepository.toggleSaveExam()`, thông báo SnackBar *"Đã lưu đề vào kho cá nhân. Bạn có thể dùng đề này để tạo phòng thi."*
    - Khi đã lưu: Hiển thị icon `bookmark_rounded` màu tím sáng, chữ *"Đã lưu"*. Bấm vào sẽ hỏi hủy lưu.
  - Ô nhập mã PIN phòng thi nhanh (`Nhập mã phòng do giáo viên cung cấp...`) dành cho học sinh.
- **Chỉ Báo Cuộn Chi Tiết Ở Đáy Màn Hình Hero:**
  - Nút biểu tượng mũi tên tròn hướng xuống (`Icons.keyboard_arrow_down_rounded`) với hiệu ứng nảy nhẹ nhàng (Tween Animation).
  - Dòng mô tả nhỏ: *"Xem chi tiết câu hỏi & đáp án"*.
  - Khi người dùng click vào: Tự động cuộn mượt (Smooth Scroll qua `_scrollController.animateTo(...)`) xuống khu vực câu hỏi bên dưới.

### 4.2. Phần 2: Vùng Xem Chi Tiết Câu Hỏi & Bảng Điều Hướng Jump Nhanh
- **Thanh Công Cụ Trên Cùng:**
  - Dòng tiêu đề: `📝 Danh Sách Câu Hỏi (${_questions.length} câu)`.
  - **Công Tắc Toggle:** `Switch` hoặc `FilterChip` *"Hiện đáp án & giải thích"* (mặc định bật, người dùng có thể tắt đi nếu muốn tự giải thử).
- **Cột Trái (Danh Sách Câu Hỏi Chi Tiết):**
  - Mỗi câu hỏi hiển thị dạng Card phẳng viền mỏng `AppTheme.border`, bo góc 16px:
    - Tiêu đề câu: `Câu 1 (0.25 điểm)`.
    - Thân câu hỏi: Hỗ trợ văn bản và công thức toán học (`VisualMathBlockWidget` hoặc `flutter_math_fork`).
    - 4 Phương án A, B, C, D:
      - Khi Toggle bật: Đáp án đúng được tô nền xanh nhạt (`Color(0xFFE8F5E9)`), viền xanh (`AppTheme.success`), icon tích tròn `check_circle_rounded` màu xanh.
      - Các phương án khác hiển thị màu chữ trung tính rõ ràng.
    - Khung giải thích chi tiết: Nền tím lavender nhẹ (`AppTheme.surfaceLavender`), viền bo 10px, biểu tượng bóng đèn `lightbulb_outline_rounded`, giải thích cặn kẽ từng bước.
- **Cột Phải / Sidebar (Quick-Jump Question Navigator):**
  - Một bảng con nhỏ đặt bên cạnh danh sách câu hỏi:
    - Tiêu đề: *"Mục lục câu hỏi"*.
    - Lưới số câu hỏi (Lưới 4-5 cột): Các ô số `1`, `2`, `3` ... `N`.
    - Khi click vào bất kỳ số câu nào: Màn hình tự động cuộn chính xác đến câu hỏi đó bằng `Scrollable.ensureVisible` với `GlobalKey` tương ứng của từng câu hỏi.
    - Thiết kế co giãn linh hoạt: Trên Desktop hiển thị cố định ở cột phải; trên Mobile hiển thị dạng thanh cuộn ngang (Horizontal Strip) ghim trên đỉnh danh sách câu hỏi.

---

## 5. Thiết Kế Điểm Chạm Giao Diện Tại Các Màn Hình Khác

### 5.1. Thẻ Tìm Kiếm (`SearchScreen`)
- Trên mỗi thẻ kết quả đề thi trong `_ResultsGrid`:
  - Thêm nút Icon Bookmark tròn nhỏ ở góc trên bên phải của thẻ.
  - Bấm vào sẽ lưu nhanh đề về kho cá nhân chỉ với 1 chạm (hiển thị trạng thái đã lưu ngay lập tức mà không cần mở màn hình chi tiết).

### 5.2. Màn Hình Tạo Phòng Thi (`CreateRoomScreen`)
- Cung cấp thanh lọc Tab 3 lựa chọn phía trên danh sách chọn đề thi:
  - `Tất cả` | `Đề của tôi` | `Đề đã lưu từ cộng đồng`.
- Các đề được lưu từ cộng đồng hiển thị huy hiệu *"Đã lưu"* kèm tên giáo viên tác giả gốc.
- Giáo viên chọn đề và bấm *"Tạo phòng thi"* hoạt động 100% bình thường.

### 5.3. Màn Hình Quản Lý Đề Thi (`TeacherExamsScreen`)
- Bổ sung thêm Tab `Đề đã lưu` bên cạnh `Tất cả`, `Đã xuất bản`, `Bản nháp`.
- Hiển thị danh sách các đề cộng đồng đã lưu kèm nút *"Tạo phòng thi ngay"* hoặc *"Xem chi tiết"*.

---

## 6. Chiến Lược Kiểm Thử & Tự Động Hóa (TDD)

1. **Unit Tests:**
   - `test/repositories/saved_exam_repository_test.dart`: Kiểm thử lưu, hủy lưu, kiểm tra trạng thái lưu, xử lý fallback khi không có Supabase instance.
2. **Widget Tests:**
   - `test/screens/exam_detail_preview_test.dart`:
     - Kiểm thử hiển thị đầy đủ thông tin đề, nút "Bắt đầu tự luyện", "Thêm vào yêu thích" và "Lưu đề".
     - Kiểm thử bấm nút mũi tên cuộn mượt xuống vùng câu hỏi.
     - Kiểm thử hiển thị danh sách câu hỏi, toggle bật/tắt đáp án & giải thích.
     - Kiểm thử bấm vào số câu trong bảng con Quick-Jump Navigator.
   - `test/screens/search_screen_save_test.dart`:
     - Kiểm thử bấm icon lưu nhanh trên thẻ tìm kiếm.
   - `test/screens/create_room_with_saved_exam_test.dart`:
     - Kiểm thử lọc và chọn đề đã lưu trong màn hình tạo phòng thi.
3. **Bộ Kiểm Thử Hiện Hữu:**
   - Đảm bảo toàn bộ **186 / 186 test cases** hiện tại tiếp tục vượt qua 100% (`flutter test`).

---

## 7. Kế Hoạch Triển Khai (Dự Kiến Chuyển Sang `writing-plans`)

- **Task 1:** Tạo migration SQL `public.saved_exams` và cập nhật RPC `create_teacher_room`.
- **Task 2:** Xây dựng `SavedExamRepository` và đăng ký vào `MultiProvider`.
- **Task 3:** Nâng cấp `ExamDetailScreen` với nút Lưu đề, mũi tên chỉ báo cuộn, danh sách câu hỏi & đáp án, toggle giải thích và Sidebar Quick-Jump Navigator.
- **Task 4:** Bổ sung icon Lưu nhanh trên thẻ tìm kiếm tại `SearchScreen`.
- **Task 5:** Nâng cấp `CreateRoomScreen` và `TeacherExamsScreen` hỗ trợ tab "Đề đã lưu".
- **Task 6:** Viết bộ test và xác minh 100% test suite PASS, cập nhật tài liệu và tự động push.
