# Báo Cáo Nghiệm Thu: Hợp Nhất Trải Nghiệm & Khắc Phục RLS 42501

> **Phương pháp:** Superpowers Subagent-Driven Development  
> **Nguyên tắc sắt:** *Evidence Before Claims* (Mọi kết luận hoàn thành đều kèm bằng chứng log kiểm thử)  
> **Tự động hóa CI/CD:** Auto-push song song cả submodule `thi_nhanh` và kho gốc `CODE`

---

## 1. Tóm Tắt Kết Quả & Bằng Chứng Thực Nghiệm

| Nhiệm Vụ | Mục Tiêu Kỹ Thuật | Bằng Chứng Kiểm Thử / DB | Trạng Thái | Commit Git |
| :--- | :--- | :--- | :---: | :---: |
| **Task 1: Supabase RLS** | Khắc phục lỗi `42501` khi upsert profile; thêm `is_author_preview` | Migration `202609130001` applied; `pg_policies` có đủ `INSERT`, `SELECT`, `UPDATE`, `DELETE` | ✅ Hoàn thành | `e589911` |
| **Task 2: Web Hot Bar** | Mở 5 mục cốt lõi (`Home`, `Tìm kiếm`, `Tạo đề thi`, `Đề của tôi`, `Tạo phòng thi`) cho mọi người dùng | `test/widgets/top_nav_bar_test.dart` PASS (1/1 test) | ✅ Hoàn thành | `f91374d` |
| **Task 3: Workspace Mode** | Thanh gạt `🎓 Học tập & Thi thử` ⇄ `📝 Soạn đề & Quản lý` trên Trang chủ | `test/screens/home_screen_test.dart` PASS (2/2 tests) | ✅ Hoàn thành | `a0c5d6a` |
| **Task 4: Profile 2-Tab** | Hồ sơ 2 Tab (`Học tập & Thành tích` \| `Đề thi & Phòng thi của tôi`), xóa xung đột role | `test/screens/profile_screen_test.dart` PASS (1/1 test) | ✅ Hoàn thành | `a0bf44c` |
| **Task 5: Smart Room Join** | Nhập mã phòng: nếu là chủ phòng -> vào Dashboard quản trị, nếu là thí sinh -> vào phòng chờ | `test/screens/join_room_flow_test.dart` PASS (2/2 tests) | ✅ Hoàn thành | `a394b31` |
| **Task 6: Author Preview** | Banner xem trước đề thi cho tác giả & không tính điểm ảo vào BXH | `test/screens/taking_exam_preview_test.dart` PASS (2/2 tests) | ✅ Hoàn thành | `a00102b` |
| **Task 7: Toàn Bộ Test Suite** | Kiểm thử hồi quy toàn diện trên toàn bộ codebase | `flutter test` PASS **65/65 tests (100%)** | ✅ Hoàn thành | `0dc8268` |

---

## 2. Chi Tiết Kỹ Thuật Từng Tính Năng

### 2.1. Khắc phục lỗi Supabase RLS 42501 (Task 1)
- **Nguyên nhân gốc:** Bảng `public.profiles` trước đó chỉ có chính sách `UPDATE` và `SELECT`, thiếu chính sách `INSERT`. Khi PostgREST gọi `.upsert()`, PostgreSQL bắt buộc phải kiểm tra quyền `INSERT` trước khi xử lý xung đột (`ON CONFLICT DO UPDATE`).
- **Khắc phục:** 
  - Đã thêm policy `"users insert own profile"` với điều kiện `check (id = auth.uid())`.
  - Cập nhật hàm `ensure_current_teacher()` tự động ghi nhận mọi tài khoản đăng nhập vào bảng `public.teachers`.

### 2.2. Thanh Hot Bar 5 Mục Cốt Lõi Trên Web (Task 2)
- **Vị trí file:** [top_nav_bar.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/shared/widgets/top_nav_bar.dart)
- **Cải tiến:**
  - Bỏ hoàn toàn rào cản `if (authProvider.isTeacher)`. Cả 5 mục cốt lõi luôn hiện diện trên thanh điều hướng Web:
    1. `Home` (`/home`)
    2. `Tìm kiếm` (`/search`)
    3. `Tạo đề thi` (`/create_exam`)
    4. `Đề của tôi` (`/teacher_exams`) — đổi từ tên cũ "Quản lý đề"
    5. `Tạo phòng thi` (`/create_room`)
  - Thiết kế thích ứng với `SingleChildScrollView(scrollDirection: Axis.horizontal)` và `ConstrainedBox(maxWidth: 130..160)` cho ô nhập mã phòng, chống triệt để lỗi RenderFlex overflow khi co kéo trình duyệt.

### 2.3. Chế Độ Làm Việc Workspace Mode Switcher trên Trang Chủ (Task 3)
- **Vị trí file:** [home_screen.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/home/home_screen.dart)
- **Cải tiến:**
  - Bổ sung thanh chuyển đổi 2 chế độ làm việc dạng pill hiện đại:
    - `🎓 Học tập & Thi thử`: Hiển thị chuỗi ngày học, điểm trung bình, danh mục luyện thi và lịch sử làm bài gần đây.
    - `📝 Soạn đề & Quản lý`: Hiển thị số đề đã soạn, số phòng thi, thí sinh tham gia và danh sách đề thi / phòng thi đã tạo.
  - Tự động lưu và phục hồi lựa chọn của người dùng vào `SharedPreferences` (`active_workspace_mode`).

### 2.4. Trang Hồ Sơ ProfileScreen Dạng 2 Tab Chuyên Biệt (Task 4)
- **Vị trí file:** [profile_screen.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/profile/profile_screen.dart) & [auth_provider.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/core/providers/auth_provider.dart)
- **Cải tiến:**
  - Loại bỏ hoàn toàn nút bấm đổi vai trò gây hiểu lầm và lỗi phân quyền; thay bằng huy hiệu **"✨ Tài khoản Toàn quyền"**.
  - Chia tách thành 2 Tab rõ ràng:
    - **Tab 1: 🎓 Học tập & Thành tích:** Thống kê kết quả thi cá nhân, biểu đồ điểm số, bộ sưu tập huy hiệu, lịch sử làm bài.
    - **Tab 2: 📚 Đề thi & Phòng thi của tôi:** Quản lý kho đề thi đã tạo, các phòng thi trực tiếp, thống kê thí sinh tham gia.
  - Sửa lỗi tràn màn hình `RenderFlex overflow` trong `_buildHeaderStats` bằng `Flexible` và nhãn rút gọn.
  - Bọc hàm `updateActiveRole` bằng `SupabaseRetryHelper.run` và try-catch an toàn.

### 2.5. Điều Hướng Thông Minh Khi Nhập Mã Phòng Thi (Task 5)
- **Vị trí file:** [home_screen.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/home/home_screen.dart), [top_nav_bar.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/shared/widgets/top_nav_bar.dart), [room_repository.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/core/repositories/room_repository.dart)
- **Cải tiến:**
  - Triển khai RPC `find_hosted_room(p_code)` trên Supabase Cloud (`202609130002_find_hosted_room_rpc.sql`).
  - Khi người dùng nhập mã phòng:
    - Nếu mã phòng thuộc về chính tài khoản đó tạo ra -> Tự động chuyển thẳng tới màn hình Giám sát chủ phòng (`/teacher_waiting_room?roomId=...`).
    - Nếu là người tham gia khác -> Thực hiện luồng vào phòng của thí sinh bình thường (`/student_waiting_room`).

### 2.6. Chế Độ Xem Trước Của Tác Giả (Task 6)
- **Vị trí file:** [taking_exam_screen.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/exam/taking_exam_screen.dart), [assessment.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/core/models/assessment.dart)
- **Cải tiến:**
  - Khi tác giả tự làm bài thi của chính mình, màn hình làm bài sẽ hiển thị thanh thông báo màu hổ phách trang trọng:
    *"Chế độ xem trước của tác giả (không tính vào Bảng xếp hạng công khai)"*.
  - Lượt nộp bài được đánh dấu cờ `is_author_preview = true` trên Supabase `attempts`.

---

## 3. Nhật Ký Kiểm Thử Chi Tiết (Evidence Log)

```
00:00 +0: loading test/screens/home_screen_test.dart
00:01 +2: All tests passed!

00:00 +0: loading test/screens/profile_screen_test.dart
00:01 +1: All tests passed!

00:00 +0: loading test/screens/join_room_flow_test.dart
00:01 +2: All tests passed!

00:00 +0: loading test/screens/taking_exam_preview_test.dart
00:00 +2: All tests passed!

00:00 +0: loading test/widgets/top_nav_bar_test.dart
00:01 +1: All tests passed!

==================================================
TỔNG KẾT TOÀN BỘ SUITE KIỂM THỬ:
00:22 +65: All tests passed! (65/65 tests PASS 100%)
==================================================
```

---

## 4. Tình Trạng Kho Lưu Trữ & CI/CD
- **Submodule `thi_nhanh`:** Nhánh `main`, commit mới nhất `a00102b`, working tree sạch, đã push lên GitHub.
- **Parent Repository `CODE`:** Nhánh `main`, commit mới nhất `0dc8268`, working tree sạch, đã push lên GitHub.
- **GitHub Actions:** Tự động kích hoạt build và deploy bản mới nhất lên GitHub Pages.
