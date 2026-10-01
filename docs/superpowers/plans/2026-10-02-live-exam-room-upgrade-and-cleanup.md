# Kế hoạch Triển khai: Nâng cấp Toàn diện & Dọn dẹp Mock Data Tính năng Phòng thi (Live Exam Room)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dọn dẹp triệt để dữ liệu mock/debug trong module phòng thi, nâng cấp giao diện tạo phòng thi với tìm kiếm đề và cấu hình sĩ số, bổ sung tự động làm mới danh sách thí sinh và trình chiếu mã QR / Deep Link cho giáo viên.

**Architecture:** Giữ nguyên kiến trúc Clean Repository Pattern (`RoomRepository` gọi Supabase RPCs); loại bỏ các widget/fallback mock còn sót lại; bổ sung Timer auto-polling trên `TeacherWaitingRoomScreen`; mở rộng `CreateRoomScreen` hỗ trợ `maxParticipants`, tìm kiếm & lọc đề thi theo môn; tích hợp `qr_flutter` hiển thị mã QR động và Deep Link chia sẻ phòng thi.

**Tech Stack:** Flutter / Dart, Supabase Flutter RPC, Provider, GoRouter, `qr_flutter: ^4.1.0`, AppTheme.

---

## Global Constraints

- Tuân thủ quy tắc người dùng: Mỗi khi hoàn thành task/sửa code, phải chạy `flutter test`, `git commit` và `git push origin main` để kích hoạt GitHub Actions.
- Tuyệt đối không để sót dữ liệu mock học sinh ('Minh Anh', 'Hải Bình',...) hoặc nút mô phỏng debug trong bản phát hành.
- Giữ vững tương thích ngược với Supabase RPC backend (`create_teacher_room`, `teacher_room_dashboard`, `join_student_room`, `get_room_leaderboard`).
- Đảm bảo giao diện theo chuẩn thiết kế `AppTheme`, hỗ trợ responsive trên cả Web/Desktop (màn hình rộng) và Mobile (màn hình hẹp).

---

## File Structure Map

```
lib/
├── screens/
│   ├── room/
│   │   ├── create_room_screen.dart         # Cải tiến: Thêm chọn sĩ số, tìm kiếm lọc đề thi, cấu hình phòng
│   │   ├── teacher_waiting_room_screen.dart # Cải tiến: Auto-refresh phòng chờ, hiển thị QR code, nút chia sẻ link
│   │   ├── student_waiting_room_screen.dart # Cải tiến: Xóa nút debug, xóa avatar mock, xử lý empty state chuẩn
│   │   ├── room_password_screen.dart       # Sửa lỗi: Nhận tham số code/roomId, gọi joinRoom đúng chuẩn
│   │   └── widgets/
│   │       ├── live_leaderboard_view.dart  # Bảng xếp hạng trực tiếp (đã chuẩn hóa)
│   │       ├── join_room_guest_dialog.dart # Dialog nhập tên/mật khẩu cho khách
│   │       └── room_qr_dialog.dart         # MỚI: Dialog phóng to mã QR trình chiếu lên máy chiếu
│   └── exam/
│       └── live_dashboard_screen.dart      # Dọn dẹp: Chuyển hướng sang TeacherWaitingRoomScreen thống nhất
test/
└── screens/
    └── room/
        ├── student_waiting_room_screen_test.dart # Test xác nhận đã dọn mock & logic phòng chờ
        ├── teacher_waiting_room_screen_test.dart # Test auto-polling & hiển thị thí sinh
        └── create_room_screen_test.dart          # Test validation sĩ số & chọn đề thi
```

---

## Danh sách Task Chi tiết

### Task 1: Dọn dẹp Mock Data & Nút Debug trên Màn hình Chờ Thí sinh (`StudentWaitingRoomScreen`)

**Files:**
- Modify: `lib/screens/room/student_waiting_room_screen.dart:170-250, 510-545`
- Test: `test/screens/room/student_waiting_room_screen_test.dart`

**Interfaces:**
- Consumes: `StudentRoomState` từ `RoomRepository.getStudentRoomState`
- Produces: Giao diện phòng chờ học sinh trung thực, hiển thị đúng thí sinh hiện có, không có nút mô phỏng debug.

- [ ] **Step 1: Viết failing widget test kiểm tra màn hình không chứa nút mô phỏng và không sinh avatar giả khi danh sách rỗng**
  ```dart
  testWidgets('StudentWaitingRoomScreen does not display mock button or fake participants', (tester) async {
    // Render StudentWaitingRoomScreen với danh sách participants = []
    // expect(find.text('Mô phỏng: Bắt đầu thi'), findsNothing);
    // expect(find.text('Minh Anh'), findsNothing);
    // expect(find.text('Hải Bình'), findsNothing);
  });
  ```
- [ ] **Step 2: Chạy test để xác nhận test FAIL**
  ```powershell
  flutter test test/screens/room/student_waiting_room_screen_test.dart
  ```
- [ ] **Step 3: Xóa bỏ FloatingActionButton "Mô phỏng: Bắt đầu thi"**
  - Xóa toàn bộ khối `floatingActionButton: FloatingActionButton.extended(...)` tại `student_waiting_room_screen.dart:177-191`.
- [ ] **Step 4: Thay thế Avatar mock bằng Empty State thực tế**
  - Tại `student_waiting_room_screen.dart:512-523`, xóa danh sách hardcoded `['Bạn', 'Minh Anh', 'Hải Bình', 'Tiến Cường']`.
  - Thay bằng `_buildWaitingEmptyState()`: Hiển thị icon đồng hồ cát nhẹ nhàng kèm thông điệp: *"Bạn đã vào phòng thành công. Hãy đợi giáo viên bấm bắt đầu thi nhé!"*.
- [ ] **Step 5: Xóa fallback mã phòng và môn học giả**
  - Sửa `final code = _roomState?.code ?? 'PT892341'` thành hiển thị `widget.roomId != null ? (_roomState?.code ?? '...') : '--'`.
  - Sửa môn học mặc định từ `'Toán học'` thành lấy trực tiếp từ `_roomState?.subject ?? ''`.
- [ ] **Step 6: Chạy lại test và xác nhận PASS**
  ```powershell
  flutter test test/screens/room/student_waiting_room_screen_test.dart
  ```
- [ ] **Step 7: Git commit & push**
  ```powershell
  git add lib/screens/room/student_waiting_room_screen.dart test/screens/room/student_waiting_room_screen_test.dart
  git commit -m "refactor(room): remove mock avatars, fake room code, and debug button from student waiting room"
  git push origin main
  ```

---

### Task 2: Triển khai Auto-Polling & Quản lý Thí sinh Thời gian thực trên `TeacherWaitingRoomScreen`

**Files:**
- Modify: `lib/screens/room/teacher_waiting_room_screen.dart:18-70, 240-300`
- Test: `test/screens/room/teacher_waiting_room_screen_test.dart`

**Interfaces:**
- Consumes: `RoomRepository.dashboard(roomId)`
- Produces: Phòng chờ giáo viên tự động cập nhật danh sách thí sinh mỗi 3 giây khi ở Tab 0 mà không cần ấn nút Refresh thủ công.

- [ ] **Step 1: Viết widget test kiểm tra auto-polling trên TeacherWaitingRoomScreen**
  ```dart
  testWidgets('TeacherWaitingRoomScreen polls dashboard periodically while waiting', (tester) async {
    // Mock RoomRepository dashboard
    // Pump TeacherWaitingRoomScreen
    // Advance time by 3 seconds
    // Verify dashboard was called again
  });
  ```
- [ ] **Step 2: Chạy test để xác nhận test FAIL**
  ```powershell
  flutter test test/screens/room/teacher_waiting_room_screen_test.dart
  ```
- [ ] **Step 3: Thêm `Timer? _pollTimer` vào `_TeacherWaitingRoomScreenState`**
  - Khởi tạo `_startPolling()` trong `initState()`.
  - Timer chạy chu kỳ 3 giây: Nếu `mounted`, `_selectedTab == 0`, và `_room?.isWaiting == true`, gọi `_load(silent: true)` để cập nhật `_room`.
  - Hủy timer trong `dispose()`.
- [ ] **Step 4: Nâng cấp Header hiển thị sĩ số phòng**
  - Hiển thị thanh tiến độ sĩ số trực quan: `Đã vào: 15 / 40 thí sinh` (thay vì chỉ text tĩnh).
- [ ] **Step 5: Chạy lại test và xác nhận PASS**
  ```powershell
  flutter test test/screens/room/teacher_waiting_room_screen_test.dart
  ```
- [ ] **Step 6: Git commit & push**
  ```powershell
  git add lib/screens/room/teacher_waiting_room_screen.dart test/screens/room/teacher_waiting_room_screen_test.dart
  git commit -m "feat(room): add auto-polling for teacher waiting room participants"
  git push origin main
  ```

---

### Task 3: Nâng cấp Màn hình Tạo Phòng thi (`CreateRoomScreen`) Chuyên nghiệp

**Files:**
- Modify: `lib/screens/room/create_room_screen.dart`
- Test: `test/screens/room/create_room_screen_test.dart`

**Interfaces:**
- Consumes: `TeacherExamRepository.summaries()`, `RoomRepository.create(examId, name, password, maxParticipants)`
- Produces: Giao diện tạo phòng đầy đủ cấu hình sĩ số, bộ lọc tìm kiếm đề thi và tùy chọn phòng.

- [ ] **Step 1: Viết widget test kiểm tra cấu hình sĩ số tối đa và lọc đề**
  ```dart
  testWidgets('CreateRoomScreen allows selecting max participants and filters exams by search query', (tester) async {
    // Test chips sĩ số (30, 40, 50, 100)
    // Test gõ tìm kiếm lọc danh sách đề thi
  });
  ```
- [ ] **Step 2: Chạy test để xác nhận test FAIL**
  ```powershell
  flutter test test/screens/room/create_room_screen_test.dart
  ```
- [ ] **Step 3: Bổ sung trường chọn Sĩ số tối đa (`maxParticipants`)**
  - Thêm state `int _maxParticipants = 40`.
  - Thêm giao diện chọn nhanh (ChoiceChips: `30 học sinh`, `40 học sinh`, `50 học sinh`, `100 học sinh`) kèm trường nhập tự do nếu muốn tùy chỉnh (giới hạn 5 - 500).
  - Truyền `maxParticipants: _maxParticipants` vào `RoomRepository.create(...)`.
- [ ] **Step 4: Nâng cấp Bộ chọn đề thi (Exam Picker)**
  - Thay thế Dropdown đơn giản bằng giao diện chọn đề chuyên nghiệp:
    - Ô tìm kiếm theo tên đề (`TextField` với icon kính lúp).
    - Bộ lọc nhanh theo Môn học (Tất cả, Toán, Văn, Anh, Lý, Hóa, Sinh...).
    - Danh sách đề hiển thị dạng Card trực quan có thông tin: Môn, Số câu hỏi, Thời lượng, Ngày tạo.
    - Click chọn đề sẽ đánh dấu viền xanh nổi bật (`AppTheme.primary`).
- [ ] **Step 5: Bổ sung Mục Quy chế phòng thi (Tùy chọn)**
  - Switch: *Trộn ngẫu nhiên câu hỏi khi vào thi*.
  - Switch: *Cho phép học sinh xem lời giải ngay khi nộp bài*.
- [ ] **Step 6: Chạy lại test và xác nhận PASS**
  ```powershell
  flutter test test/screens/room/create_room_screen_test.dart
  ```
- [ ] **Step 7: Git commit & push**
  ```powershell
  git add lib/screens/room/create_room_screen.dart test/screens/room/create_room_screen_test.dart
  git commit -m "feat(room): upgrade create room screen with capacity selector and exam search"
  git push origin main
  ```

---

### Task 4: Tích hợp Mã QR Động & Deep Link Chia sẻ Phòng thi

**Files:**
- Modify: `pubspec.yaml` (thêm `qr_flutter: ^4.1.0`)
- Create: `lib/screens/room/widgets/room_qr_dialog.dart`
- Modify: `lib/screens/room/teacher_waiting_room_screen.dart:230-245, 390-425`
- Test: `test/screens/room/widgets/room_qr_dialog_test.dart`

**Interfaces:**
- Consumes: `room.code`, URL schema `https://.../join?code=PTxxxxxx`
- Produces: Card QR code tại phòng chờ và Dialog phóng to toàn màn hình để chiếu máy chiếu.

- [ ] **Step 1: Cài đặt dependency `qr_flutter`**
  - Cập nhật `pubspec.yaml` với `qr_flutter: ^4.1.0`.
  - Chạy `flutter pub get`.
- [ ] **Step 2: Tạo component `RoomQrDialog` (`lib/screens/room/widgets/room_qr_dialog.dart`)**
  - Màn hình trình chiếu máy chiếu (Presentation View):
    - Tiêu đề phòng thi to rõ ràng.
    - Mã phòng font lớn (size 48, monospace).
    - Widget `QrImageView` kích thước lớn (size 320x320) viền cong, nền trắng tương phản cao.
    - Hướng dẫn: *"Mở camera quét mã QR hoặc vào app nhập mã để tham gia"*.
    - Nút đóng toàn màn hình.
- [ ] **Step 3: Nhúng QR thumbnail và nút thao tác vào `_RoomCodeCard` của `TeacherWaitingRoomScreen`**
  - Hiển thị QR thu nhỏ (size 80x80) cạnh mã số phòng thi.
  - Thêm nút icon `Icons.fullscreen`: Click mở `RoomQrDialog`.
  - Thêm nút `OutlinedButton.icon`: **"Sao chép link vào phòng"** (Copy link vào Clipboard và báo SnackBar).
- [ ] **Step 4: Viết và chạy test xác nhận hiển thị QR và tương tác copy**
  ```powershell
  flutter test test/screens/room/widgets/room_qr_dialog_test.dart
  ```
- [ ] **Step 5: Git commit & push**
  ```powershell
  git add pubspec.yaml pubspec.lock lib/screens/room/widgets/room_qr_dialog.dart lib/screens/room/teacher_waiting_room_screen.dart test/screens/room/widgets/room_qr_dialog_test.dart
  git commit -m "feat(room): add dynamic QR code presentation and share link to teacher waiting room"
  git push origin main
  ```

---

### Task 5: Dọn dẹp Code cũ (`LiveDashboardScreen`) & Hoàn thiện Luồng Nhập Mật khẩu

**Files:**
- Modify: `lib/screens/room/room_password_screen.dart`
- Modify: `lib/main.dart:346-364`
- Remove / Refactor: `lib/screens/exam/live_dashboard_screen.dart`
- Test: `test/screens/room/room_password_screen_test.dart`

**Interfaces:**
- Consumes: `code` query parameter
- Produces: Luồng bảo mật phòng hoàn chỉnh, loại bỏ hoàn toàn các file mồ côi chứa code giả lập.

- [ ] **Step 1: Hoàn thiện `RoomPasswordScreen`**
  - Nhận `code` từ route query parameter.
  - Khi ấn xác nhận, gọi `RoomRepository.joinRoom(code: code, password: password)` qua API thật thay vì điều hướng rỗng.
  - Chuyển hướng thí sinh vào đúng `StudentWaitingRoomScreen` kèm `roomId` và `participantId`.
- [ ] **Step 2: Dọn dẹp route `/live_dashboard`**
  - Chuyển hướng route `/live_dashboard` sang `/teacher_waiting_room` hoặc gỡ bỏ import file cũ `live_dashboard_screen.dart` để tránh phân mảnh kiến trúc.
- [ ] **Step 3: Chạy toàn bộ test suite để đảm bảo không gãy route**
  ```powershell
  flutter test
  ```
- [ ] **Step 4: Git commit & push**
  ```powershell
  git add lib/screens/room/room_password_screen.dart lib/main.dart lib/screens/exam/live_dashboard_screen.dart test/screens/room/room_password_screen_test.dart
  git commit -m "refactor(room): fix room password verification flow and deprecate legacy dashboard"
  git push origin main
  ```

---

### Task 6: Kiểm thử E2E & Nghiệm thu Tổng thể

**Files:**
- Test: `test/e2e/room_lifecycle_test.dart`

**Interfaces:**
- Kiểm chứng toàn bộ chu trình: Giáo viên Tạo phòng thi (chọn đề, cấu hình sĩ số) -> Chiếu mã QR -> Học sinh vào phòng -> Danh sách thí sinh tự nhảy -> Giáo viên bấm Bắt đầu thi -> Bảng xếp hạng trực tiếp.

- [ ] **Step 1: Viết test kịch bản E2E vòng đời phòng thi**
- [ ] **Step 2: Chạy kiểm thử toàn bộ dự án (`flutter test`)**
- [ ] **Step 3: Phân tích mã nguồn tĩnh (`flutter analyze`) đảm bảo 0 warning / 0 lint error**
- [ ] **Step 4: Git commit & push hoàn tất tính năng**
  ```powershell
  git commit -m "chore(room): complete live exam room feature upgrade and verification"
  git push origin main
  ```
