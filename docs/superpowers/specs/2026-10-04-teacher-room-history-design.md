# Thiết Kế Chi Tiết: Quản Lý & Lịch Sử Phòng Thi Đã Tạo (Teacher Room History & Management)

**Ngày lập:** 04/10/2026  
**Trạng thái:** Đã duyệt bởi người dùng  
**Tác giả:** Antigravity & Pair Programmer  

---

## 1. Bối Cảnh & Vấn Đề (Context & Motivation)

Hiện tại trong ứng dụng Thi Nhanh, giáo viên hoặc người tổ chức có thể tạo phòng thi trực tiếp thông qua màn hình `/create_room`. Tuy nhiên:
1. **Chưa có trang chuyên biệt quản lý tất cả phòng thi**: Trang `ProfileScreen` chỉ hiển thị danh sách rút gọn vài phòng gần nhất (`recentRooms`), và nút **"Xem tất cả phòng thi"** ở dòng 1311 chỉ hiển thị một thông báo SnackBar tạm thời (`_showSnackBar('Tất cả phòng thi đã được hiển thị')`).
2. **Thiếu công cụ tìm kiếm và lọc trạng thái**: Người dùng không thể tìm kiếm theo mã phòng thi (VD: `PT123456`) hoặc lọc theo các trạng thái quan trọng (`waiting`, `live`, `closed`).
3. **Thao tác hành động chưa liền mạch**: Người tạo phòng cần quay lại phòng chờ đang mở, bảng điều khiển đang thi, hoặc xem lại bảng điểm tổng kết sau khi phòng thi kết thúc một cách nhanh chóng.
4. **Điều hướng từ thanh TopNavBar**: Menu avatar trên TopNavBar hiện chỉ có "Hồ sơ cá nhân", "Lịch sử làm bài" và "Đăng xuất", thiếu lối tắt đến danh sách phòng thi đã tạo.

---

## 2. Mục Tiêu Thiết Kế (Design Goals)

1. **Trang chuyên dụng `/teacher/rooms`**: Cung cấp giao diện hiện đại, đầy đủ tính năng tra cứu, lọc trạng thái, phân trang cho toàn bộ phòng thi do người dùng tạo.
2. **Hành động nhanh theo ngữ cảnh phòng**:
   - Phòng `waiting`: Nút "Vào phòng chờ" (`/teacher_waiting_room?roomId=...`).
   - Phòng `live`: Nút "Bảng theo dõi trực tiếp" (`/live_dashboard?roomId=...`).
   - Phòng `closed`: Nút "Bảng xếp hạng & Kết quả" (`/student/leaderboard?roomId=...`).
   - Sao chép mã phòng (1-click copy).
3. **Responsive 100%**: Hoàn toàn không bị lỗi tràn khung (`RenderFlex overflow`) trên cả thiết bị di động (360x640) lẫn máy tính bàn.
4. **Kiểm thử tự động (TDD)**: Có bộ test widget và service bao phủ toàn bộ các kịch bản lọc, tìm kiếm, phân trang và tương tác.

---

## 3. Kiến Trúc Hệ Thống (Architecture & Data Flow)

### 3.1. Tuyến Đường Điều Hướng (Routes)
- Đăng ký route mới trong `lib/main.dart` thuộc nhánh có `TopNavBar`:
  ```dart
  GoRoute(
    path: '/teacher/rooms',
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const TeacherRoomsHistoryScreen(),
    ),
  ),
  ```

### 3.2. Điểm Truy Cập (Entry Points)
1. **Trang Hồ sơ (`ProfileScreen`)**: Nút *"Xem tất cả phòng thi"* kích hoạt `context.go('/teacher/rooms')`.
2. **Menu Avatar (`TopNavBar`)**: Bổ sung `PopupMenuItem` có giá trị `created_rooms` dẫn tới `/teacher/rooms`.
3. **Smart Back Navigation**: Sử dụng `context.canPop() ? context.pop() : context.go('/profile')`.

### 3.3. Mô Hình Dữ Liệu (`TeacherRoomData`)
Mở rộng đối tượng `TeacherRoomData` trong `lib/core/services/profile_service.dart`:
- `id` (String): ID phòng thi.
- `title` (String): Tên phòng thi.
- `roomCode` (String): Mã code 6 ký tự.
- `date` (String): Ngày tạo hiển thị định dạng `dd/MM/yyyy`.
- `studentsCount` (int): Số lượng thí sinh đã tham gia.
- `statusLabel` (String): Nhãn hiển thị trạng thái ('Đang chờ', 'Đang diễn ra', 'Đã kết thúc').
- `statusType` (String): Mã loại trạng thái ('upcoming' | 'live' | 'ended').
- `examTitle` (String?): Tên đề thi gốc được sử dụng trong phòng thi.
- `examSubject` (String?): Môn học của đề thi.
- `durationMinutes` (int?): Thời gian làm bài của phòng thi.

### 3.4. Dữ Liệu & Service Layer
Bổ sung hàm truy vấn toàn diện `ProfileService.fetchTeacherRoomsSecure`:
- Đầu vào: `userId`, `userEmail`, `search`, `statusFilter` (`all`, `waiting`, `live`, `closed`).
- Đầu ra: Danh sách `List<TeacherRoomData>` được sắp xếp mới nhất lên đầu.
- Hỗ trợ tham số `testRooms` trực tiếp trong `TeacherRoomsHistoryScreen` phục vụ kiểm thử Widget cô lập không phụ thuộc kết nối Supabase.

---

## 4. Thiết Kế Giao Diện Người Dùng (UI / UX Specifications)

### 4.1. Bố Cục Tổng Thể
1. **Thanh Header**:
   - Nút Back (`Icons.arrow_back_rounded`).
   - Tiêu đề: `🏛️ Quản Lý Phòng Thi Đã Tạo`.
   - Nút hành động nổi bật: `+ Tạo phòng mới` (`onPressed: () => context.go('/create_room')`).
2. **Thanh Tìm Kiếm & Lọc Nhanh**:
   - `TextField` tìm kiếm theo tên phòng hoặc mã phòng thi kèm nút xóa nhanh `x`.
   - Hệ thống 4 Tab phân loại trạng thái:
     - **Tất cả phòng** (`all`)
     - **Đang diễn ra** (`live`) - Huy hiệu chấm xanh lá cây nhấp nháy.
     - **Đang chờ** (`waiting`) - Huy hiệu màu hổ phách/cam.
     - **Đã kết thúc** (`closed`) - Huy hiệu màu xám tím.
3. **Thẻ Phòng Thi (`TeacherRoomCard`)**:
   - **Góc trái**: Icon môn học hoặc icon phòng thi `Icons.meeting_room_rounded` trong khối nền bo tròn 14px.
   - **Phần thông tin**:
     - Hàng huy hiệu: Trạng thái phòng (Live/Waiting/Closed) + Tên môn học + Ngày tạo.
     - Tên phòng thi (Font đậm, 16px).
     - Đề thi gốc & thời gian làm bài: `Đề: [Tên đề] • [Thời gian] phút`.
     - Mã phòng thi dạng Chip tương tác: `Mã: PT123456` kèm icon `Icons.copy_rounded` sao chép vào bộ nhớ tạm với thông báo SnackBar xác nhận.
     - Số lượng thí sinh tham gia: `Icons.people_outline` + `${studentsCount} thí sinh`.
   - **Cụm nút hành động**:
     - Nếu `statusType == 'live'`: Nút **"Bảng theo dõi trực tiếp"** (`/live_dashboard?roomId=...`).
     - Nếu `statusType == 'upcoming'`: Nút **"Vào phòng chờ"** (`/teacher_waiting_room?roomId=...`).
     - Nếu `statusType == 'ended'`: Nút **"Bảng xếp hạng & Kết quả"** (`/student/leaderboard?roomId=...`).
4. **Phân Trang**:
   - Tích hợp `GooglePaginationBar` (10 phòng/trang).
   - Tự động cuộn mượt về đầu trang khi đổi trang.
5. **Trạng Thái Trống & Lỗi**:
   - Trạng thái chưa có phòng thi nào: Hiển thị icon thân thiện, lời nhắc và nút "Tạo phòng thi đầu tiên ngay".
   - Trạng thái lọc không có kết quả: Hiển thị nút "Xóa bộ lọc & Thử lại".

---

## 5. Chiến Lược Kiểm Thử (Testing Strategy)

1. **Unit Test Service & Model**:
   - Kiểm tra `TeacherRoomData` khởi tạo và định dạng trường mở rộng.
   - Kiểm tra bộ lọc tìm kiếm và lọc trạng thái logic.
2. **Widget Tests (`test/screens/teacher_rooms_history_screen_test.dart`)**:
   - Test 1: Khởi tạo đầy đủ header, thanh tìm kiếm, 4 tab trạng thái, nút "+ Tạo phòng mới".
   - Test 2: Tìm kiếm theo mã phòng hoặc tên phòng cập nhật danh sách hiển thị.
   - Test 3: Chuyển tab trạng thái ("Đang diễn ra", "Đang chờ", "Đã kết thúc") lọc đúng dữ liệu.
   - Test 4: Không phát sinh bất kỳ lỗi tràn khung `RenderFlex overflow` nào trên màn hình di động nhỏ 360x640.
   - Test 5: Nút sao chép mã phòng và các nút hành động ("Vào phòng chờ", "Bảng theo dõi trực tiếp", "Bảng xếp hạng") gọi đúng route.
3. **Integration Test Điều Hướng**:
   - Nút "Xem tất cả phòng thi" trên `ProfileScreen` điều hướng tới `/teacher/rooms`.
   - Menu avatar trên `TopNavBar` hiển thị và điều hướng tới `/teacher/rooms`.
