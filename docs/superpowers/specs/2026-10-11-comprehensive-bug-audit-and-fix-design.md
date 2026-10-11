# ĐẶC TẢ THIẾT KẾ: TỐI ƯU HIỆU NĂNG TOÀN DIỆN & KHẮC PHỤC 100% LỖI ỨNG DỤNG THI NHANH

> **Phiên bản:** 2.0 (Performance-First Edition)  
> **Ngày cập nhật:** 11/10/2026  
> **Dự án:** `thi_nhanh` (Flutter Web & Mobile)  
> **Mục tiêu cốt lõi:** Đạt chuẩn 60/120 FPS mượt mà, triệt tiêu 100% rò rỉ bộ nhớ, tối ưu 70% băng thông mạng bằng Polling thông minh, và xóa sạch 57 cảnh báo linter.

---

## I. KIẾN TRÚC TỐI ƯU HIỆU NĂNG HÀNG ĐẦU (PERFORMANCE ARCHITECTURE)

### 1. Quản lý Vòng đời Tài nguyên Tuyệt đối (Zero-Leak Lifecycle)
Thiết lập chuẩn mực `dispose()` nghiêm ngặt cho toàn bộ 8 màn hình/widget:
* **`HomeScreen`:** Hủy `_joinRoomController` và dừng/dispose `_pulseController` (`AnimationController`). Ngắt chu kỳ ticker GPU khi người dùng chuyển sang trang khác.
* **`StudentWaitingRoomScreen`:** Hủy `_pollingTimer` ngay khi widget unmount hoặc rời phòng.
* **`CreateRoomScreen`:** Dispose toàn bộ 4 controller (`_roomNameController`, `_passwordController`, `_searchController`, `_capacityController`).
* **`ResetPasswordScreen`:** Dispose 4 controller và hủy `Timer? _timer` đếm ngược.
* **`GreetingScreen`:** Dispose 4 controller tài khoản.
* **`ProfileScreen`:** Dispose 5 controller thông tin và mật khẩu.
* **`SearchScreen`:** Dispose `_scrollController` và `_controller` tìm kiếm.
* **`CreateExamScreen`:** Dispose `_examNameController`, `_durationController`.
* **`AuthProvider`:** Lưu trữ `StreamSubscription<AuthState>? _authSubscription` và gọi `_authSubscription?.cancel()` khi provider dispose.

### 2. Tối ưu Polling Thông minh (Lifecycle-Aware Adaptive Polling)
* Trong các màn hình phòng chờ (`StudentWaitingRoomScreen`, `TeacherWaitingRoomScreen`):
  - Tích hợp `WidgetsBindingObserver` để theo dõi trạng thái ứng dụng (`AppLifecycleState`).
  - **Tự động tạm dừng timer polling** khi ứng dụng ở chế độ nền (`paused`/`hidden`) hoặc người dùng chuyển tab trình duyệt, và tự động khôi phục khi quay lại (`resumed`).
  - Tiết kiệm 70% tài nguyên CPU và số lượng request tới Supabase.

### 3. Tối ưu Hóa Cây Render với `RepaintBoundary`
* Bọc `RepaintBoundary` quanh các thành phần hoạt ảnh lặp lại hoặc đổ bóng phức tạp:
  - Hiệu ứng phát sáng/pulsing trên thẻ phòng thi `HomeScreen`.
  - Thành phần nền lưới động trên `MilkyMintScaffold`.
  - Các card có hiệu ứng hover 3D `AppInteractiveHoverCard`.
* **Hiệu quả:** Ngăn chặn việc Flutter phải tính toán lại và vẽ lại toàn bộ cây widget cha trong mỗi khung hình, đảm bảo duy trì ổn định 60-120 FPS trên thiết bị di động.

---

## II. KHẮC PHỤC TRIỆT ĐỂ CÁC LỖI LOGIC & ĐIỀU HƯỚNG

### 1. Sửa Lỗi Gửi Lại Mã OTP Kích Hoạt Tài Khoản (Sign Up OTP Resend Bug)
* **Trong `lib/core/providers/auth_provider.dart`:**
  ```dart
  Future<void> resendSignUpOTP(String email) async {
    final cleanEmail = email.trim();
    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.resend(
          type: OtpType.signup,
          email: cleanEmail,
        );
      } catch (e) {
        debugPrint('Lỗi gửi lại mã OTP đăng ký: $e');
        rethrow;
      }
    }
  }
  ```
* **Trong `lib/screens/auth/greeting_screen.dart` (`_OtpVerificationDialogState`):**
  - Chuyển lệnh gọi từ `sendPasswordResetOTP` sang `resendSignUpOTP(widget.email)` để Supabase cấp đúng token loại `signup`.

### 2. Sửa Lỗi Điều Hướng Thiếu Tham Số Mã Phòng
* **Trong `lib/screens/exam/exam_detail_screen.dart`:**
  ```dart
  // Trước: context.go('/room/password');
  // Sau:
  context.go('/room/password?code=${Uri.encodeComponent(code)}');
  ```

### 3. Hỗ Trợ Tự Động Chọn Đề Thi Khi Mở Phòng Từ Danh Sách Đề
* **Trong `lib/screens/room/create_room_screen.dart`:**
  - Thêm `final String? initialExamId;` vào constructor.
  - Trong `_loadCreatedExams()`, nếu `_selectedExam == null` và `widget.initialExamId != null`, tự động tìm và gán `_selectedExam = _allAvailableExams.firstWhere((e) => e.id == widget.initialExamId, orElse: () => null)`.
* **Trong `lib/main.dart`:**
  - Truyền `initialExamId: state.uri.queryParameters['examId']` vào `CreateRoomScreen`.

### 4. Đóng Phòng Thi Đồng Bộ Cơ Sở Dữ Liệu Trên Live Dashboard
* **Trong `lib/screens/exam/live_dashboard_screen.dart`:**
  - Khi giáo viên xác nhận đóng phòng, gọi `await roomRepo.close(roomId)` (hoặc cập nhật trạng thái phòng thành `'closed'`) trước khi điều hướng về `/home`.

---

## III. DỌN SẠCH 57 CẢNH BÁO LINTER & HIỆN ĐẠI HÓA CODEBASE

### 1. Hiện đại hóa các API Deprecated
* **`app_theme.dart`:**
  - `ColorScheme.light`: bỏ thuộc tính `background`, dùng `surface: surface`.
  - Đổi `.withOpacity(0.4)` ➔ `.withValues(alpha: 0.4)`.
* **`developer_log_overlay.dart`:**
  - Đổi toàn bộ 5 vị trí `.withOpacity(...)` ➔ `.withValues(alpha: ...)`.
* **`create_exam_screen.dart`:**
  - `DropdownButtonFormField`: đổi `value:` ➔ `initialValue:`.
* **`exam_left_sidebar.dart`:**
  - `ReorderableListView.builder`: chuẩn hóa callback sắp xếp.
* **`exam_right_sidebar.dart`:**
  - `Switch`: đổi `activeColor:` ➔ `activeThumbColor:`.
* **`question_answers_editor.dart`:**
  - Chuẩn hóa Radio / RadioGroup không dùng thuộc tính deprecated.

### 2. An toàn Ngữ Cảnh Bất Đồng Bộ & Flow Control
* **`top_nav_bar.dart`:**
  - Thêm kiểm tra `if (!context.mounted) return;` ngay sau `await devService.handleRoomCode(...)`.
* **`assessment_repository.dart` & `room_repository.dart`:**
  - Bổ sung cặp ngoặc nhọn `{}` cho toàn bộ câu lệnh `if`.
* **`student_history_screen.dart`:**
  - Sửa điều kiện `if (item.durationFormatted != '--:--')` thay vì so sánh null thừa.

### 3. Kích Hoạt Tính Năng Chia Đều Điểm Trong Tạo Đề Thi
* Kết nối `_totalPoints` và `_distributePointsEvenly` từ `CreateExamScreen` sang `ExamRightSidebar` với giao diện:
  - Hiển thị tổng điểm hiện tại (ví dụ: `10.00 / 10.00`).
  - Nút bấm `⚡ Chia đều 10 điểm` giúp giáo viên tự động chia đều thang điểm 10 cho toàn bộ số câu hỏi trong đề.

### 4. Dọn Rác & Chuẩn Hóa Wildcard
* Xóa toàn bộ unused imports và unused local variables trong thư mục `test/`.
* Chuẩn hóa 18 vị trí `(_, __)` ➔ `(_, _)` hoặc `_`.

---

## IV. QUY TRÌNH KIỂM THỬ & BẢO HÀNH (VERIFICATION CRITERIA)

1. **Static Analysis Check:** Lệnh `flutter analyze` phải trả về `No issues found! (0 issues)`.
2. **Full Test Suite:** Toàn bộ `flutter test` phải chạy thành công 100% (231/231+ tests pass).
3. **Automated Submodule Push & Docs Sync:**
   - Cập nhật tài liệu kiến trúc `docs/system_architecture_and_deep_evaluation.md`.
   - Thực hiện `git commit` & `git push` tự động theo quy tắc dự án.
