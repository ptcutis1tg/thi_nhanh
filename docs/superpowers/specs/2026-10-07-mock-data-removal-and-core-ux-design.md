# Đặc Tả Kỹ Thuật: Loại Bỏ Dữ Liệu Mock & Nâng Cao Trải Nghiệm Cốt Lõi (Core UX & Realtime First)

- **Mã kế hoạch:** `2026-10-07-mock-data-removal-and-core-ux-design`
- **Ngày lập:** 07/10/2026
- **Trạng thái:** Bản thảo đã duyệt / Chuẩn bị lập kế hoạch thi công

---

## 1. Mục Tiêu & Phạm Vi (Goals & Non-Goals)

### 1.1. Mục Tiêu (Goals)
1. **Xóa bỏ hoàn toàn số liệu giả lập trong `LiveDashboardScreen`:**
   - Thay thế việc hardcode số câu đã làm (12), số câu đúng (8), số câu sai (4) và tổng câu (20) bằng truy vấn thực tế đếm số lượng câu hỏi trong đề (`questions`) và số câu học sinh đã khoanh thực tế (`attempt_answers`).
   - Phân biệt rõ trạng thái đang làm (`in_progress` - chưa có điểm, hiện tiến độ thực tế $X/N$ câu) và đã nộp (`submitted` - có điểm và số câu đúng chính xác).
2. **Khắc phục điều hướng động thông minh tại `HomeScreen`:**
   - Thẻ *"Bài Đang Làm"*: Tự động truy vấn bài làm dở dang gần nhất (`status = 'in_progress'`) của học sinh và điều hướng trực tiếp vào bài thi đó. Nếu không có bài dở dang, hiển thị trạng thái thích hợp và hướng dẫn học sinh chọn đề mới.
   - Thẻ *"Phòng Đang Diễn Ra"*: Tự động truy vấn phòng thi đang mở (`status = 'live'`) của giáo viên để mở ngay `LiveDashboardScreen` hoặc `TeacherWaitingRoomScreen` có kèm `roomId`/`roomCode` hợp lệ, xóa bỏ hoàn toàn lỗi "Thiếu mã phòng".
3. **Chuẩn hóa Bảng Xếp Hạng `StudentLeaderboardScreen`:**
   - Không gán chuỗi giả định `'hocsinh@gmail.com'`.
   - Lấy tên người dùng thực tế từ bảng `profiles` nếu là tài khoản đã đăng ký; nếu là khách thi tự do thì ghi rõ `(Khách)` bên cạnh `guest_name`.
4. **Dọn dẹp mã nguồn di sản và các route mock:**
   - Xóa file mồ côi không dùng: `lib/core/stores/created_exam_store.dart`.
   - Xóa route giả định `/exam/physics-12` trong `lib/main.dart`.
   - Bổ sung hàm tính thời gian tương đối cho nhãn `activity` trong `SearchScreen` thay vì chuỗi cứng `'Mới tạo'`.

### 1.2. Ngoài Phạm Vi (Non-Goals)
- Không đập đi xây lại toàn bộ hệ thống huy hiệu (giữ nguyên logic 4 huy hiệu hiện tại đang hoạt động tốt với RPC Supabase).
- Không bổ sung các hệ thống push notification bên ngoài (Firebase/OneSignal) trong phạm vi này; bảng thông báo hệ thống được làm động nhẹ qua cấu hình dữ liệu.

---

## 2. Thiết Kế Chi Tiết Từng Thành Phần (Detailed Design)

### 2.1. Phân Hệ Giám Sát Phòng Thi: `LiveDashboardScreen`
- **Mã nguồn:** `lib/screens/exam/live_dashboard_screen.dart`
- **Hiện trạng:**
  ```dart
  // Dữ liệu mock hiện tại
  'answered': isDone ? 20 : 12,
  'correct': isDone ? (scoreNum / 10 * 20).round() : 8,
  'wrong': isDone ? 20 - (scoreNum / 10 * 20).round() : 4,
  ```
- **Thiết kế mới:**
  1. Khi tải phòng thi theo `roomCode`:
     - Lấy thông tin phòng và `exam_id`.
     - Lấy tổng số câu hỏi thực tế của đề thi từ bảng `questions` (`totalQuestions`).
  2. Với mỗi thí sinh trong danh sách `attempts`:
     - Truy vấn số lượng câu trả lời đã lưu trong `attempt_answers` theo `attempt_id` (`answeredCount`).
     - Nếu `status == 'submitted'`:
       - `isDone = true`.
       - `score = (a['score'] as num).toDouble()`.
       - `correctCount`: Lấy từ kết quả chấm điểm thực tế hoặc tính theo tỷ lệ điểm số trên tổng điểm đề thi.
       - `wrongCount = totalQuestions - correctCount`.
     - Nếu `status == 'in_progress'` hoặc `waiting`:
       - `isDone = false`.
       - `answered = answeredCount` (thực tế từ `attempt_answers`).
       - `correct = null` (chưa nộp bài, không hiển thị trước đáp án đúng sai để bảo mật học thuật).
       - `score = 0.0`.
       - `violations = (a['violations'] as num?)?.toInt() ?? 0`.
  3. Giao diện hiển thị:
     - Với học sinh đang thi: Hiển thị thanh tiến độ `Đã làm: answeredCount / totalQuestions câu` kèm cờ cảnh báo vi phạm màu đỏ nếu `violations > 0`.

### 2.2. Điều Hướng Động Tại `HomeScreen`
- **Mã nguồn:** `lib/screens/home/home_screen.dart`
- **Thẻ "Bài Đang Làm" (Học sinh):**
  - Bổ sung biến trạng thái `String? _activeAttemptId`, `String? _activeExamId`, `String? _activeExamTitle`.
  - Trong `_loadDashboardData()`:
    ```dart
    final inProgressRes = await client
        .from('attempts')
        .select('id, exam_id, exams(title)')
        .eq('user_id', userId)
        .eq('status', 'in_progress')
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    ```
  - Khi bấm thẻ:
    - Nếu có `_activeAttemptId`: `context.go('/taking_exam?attemptId=$_activeAttemptId&examId=$_activeExamId')`.
    - Nếu không có: Thông báo SnackBar nhẹ "Bạn không có bài thi nào đang làm dở dang" và điều hướng sang `/search` để chọn đề mới.
- **Thẻ "Phòng Đang Diễn Ra" (Giáo viên):**
  - Bổ sung biến trạng thái `String? _liveRoomId`, `String? _liveRoomCode`.
  - Trong `_loadDashboardData()`:
    ```dart
    final liveRoomRes = await client
        .from('rooms')
        .select('id, code')
        .eq('teacher_id', teacherId)
        .eq('status', 'live')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    ```
  - Khi bấm thẻ:
    - Nếu có `_liveRoomCode`: `context.go('/live_dashboard?code=$_liveRoomCode')`.
    - Nếu không có: Thông báo "Hiện không có phòng thi nào đang mở" và mở `/create_room`.

### 2.3. Bảng Xếp Hạng `StudentLeaderboardScreen`
- **Mã nguồn:** `lib/screens/student/student_leaderboard_screen.dart`
- **Thiết kế mới:**
  - Lấy danh sách điểm kèm thông tin người dùng:
    - Nếu `user_id` tồn tại: Truy vấn bảng `profiles` để lấy `full_name` và `avatar_url`.
    - Nếu `guest_name` tồn tại: Sử dụng `guest_name` và đánh dấu tag `(Khách)`.
  - Bỏ hoàn toàn chuỗi fallback `'hocsinh@gmail.com'`. Nếu không có email thì để trống hoặc hiển thị ẩn danh an toàn.

### 2.4. Dọn Dẹp Mã Nguồn & Route Mock
- Xóa file `lib/core/stores/created_exam_store.dart`.
- Xóa route `/exam/physics-12` trong `lib/main.dart`.
- Tại `SearchScreen`: Thêm helper `formatRelativeTime(DateTime createdAt)` để hiển thị `Vừa xong`, `5 phút trước`, `Hôm qua`, `dd/MM/yyyy` thay cho chuỗi tĩnh `'Mới tạo'`.

---

## 3. Kế Hoạch Kiểm Thử & Đảm Bảo Chất Lượng (QA & Test Strategy)

1. **Unit & Widget Test Coverage:**
   - Viết widget test cho `HomeScreen` xác thực:
     - Khi có `in_progress attempt`, thẻ chuyển đúng vào `/taking_exam`.
     - Khi không có, hiển thị fallback phù hợp.
     - Khi có `live room`, thẻ chuyển đúng vào `/live_dashboard`.
   - Viết widget test cho `LiveDashboardScreen` xác thực việc render số liệu thật từ `attempt_answers`.
   - Viết widget test cho `StudentLeaderboardScreen` xác thực việc hiển thị tên học sinh thật và nhãn khách.
2. **Kiểm tra hồi quy (Regression Test):**
   - Chạy toàn bộ test suite (`flutter test`) đảm bảo duy trì tỷ lệ **100% Pass** (không làm hỏng bất kỳ bài test nào trong số 188 test hiện có).
