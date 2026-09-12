# Thiết kế Hợp nhất Trải nghiệm Người dùng (Gộp Học sinh & Giáo viên) và Khắc phục RLS

## 1. Tổng quan & Mục tiêu

### 1.1 Vấn đề hiện tại
1. **Lỗi RLS `42501` khi đồng bộ vai trò:** Bảng `public.profiles` trên Supabase chỉ có chính sách RLS `SELECT` và `UPDATE`, thiếu chính sách `INSERT`. Khi gọi `upsert`, PostgreSQL kiểm tra quyền `INSERT` và ném lỗi `42501 (new row violates row-level security policy for table "profiles")`.
2. **Tách biệt vai trò cứng nhắc:** Người dùng bị phân chia thành 2 vai trò riêng biệt ("Học sinh" và "Giáo viên") và phải bấm nút chuyển đổi vai trò. Các tính năng cốt lõi như *Tạo đề thi*, *Quản lý đề* và *Tạo phòng thi* bị ẩn khỏi thanh điều hướng nếu người dùng đang ở vai trò Học sinh.
3. **Tràn giao diện (Overflow) trên thanh điều hướng Web:** Khi mở rộng thêm các mục menu trên màn hình kích thước vừa hoặc khi phóng to trình duyệt (Zoom), thanh `TopNavBar` có nguy cơ bị lỗi tràn pixel (`RenderBox overflow`).
4. **Xung đột khi tác giả làm bài thi của chính mình:** Tác giả tự làm đề của mình có thể gây sai lệch kết quả bảng xếp hạng chung.

### 1.2 Mục tiêu thiết kế
- **Một tài khoản cho tất cả (Unified Account):** Mọi tài khoản đăng nhập đều có đầy đủ quyền làm bài thi, luyện thi, tự tạo đề thi và mở phòng thi trực tiếp.
- **Thanh Hot Bar 5 mục cốt lõi trên Web:** Luôn hiển thị trực tiếp 5 chức năng chính: **Home**, **Tìm kiếm**, **Tạo đề thi**, **Đề của tôi**, **Tạo phòng thi**.
- **Chế độ làm việc linh hoạt (Workspace Mode Switch):** Chuyển đổi giữa 🎓 **Học tập & Thi thử** và 📝 **Soạn đề & Quản lý phòng** để giao diện luôn gọn gàng, trực quan.
- **Hồ sơ 2 Tab cân bằng:** Tab 1 (Kết quả học tập, Chuỗi ngày, Huy hiệu, Lịch sử thi) và Tab 2 (Đề đã tạo, Phòng đã mở, Thống kê thí sinh).
- **Khắc phục triệt để lỗi RLS `42501`:** Bổ sung chính sách `INSERT` trên bảng `public.profiles` và tối ưu cơ chế lưu trữ trạng thái.
- **Phân định Chủ phòng và Tự làm đề hợp lý:** Nhận diện chủ phòng khi nhập mã phòng, cho phép tác giả xem trước đề của mình mà không làm sai lệch bảng xếp hạng.

---

## 2. Kiến trúc & Thiết kế Chi tiết

### 2.1 CSDL & Chính sách RLS (Supabase)

#### A. Thêm chính sách RLS `INSERT` trên bảng `public.profiles`
Tạo migration `202609130001_profiles_insert_rls_and_unified_roles.sql`:
```sql
-- Cho phép người dùng tự tạo profile chính mình khi đăng nhập / cập nhật
create policy "users insert own profile" on public.profiles
  for insert with check (id = auth.uid());
```

#### B. Cơ chế cấp quyền Tác giả tự động (`ensure_current_teacher`)
Mọi người dùng đã xác thực (`auth.uid() is not null`) khi tạo đề thi hoặc tạo phòng thi đều được hàm `ensure_current_teacher()` ghi nhận vào bảng `public.teachers` với `owner_user_id = auth.uid()` mà không cần bất kỳ thủ tục phê duyệt hay chuyển đổi vai trò phức tạp nào.

#### C. Xử lý Lượt thi của chính Tác giả
- Bổ sung cột `is_author_preview boolean not null default false` trên bảng `public.attempts`.
- Khi người dùng làm bài thi do chính mình tạo, cờ này được đánh dấu `true` và hàm tính Bảng xếp hạng phòng / đề thi sẽ bỏ qua các lượt thi có `is_author_preview = true`.

---

### 2.2 Thanh Hot Bar Điều hướng Web (`TopNavBar`)

#### A. 5 Mục Menu Cốt lõi
Luôn hiển thị cho mọi người dùng đã đăng nhập hoặc khách:
1. 🏠 **Home** (`/home`): Trang chủ tổng quan.
2. 🔍 **Tìm kiếm** (`/search`): Khám phá kho 27+ đề thi các môn học.
3. ➕ **Tạo đề thi** (`/create_exam`): Công cụ soạn thảo câu hỏi trắc nghiệm.
4. 📁 **Đề của tôi** (`/teacher_exams`): Danh sách các bộ đề do tài khoản tạo (đổi nhãn từ "Quản lý đề" thành "Đề của tôi").
5. ⚡ **Tạo phòng thi** (`/create_room`): Mở phòng thi trực tiếp theo thời gian thực.

#### B. Thiết kế Responsive thích ứng, chống tràn màn hình
- Dùng `LayoutBuilder` / `MediaQuery`:
  - Màn hình rộng (> 1150px): Hiển thị đầy đủ chữ và icon của 5 mục menu.
  - Màn hình trung bình (800px - 1150px): Co giãn khoảng cách giữa các mục (`SizedBox` linh hoạt 12-16px thay vì cố định 32px), nhãn chữ ngắn gọn.
  - Ô "Nhập mã PT": Sử dụng `Flexible` với giới hạn tối đa `maxWidth: 160px` để không chèn ép các nút menu.

---

### 2.3 Màn hình Trang chủ (`HomeScreen`)

#### A. Thanh gạt Chế độ làm việc (Workspace Mode Switcher)
Đặt ngay đầu phần nội dung chính của Trang chủ:
- **[ 🎓 Học tập & Thi thử ]** (Mặc định)
- **[ 📝 Soạn đề & Quản lý ]**

Trạng thái được lưu trong `SharedPreferences` (`active_workspace_mode: 'learning' | 'authoring'`).

#### B. Giao diện theo Chế độ
1. **Khi ở Chế độ Học tập:**
   - Thẻ Chào mừng & Ô nhập mã vào phòng nhanh.
   - Thống kê học tập: Điểm trung bình, Chuỗi ngày học (Streak), Số bài đã nộp.
   - Lưới tính năng học tập: Luyện thi theo môn, Lịch sử làm bài, Bảng xếp hạng học sinh, Bộ sưu tập huy hiệu.
   - Danh sách bài tập đã thi gần đây.
2. **Khi ở Chế độ Soạn đề:**
   - Thống kê giảng dạy/soạn đề: Số bộ đề đã tạo, Số phòng thi đã mở, Tổng lượt thí sinh tham gia.
   - Thao tác nhanh: *Tạo đề thi mới*, *Mở phòng thi mới*.
   - Danh sách các đề thi gần đây của tài khoản (kèm trạng thái Nháp / Đã xuất bản).
   - Danh sách các phòng thi gần đây (Đang mở / Đã kết thúc).

---

### 2.4 Màn hình Hồ sơ Cá nhân (`ProfileScreen`)

Chuyển đổi giao diện sang dạng **2 Tab rõ ràng** (thay vì nút gạt vai trò chuyển đổi máy chủ):
- **Tab 1: 🎓 Học tập & Thành tích**
  - Biểu đồ điểm số các bài thi gần đây.
  - Chuỗi ngày học liên tục (Streak).
  - Danh sách huy hiệu đã đạt được (Chuỗi 5 bài, Điểm tuyệt đối, Phản xạ nhanh, Top 3).
  - Lịch sử chi tiết các bài thi đã làm.
- **Tab 2: 📚 Đề thi & Phòng thi của tôi**
  - Thống kê tổng quan: Số đề đã tạo, Tổng số câu hỏi, Tỷ lệ làm đúng trung bình của học sinh, Phòng thi đông nhất.
  - Danh sách các bộ đề đã soạn (kèm nút sửa nhanh, xuất bản hoặc tạo phòng thi ngay).
  - Danh sách các phòng thi đã tổ chức.

---

### 2.5 Logic Điều hướng Phòng thi (`Join Room Routing`)

Khi người dùng nhập mã phòng thi:
1. Truy vấn thông tin phòng qua `RoomRepository`.
2. Kiểm tra nếu `room.teacher_id == current_user_teacher_id` (người nhập mã là chủ phòng):
   - Chuyển hướng ngay tới **Màn hình Giám sát của Chủ phòng (`TeacherWaitingRoomScreen` / `LiveDashboardScreen`)**.
3. Nếu người nhập mã là thí sinh khác:
   - Chuyển hướng tới **Màn hình Chờ của Thí sinh (`StudentWaitingRoomScreen`)**.

---

## 3. Kế hoạch Kiểm thử (Verification Plan)

### 3.1 Kiểm thử Đơn vị & Tích hợp (Automated Tests)
- `test/utils/supabase_retry_helper_test.dart`: Đảm bảo cơ chế tự động thử lại vẫn hoạt động chuẩn xác.
- `test/screens/profile_screen_test.dart`: Cập nhật kiểm thử cho cấu trúc 2 Tab mới của Hồ sơ cá nhân.
- `test/screens/home_screen_test.dart`: Kiểm thử chuyển đổi Chế độ Học tập / Soạn đề trên Trang chủ.
- `test/widgets/top_nav_bar_test.dart`: Kiểm thử 5 mục menu luôn hiển thị và không gây tràn màn hình (overflow).

### 3.2 Kiểm thử Thực tế trên Trình duyệt (Manual / Web Verification)
- Khởi động app bằng trình duyệt Web.
- Kiểm tra thanh Hot Bar trên các độ phân giải màn hình khác nhau (Zoom 100%, 125%, 150%).
- Thử nghiệm tài khoản tạo đề thi mới -> vào danh sách "Đề của tôi" -> mở phòng thi -> nhập mã phòng thi và xác minh chuyển đúng màn hình.
- Kiểm tra màn hình Hồ sơ chuyển đổi mượt mà giữa Tab Học tập và Tab Đề thi mà không có bất kỳ thông báo lỗi RLS nào trong log.
