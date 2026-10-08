# Thiết Kế: Dọn Dẹp Widget Thừa, Loại Bỏ Mã Mồ Côi & Chuẩn Hóa Logic Ứng Dụng (Zero New Features)

> **Mục tiêu:** Quét sạch toàn bộ các widget không còn được sử dụng (orphan widgets), loại bỏ các tệp trùng lặp/di sản thừa, triệt tiêu các fallback UUID ảo và khắc phục cảnh báo linter về async gap. Tuyệt đối không bổ sung bất kỳ tính năng mới nào.

---

## 1. Phạm Vi & Nguyên Tắc Cốt Lõi

- **Nguyên tắc YAGNI & Zero New Features:** Chỉ loại bỏ mã chết, tối ưu hóa các thành phần hiện có; không thêm màn hình, không thêm API và không thêm tính năng mới.
- **Bảo toàn Test Suite:** Mọi bài test liên quan phải được cập nhật tương ứng, đảm bảo 100% test suites tiếp tục màu xanh (green) sau khi dọn dẹp.
- **Đồng bộ Kiến trúc:** Đảm bảo toàn bộ import trong dự án sạch sẽ, không còn tham chiếu tới các tệp mồ côi.

---

## 2. Chi Tiết Danh Sách Tệp & Widget Cần Loại Bỏ

| Tệp cần loại bỏ | Lý do & Hiện trạng | Giải pháp xử lý |
| :--- | :--- | :--- |
| `lib/shared/widgets/profile_dialog.dart` | Định nghĩa `ProfileDialog` (337 dòng) với 0 tham chiếu trong toàn bộ dự án. Header `TopNavBar` đã chuyển hướng sang `/profile` (`ProfileScreen`). | Xóa vĩnh viễn tệp này. |
| `lib/shared/widgets/topic_chip.dart` | Định nghĩa `TopicChip` (39 dòng) với 0 tham chiếu. `HomeScreen` tự render chip môn học trực tiếp. | Xóa vĩnh viễn tệp này. |
| `lib/core/utils/otp_mailer.dart` | Utility gọi API FormSubmit (42 dòng) với 0 tham chiếu, không dùng trong luồng Supabase Auth hiện tại. | Xóa vĩnh viễn tệp này. |
| `lib/screens/exam/teacher_exams_screen.dart` | Bản nháp cũ (85 dòng) trùng lặp với màn hình chính thức `lib/screens/teacher/teacher_exams_screen.dart` (655 dòng). | Xóa tệp thừa này; cập nhật `test/screens/teacher_exams_screen_test.dart` trỏ về màn hình chính thức. |

---

## 3. Tinh Chỉnh Màn Hình & Triệt Tiêu Hành Vi Ảo

### 3.1. `ExamDetailScreen` (`lib/screens/exam/exam_detail_screen.dart`)
- **Vấn đề:** Dòng 18 & 115 chứa `static const _demoExamId = '10000000-0000-4000-8000-000000000002';`. Khi không tìm thấy đề hoặc ID rỗng, code tự ý fallback về UUID demo này.
- **Giải pháp:**
  - Xóa bỏ `_demoExamId`.
  - Nếu `_examData == null` và không tải được đề: Hiển thị giao diện thông báo *"Không tìm thấy đề thi hoặc đề thi đã bị xóa"* cùng nút quay lại trang chủ.
  - Vô hiệu hóa nút Bookmark hoặc hiển thị thông báo rõ ràng, loại bỏ biến `_saved` đánh lừa trạng thái người dùng.

### 3.2. `HomeScreen` (`lib/screens/home/home_screen.dart`)
- **Vấn đề:** Các hàm `_handleActiveAttemptClick` và `_handleActiveLiveRoomClick` sử dụng `BuildContext` sau async call mà thiếu kiểm tra `if (!mounted) return;`.
- **Giải pháp:** Bổ sung `if (!mounted) return;` trước các thao tác `context.go(...)` và `ScaffoldMessenger.of(context)`.

---

## 4. Kế Hoạch Kiểm Thử & Xác Nhận (Verification)

1. **Phân tích tĩnh:** Chạy `dart analyze lib/` đảm bảo không còn lỗi gãy import hay lỗi cú pháp.
2. **Kiểm thử tự động:**
   - Cập nhật `test/screens/teacher_exams_screen_test.dart` để kiểm tra màn hình chính thức `screens/teacher/teacher_exams_screen.dart`.
   - Chạy `flutter test` đảm bảo tất cả test suites PASS 100%.
3. **Cập nhật tài liệu:** Đồng bộ `docs/system_architecture_and_deep_evaluation.md`.
4. **Git Commit & Push:** Tự động commit và đẩy mã nguồn lên GitHub.
