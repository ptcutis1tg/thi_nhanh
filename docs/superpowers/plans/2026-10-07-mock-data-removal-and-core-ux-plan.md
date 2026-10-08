# Kế Hoạch Triển Khai: Loại Bỏ Dữ Liệu Mock & Nâng Cao Trải Nghiệm Cốt Lõi (Core UX & Realtime First)

> **Dành cho tác tử:** BẮT BUỘC SỬ DỤNG KỸ NĂNG: Sử dụng `superpowers:subagent-driven-development` (khuyến nghị) hoặc `superpowers:executing-plans` để triển khai kế hoạch này theo từng tác vụ. Các bước sử dụng cú pháp checkbox (`- [ ]`) để theo dõi tiến độ.

**Mục tiêu:** Xóa bỏ triệt để các dữ liệu giả lập/mock trong `LiveDashboardScreen`, chuẩn hóa điều hướng động của thẻ "Bài Đang Làm" & "Phòng Đang Diễn Ra" trên `HomeScreen`, dọn dẹp các route thừa và chuẩn hóa bảng xếp hạng học sinh.

**Kiến trúc:** Bổ sung các truy vấn Supabase chính xác cho tiến độ thi thời gian thực (`attempt_answers`, `questions`, `attempts`, `rooms`), thay thế hoàn toàn các giá trị hardcode bằng dữ liệu phản ánh từ CSDL, dọn dẹp mã nguồn di sản không sử dụng.

**Công nghệ:** Flutter / Dart, GoRouter, Supabase Flutter Client (PostgreSQL / RLS), Provider.

## Ràng Buộc Chung (Global Constraints)
- Giữ vững 100% các bài test hiện có (188/188 tests green), không gây hồi quy (no regression).
- Tuân thủ quy tắc Auto-push: Tự động commit và push lên GitHub sau mỗi task hoàn thành.
- Tuân thủ quy tắc cập nhật tài liệu tổng quan: Đồng bộ `docs/system_architecture_and_deep_evaluation.md` và artifact tương ứng khi hoàn tất mốc phát triển.

---

### Task 1: Dọn Dẹp Mã Nguồn Di Sản & Route Mock & Chuẩn Hóa Thời Gian Tương Đối

**Files:**
- Xóa: `thi_nhanh/lib/core/stores/created_exam_store.dart`
- Sửa: `thi_nhanh/lib/main.dart:264-271`
- Sửa: `thi_nhanh/lib/screens/home/search_screen.dart:10-34, 101`
- Test: `thi_nhanh/test/shared/relative_time_test.dart`

**Interfaces:**
- `formatRelativeTime(DateTime dateTime)` $\rightarrow$ trả về `String` biểu diễn thời gian tự nhiên tiếng Việt (`Vừa xong`, `X phút trước`, `X giờ trước`, `Hôm qua`, `dd/MM/yyyy`).

- [ ] **Bước 1: Viết test kiểm thử cho hàm `formatRelativeTime`**
Tạo file `thi_nhanh/test/shared/relative_time_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/screens/home/search_screen.dart';

void main() {
  group('formatRelativeTime helper', () {
    test('trả về Vừa xong cho thời gian dưới 1 phút', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(seconds: 30))), 'Vừa xong');
    });

    test('trả về X phút trước cho thời gian dưới 1 giờ', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(minutes: 15))), '15 phút trước');
    });

    test('trả về X giờ trước cho thời gian trong ngày', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(hours: 3))), '3 giờ trước');
    });

    test('trả về Hôm qua cho thời gian 1 ngày trước', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(days: 1))), 'Hôm qua');
    });
  });
}
```

- [ ] **Bước 2: Chạy test để xác nhận test thất bại (Red)**
Chạy: `flutter test test/shared/relative_time_test.dart`
Kỳ vọng: Thất bại do chưa định nghĩa hàm `formatRelativeTime`.

- [ ] **Bước 3: Cập nhật `search_screen.dart`, xóa `created_exam_store.dart`, xóa route mock trong `main.dart`**
1. Xóa file `thi_nhanh/lib/core/stores/created_exam_store.dart`.
2. Trong `thi_nhanh/lib/screens/home/search_screen.dart`, định nghĩa hàm `formatRelativeTime`:
```dart
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays == 1) return 'Hôm qua';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
}
```
Và sử dụng `item['created_at'] != null ? formatRelativeTime(DateTime.parse(item['created_at'].toString()).toLocal()) : 'Mới tạo'` thay cho chuỗi cứng `'Mới tạo'`.
3. Trong `thi_nhanh/lib/main.dart`, gỡ bỏ route `/exam/physics-12`.

- [ ] **Bước 4: Chạy lại test để xác nhận test vượt qua (Green)**
Chạy: `flutter test test/shared/relative_time_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 5: Commit và Push**
```bash
git -C thi_nhanh add lib/main.dart lib/screens/home/search_screen.dart test/shared/relative_time_test.dart
git -C thi_nhanh rm lib/core/stores/created_exam_store.dart
git -C thi_nhanh commit -m "refactor: clean up orphan store, remove mock route and add relative time formatting"
git -C thi_nhanh push origin main
```

---

### Task 2: Loại Bỏ Dữ Liệu Giả Lập Trong `LiveDashboardScreen`

**Files:**
- Sửa: `thi_nhanh/lib/screens/exam/live_dashboard_screen.dart:35-85`
- Test: `thi_nhanh/test/screens/live_dashboard_real_data_test.dart`

**Interfaces:**
- `LiveDashboardScreen`: Tải danh sách `attempts` kèm đếm số câu hỏi thực tế của đề thi (`questions`), đếm số câu đã trả lời từ `attempt_answers`. Đối với `in_progress`, hiển thị số câu đã làm thực tế thay vì hardcode 12/8/4/20.

- [ ] **Bước 1: Viết test kiểm thử dữ liệu thực tế cho `LiveDashboardScreen`**
Tạo file `thi_nhanh/test/screens/live_dashboard_real_data_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/screens/exam/live_dashboard_screen.dart';

void main() {
  testWidgets('LiveDashboardScreen hiển thị chính xác số câu đã làm thực tế của học sinh đang thi', (tester) async {
    final mockStudents = [
      {
        'name': 'Trần Văn Nam',
        'initials': 'TN',
        'answered': 17,
        'totalQuestions': 25,
        'correct': null,
        'wrong': null,
        'completed': false,
        'score': 0.0,
        'violations': 1,
      },
      {
        'name': 'Lê Thị Mai',
        'initials': 'LM',
        'answered': 25,
        'totalQuestions': 25,
        'correct': 23,
        'wrong': 2,
        'completed': true,
        'score': 9.2,
        'violations': 0,
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: LiveDashboardScreen(
          roomCode: 'PT999999',
          initialStudents: mockStudents,
        ),
      ),
    );

    expect(find.text('Trần Văn Nam'), findsOneWidget);
    expect(find.text('17 / 25 câu'), findsOneWidget);
    expect(find.text('Lê Thị Mai'), findsOneWidget);
    expect(find.text('9.2 điểm'), findsOneWidget);
  });
}
```

- [ ] **Bước 2: Chạy test để xác nhận kiểm thử ban đầu**
Chạy: `flutter test test/screens/live_dashboard_real_data_test.dart`
Kỳ vọng: Thất bại hoặc chưa khớp định dạng hiển thị.

- [ ] **Bước 3: Nâng cấp `live_dashboard_screen.dart` để truy vấn câu hỏi và câu trả lời thực tế**
Trong `_loadLiveRoomData()` của `live_dashboard_screen.dart`:
1. Truy vấn `totalQuestions` từ bảng `questions` theo `exam_id`.
2. Với mỗi attempt:
   - Nếu `status == 'submitted'`: Điểm số và số câu đúng được tính từ kết quả đã chấm, số câu sai = `totalQuestions - correct`.
   - Nếu `status != 'submitted'` (đang làm): Truy vấn `count` từ `attempt_answers` theo `attempt_id`.
   - Không bịa số câu đúng/sai trước khi nộp.
3. Cập nhật bảng giám sát `_buildMonitoringTable`:
   - Hiển thị `${s['answered']} / ${s['totalQuestions'] ?? 20} câu`.
   - Hiển thị cờ vi phạm màu đỏ nếu `violations > 0`.

- [ ] **Bước 4: Chạy lại test để xác nhận xanh (Green)**
Chạy: `flutter test test/screens/live_dashboard_real_data_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 5: Commit và Push**
```bash
git -C thi_nhanh add lib/screens/exam/live_dashboard_screen.dart test/screens/live_dashboard_real_data_test.dart
git -C thi_nhanh commit -m "feat: eliminate mock monitoring data in live dashboard with real questions and answers counts"
git -C thi_nhanh push origin main
```

---

### Task 3: Điều Hướng Động Thông Minh Cho Thẻ "Bài Đang Làm" & "Phòng Đang Diễn Ra" trên `HomeScreen`

**Files:**
- Sửa: `thi_nhanh/lib/screens/home/home_screen.dart:25-85, 820-888`
- Test: `thi_nhanh/test/screens/home_smart_navigation_test.dart`

**Interfaces:**
- `HomeScreen`:
  - `_inProgressAttemptId`, `_inProgressExamId`: ID bài làm dở dang gần nhất.
  - `_activeLiveRoomId`, `_activeLiveRoomCode`: ID và mã phòng thi đang mở gần nhất.
  - Xử lý tương tác: Nếu có bài dở dang $\rightarrow$ mở thẳng `/taking_exam`. Nếu có phòng mở $\rightarrow$ mở thẳng `/live_dashboard`. Nếu không có $\rightarrow$ phản hồi thông điệp rõ ràng và gợi ý tạo/tìm kiếm.

- [ ] **Bước 1: Viết test cho điều hướng thông minh của `HomeScreen`**
Tạo file `thi_nhanh/test/screens/home_smart_navigation_test.dart`:
Kiểm tra xử lý nhấp chuột khi có bài thi đang làm dở và khi không có bài thi nào đang làm dở.

- [ ] **Bước 2: Chạy test xác nhận**
Chạy: `flutter test test/screens/home_smart_navigation_test.dart`

- [ ] **Bước 3: Cập nhật logic trong `home_screen.dart`**
1. Thêm `_checkActiveSessions()` trong `_loadDashboardData()`:
   - Truy vấn `attempts` lọc `user_id` và `status = 'in_progress'`.
   - Truy vấn `rooms` lọc `teacher_id` và `status = 'live'`.
2. Trong `_buildFeatureCardsGrid()`:
   - Thẻ "Bài Đang Làm": Khi bấm, nếu có `_inProgressAttemptId` $\rightarrow$ `context.go('/taking_exam?attemptId=$_inProgressAttemptId&examId=$_inProgressExamId')`. Nếu không có $\rightarrow$ hiển thị SnackBar thông báo và chuyển sang `/search`.
   - Thẻ "Phòng Đang Diễn Ra": Khi bấm, nếu có `_activeLiveRoomCode` $\rightarrow$ `context.go('/live_dashboard?code=$_activeLiveRoomCode')`. Nếu không có $\rightarrow$ hiển thị SnackBar và chuyển sang `/create_room`.

- [ ] **Bước 4: Chạy lại test xác nhận xanh (Green)**
Chạy: `flutter test test/screens/home_smart_navigation_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 5: Commit và Push**
```bash
git -C thi_nhanh add lib/screens/home/home_screen.dart test/screens/home_smart_navigation_test.dart
git -C thi_nhanh commit -m "feat: implement smart dynamic navigation for in-progress tests and live rooms on home screen"
git -C thi_nhanh push origin main
```

---

### Task 4: Chuẩn Hóa Bảng Xếp Hạng `StudentLeaderboardScreen`

**Files:**
- Sửa: `thi_nhanh/lib/screens/student/student_leaderboard_screen.dart:40-95`
- Test: `thi_nhanh/test/screens/student_leaderboard_real_user_test.dart`

**Interfaces:**
- `StudentLeaderboardScreen`: Không sinh email giả `'hocsinh@gmail.com'`. Khi học sinh là tài khoản khách nộp bài theo `guest_name`, hiển thị nhãn `(Khách)`. Khi có `user_id`, hiển thị tên tài khoản sạch sẽ.

- [ ] **Bước 1: Viết test cho `StudentLeaderboardScreen`**
Tạo file `thi_nhanh/test/screens/student_leaderboard_real_user_test.dart` xác minh việc không còn hiển thị email giả và định danh khách rõ ràng.

- [ ] **Bước 2: Chạy test xác nhận**
Chạy: `flutter test test/screens/student_leaderboard_real_user_test.dart`

- [ ] **Bước 3: Triển khai chuẩn hóa trong `student_leaderboard_screen.dart`**
1. Loại bỏ dòng `email: nameKey.contains('@') ? nameKey : 'hocsinh@gmail.com'`.
2. Thay thế bằng định danh chuẩn:
   - Nếu `guest_name` có giá trị: Gán nhãn `$guestName (Khách)`.
   - Nếu là tài khoản đăng ký: Sử dụng tên hiển thị từ metadata hoặc bảng liên kết.

- [ ] **Bước 4: Chạy lại test xác nhận xanh (Green)**
Chạy: `flutter test test/screens/student_leaderboard_real_user_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 5: Commit và Push**
```bash
git -C thi_nhanh add lib/screens/student/student_leaderboard_screen.dart test/screens/student_leaderboard_real_user_test.dart
git -C thi_nhanh commit -m "feat: sanitize student leaderboard by removing fake email placeholders and labeling guests"
git -C thi_nhanh push origin main
```

---

### Task 5: Kiểm Thử Toàn Diện Toàn Bộ Hệ Thống & Cập Nhật Tài Liệu Đánh Giá

**Files:**
- Cập nhật: `thi_nhanh/docs/system_architecture_and_deep_evaluation.md`
- Cập nhật IDE Artifact: `system_architecture_and_deep_evaluation.md`
- Submodule Pointer: `CODE` root

- [ ] **Bước 1: Chạy toàn bộ test suite hồi quy (Full Regression Test Suite)**
Chạy: `flutter test` trong thư mục `thi_nhanh`.
Kỳ vọng: 100% tất cả các bài test (188+ bài test) đều đạt màu xanh (All Green).

- [ ] **Bước 2: Cập nhật tài liệu đánh giá tổng quan kiến trúc hệ thống**
Đồng bộ các cải tiến loại bỏ dữ liệu mock vào `thi_nhanh/docs/system_architecture_and_deep_evaluation.md`:
- Mục 2: Mô tả luồng giám sát Live Dashboard chính xác theo câu trả lời thực tế.
- Mục 5: Đánh giá độ tin cậy dữ liệu (Data Integrity) tăng lên sau khi loại bỏ mock.
- Mục 6.1: Đánh dấu hoàn thành giai đoạn làm sạch dữ liệu mock & nâng cấp Core UX.

- [ ] **Bước 3: Commit và Push cả `thi_nhanh` và `CODE` root**
```bash
git -C thi_nhanh add docs/system_architecture_and_deep_evaluation.md
git -C thi_nhanh commit -m "docs: sync system architecture evaluation after mock data removal and core UX enhancements"
git -C thi_nhanh push origin main

git add .
git commit -m "docs: update submodule and system evaluation after mock removal"
git push origin main
```
