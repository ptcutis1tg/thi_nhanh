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
    ├── student_waiting_room_screen_test.dart # Test xác nhận đã dọn mock & logic phòng chờ
    ├── teacher_waiting_room_screen_test.dart # Test auto-polling & hiển thị thí sinh
    ├── create_room_screen_test.dart          # Test validation sĩ số & chọn đề thi
    ├── room_password_screen_test.dart        # Test xác thực mật khẩu qua repository
    ├── room_lifecycle_e2e_test.dart          # Test E2E toàn bộ vòng đời phòng thi
    └── widgets/
        └── room_qr_dialog_test.dart          # Test hiển thị mã QR và chia sẻ link
```

---

## Danh sách Task Chi tiết

### Task 1: Dọn dẹp Mock Data & Nút Debug trên Màn hình Chờ Thí sinh (`StudentWaitingRoomScreen`)

**Files:**
- Modify: `lib/screens/room/student_waiting_room_screen.dart:170-250, 510-545`
- Test: `test/screens/student_waiting_room_screen_test.dart`

**Interfaces:**
- Consumes: `StudentRoomState` từ `RoomRepository.getStudentRoomState`
- Produces: Giao diện phòng chờ học sinh trung thực, hiển thị đúng thí sinh hiện có, không có nút mô phỏng debug.

- [x] **Step 1: Viết failing widget test kiểm tra màn hình không chứa nút mô phỏng và không sinh avatar giả khi danh sách rỗng**
- [x] **Step 2: Chạy test để xác nhận test FAIL**
- [x] **Step 3: Xóa bỏ FloatingActionButton "Mô phỏng: Bắt đầu thi"**
- [x] **Step 4: Thay thế Avatar mock bằng Empty State thực tế**
- [x] **Step 5: Xóa fallback mã phòng và môn học giả**
- [x] **Step 6: Chạy lại test và xác nhận PASS**
- [x] **Step 7: Git commit & push** (`da526c6`)

---

### Task 2: Triển khai Auto-Polling & Quản lý Thí sinh Thời gian thực trên `TeacherWaitingRoomScreen`

**Files:**
- Modify: `lib/screens/room/teacher_waiting_room_screen.dart:18-70, 240-300`
- Test: `test/screens/teacher_waiting_room_screen_test.dart`

**Interfaces:**
- Consumes: `RoomRepository.dashboard(roomId)`
- Produces: Phòng chờ giáo viên tự động cập nhật danh sách thí sinh mỗi 3 giây khi ở Tab 0 mà không cần ấn nút Refresh thủ công.

- [x] **Step 1: Viết widget test kiểm tra auto-polling trên TeacherWaitingRoomScreen**
- [x] **Step 2: Chạy test để xác nhận test FAIL**
- [x] **Step 3: Thêm `Timer? _pollTimer` vào `_TeacherWaitingRoomScreenState`**
- [x] **Step 4: Nâng cấp Header hiển thị sĩ số phòng**
- [x] **Step 5: Chạy lại test và xác nhận PASS**
- [x] **Step 6: Git commit & push** (`e7e4e9f`)

---

### Task 3: Nâng cấp Màn hình Tạo Phòng thi (`CreateRoomScreen`) Chuyên nghiệp

**Files:**
- Modify: `lib/screens/room/create_room_screen.dart`
- Test: `test/screens/create_room_screen_test.dart`

**Interfaces:**
- Consumes: `TeacherExamRepository.summaries()`, `RoomRepository.create(examId, name, password, maxParticipants)`
- Produces: Giao diện tạo phòng đầy đủ cấu hình sĩ số, bộ lọc tìm kiếm đề thi và tùy chọn phòng.

- [x] **Step 1: Viết widget test kiểm tra cấu hình sĩ số tối đa và lọc đề**
- [x] **Step 2: Chạy test để xác nhận test FAIL**
- [x] **Step 3: Bổ sung trường chọn Sĩ số tối đa (`maxParticipants`)**
- [x] **Step 4: Nâng cấp Bộ chọn đề thi (Exam Picker)**
- [x] **Step 5: Bổ sung Mục Quy chế phòng thi (Tùy chọn)**
- [x] **Step 6: Chạy lại test và xác nhận PASS**
- [x] **Step 7: Git commit & push** (`281ac12`)

---

### Task 4: Tích hợp Mã QR Động & Deep Link Chia sẻ Phòng thi

**Files:**
- Modify: `pubspec.yaml` (thêm `qr_flutter: ^4.1.0`)
- Create: `lib/screens/room/widgets/room_qr_dialog.dart`
- Modify: `lib/screens/room/teacher_waiting_room_screen.dart:230-245, 390-425`
- Test: `test/screens/widgets/room_qr_dialog_test.dart`

**Interfaces:**
- Consumes: `room.code`, URL schema `https://.../join?code=PTxxxxxx`
- Produces: Card QR code tại phòng chờ và Dialog phóng to toàn màn hình để chiếu máy chiếu.

- [x] **Step 1: Cài đặt dependency `qr_flutter`**
- [x] **Step 2: Tạo component `RoomQrDialog` (`lib/screens/room/widgets/room_qr_dialog.dart`)**
- [x] **Step 3: Nhúng QR thumbnail và nút thao tác vào `_RoomCodeCard` của `TeacherWaitingRoomScreen`**
- [x] **Step 4: Viết và chạy test xác nhận hiển thị QR và tương tác copy**
- [x] **Step 5: Git commit & push** (`e578c57`)

---

### Task 5: Dọn dẹp Code cũ & Hoàn thiện Luồng Nhập Mật khẩu

**Files:**
- Modify: `lib/screens/room/room_password_screen.dart`
- Modify: `lib/main.dart:346-364`
- Test: `test/screens/room_password_screen_test.dart`

**Interfaces:**
- Consumes: `code` query parameter
- Produces: Luồng bảo mật phòng hoàn chỉnh, kết nối API xác thực `joinRoom` thực thụ.

- [x] **Step 1: Hoàn thiện `RoomPasswordScreen`**
- [x] **Step 2: Nhận mã phòng qua query parameter và xác thực qua RoomRepository**
- [x] **Step 3: Chạy toàn bộ test suite để đảm bảo không gãy route**
- [x] **Step 4: Git commit & push** (`e94a22f`)

---

### Task 6: Kiểm thử E2E & Nghiệm thu Tổng thể

**Files:**
- Test: `test/screens/room_lifecycle_e2e_test.dart`

**Interfaces:**
- Kiểm chứng toàn bộ chu trình: Giáo viên Tạo phòng thi (chọn đề, cấu hình sĩ số) -> Chiếu mã QR -> Học sinh vào phòng -> Danh sách thí sinh tự nhảy -> Không còn mock data.

- [x] **Step 1: Viết test kịch bản E2E vòng đời phòng thi**
- [x] **Step 2: Chạy kiểm thử toàn bộ các bộ test tính năng phòng thi (`flutter test`)**
- [x] **Step 3: Phân tích mã nguồn tĩnh (`flutter analyze`) đảm bảo 0 lỗi trong module phòng thi**
- [x] **Step 4: Git commit & push hoàn tất tính năng**
