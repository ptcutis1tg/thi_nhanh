# Kế hoạch Thực hiện: Hợp nhất Trải nghiệm Người dùng & Khắc phục Lỗi RLS profiles

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hợp nhất vai trò Học sinh và Giáo viên thành một tài khoản duy nhất có đầy đủ quyền (làm bài + tạo đề + mở phòng thi), hiển thị thanh Hot Bar 5 mục cốt lõi trên Web, bổ sung chế độ làm việc (Workspace Mode), chuyển Hồ sơ sang dạng 2 Tab và khắc phục triệt để lỗi phân quyền RLS `42501` trên Supabase.

**Architecture:**
- **Database (Supabase):** Migration bổ sung chính sách RLS `INSERT` trên bảng `public.profiles`, thêm cột `is_author_preview` trên `public.attempts` và đảm bảo mọi tài khoản đăng nhập đều tự động được ghi nhận quyền tác giả trong `public.teachers`.
- **Navigation (Web TopNavBar):** Mở 5 mục menu cốt lõi (`/home`, `/search`, `/create_exam`, `/teacher_exams`, `/create_room`) luôn hiển thị cho mọi người dùng; thiết kế thích ứng (Responsive) chống tràn màn hình.
- **UI (HomeScreen & ProfileScreen):** Trang chủ có thanh gạt Chế độ làm việc (🎓 Học tập | 📝 Soạn đề); Trang Hồ sơ có 2 Tab chuyên biệt (Học tập & Thành tích | Đề thi & Phòng thi của tôi).
- **Logic Routing:** Tự động phát hiện chủ phòng khi nhập mã phòng để điều hướng vào màn hình Giám sát thay vì phòng chờ thí sinh.

**Tech Stack:** Flutter, Dart, Supabase (PostgreSQL + RLS), Provider, GoRouter, SharedPreferences.

## Global Constraints
- Tập trung hoàn thiện 100% trải nghiệm trên nền tảng Web trước.
- Không được làm vỡ bất kỳ luồng thi hoặc dữ liệu thi nào đã có.
- Tuân thủ quy tắc Auto-push: Mỗi khi hoàn thành và kiểm thử xong phải tự động `git commit` và `git push` lên kho lưu trữ.
- Tuân thủ TDD: Viết hoặc cập nhật test trước khi sửa đổi logic.

---

### Task 1: Supabase Migration - Bổ sung RLS INSERT cho profiles & cột is_author_preview

**Files:**
- Create: `supabase/migrations/202609130001_profiles_insert_rls_and_unified_roles.sql`
- Test: Live Supabase DB Verification (via `supabase db push` / `supabase db query`)

**Interfaces:**
- Produces: RLS policy `"users insert own profile"` on `public.profiles`, column `is_author_preview` on `public.attempts`.

- [ ] **Step 1: Viết migration SQL**

Tạo file `supabase/migrations/202609130001_profiles_insert_rls_and_unified_roles.sql`:
```sql
-- Migration: Bổ sung chính sách INSERT cho profiles và cờ xem trước của tác giả
-- 1. Bổ sung policy INSERT cho bảng profiles
drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile" on public.profiles
  for insert with check (id = auth.uid());

-- 2. Bổ sung policy ALL cho service_role nếu cần
drop policy if exists "users delete own profile" on public.profiles;
create policy "users delete own profile" on public.profiles
  for delete using (id = auth.uid());

-- 3. Bổ sung cột is_author_preview trên attempts nếu chưa có
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'attempts' and column_name = 'is_author_preview'
  ) then
    alter table public.attempts add column is_author_preview boolean not null default false;
  end if;
end $$;

-- 4. Đảm bảo ensure_current_teacher cấp quyền tác giả an toàn cho mọi tài khoản
create or replace function public.ensure_current_teacher()
returns uuid language plpgsql security definer set search_path = public as $$
declare v_teacher_id uuid; v_name text;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  select id into v_teacher_id from public.teachers where owner_user_id = auth.uid();
  if v_teacher_id is not null then return v_teacher_id; end if;
  select coalesce(nullif(trim(display_name), ''), nullif(trim(auth.jwt() ->> 'email'), ''), 'Thành viên')
    into v_name from public.profiles where id = auth.uid();
  insert into public.teachers (owner_user_id, display_name)
  values (auth.uid(), coalesce(v_name, 'Thành viên')) returning id into v_teacher_id;
  return v_teacher_id;
end;
$$;
```

- [ ] **Step 2: Đẩy migration lên Supabase Cloud**

Run: `npx --yes supabase db push`
Expected: Success with exit code 0.

- [ ] **Step 3: Kiểm tra các chính sách trên bảng profiles**

Run SQL query: `SELECT policyname, cmd FROM pg_policies WHERE tablename = 'profiles';`
Expected: Xuất hiện đầy đủ `SELECT`, `UPDATE`, `INSERT`, `DELETE`.

- [ ] **Step 4: Commit migration**

```bash
git add supabase/migrations/202609130001_profiles_insert_rls_and_unified_roles.sql
git commit -m "feat(db): add profiles insert rls policy and is_author_preview flag"
git push origin main
```

---

### Task 2: Thanh Hot Bar TopNavBar Responsive cho Web (5 Mục Cốt lõi Luôn Mở)

**Files:**
- Modify: `lib/shared/widgets/top_nav_bar.dart`
- Test: `test/widgets/top_nav_bar_test.dart`

**Interfaces:**
- Produces: `TopNavBar` hiển thị 5 mục: Home (`/home`), Tìm kiếm (`/search`), Tạo đề thi (`/create_exam`), Đề của tôi (`/teacher_exams`), Tạo phòng thi (`/create_room`) mà không bị ẩn bởi `isTeacher`.

- [ ] **Step 1: Viết test cho TopNavBar**

Tạo/cập nhật `test/widgets/top_nav_bar_test.dart`:
- Kiểm tra 5 mục menu luôn xuất hiện dù vai trò là student hay teacher.
- Kiểm tra tiêu đề "Đề của tôi" thay thế cho "Quản lý đề".

- [ ] **Step 2: Chạy test để xác nhận test fail**

Run: `flutter test test/widgets/top_nav_bar_test.dart`
Expected: FAIL (do mục menu vẫn đang bị ẩn sau `if (authProvider.isTeacher)`).

- [ ] **Step 3: Cập nhật `TopNavBar`**

Trong `lib/shared/widgets/top_nav_bar.dart`:
- Bỏ điều kiện `if (authProvider.isTeacher)` để 5 mục luôn hiển thị.
- Đổi nhãn `Quản lý đề` thành `Đề của tôi`.
- Bọc menu bằng `LayoutBuilder` để co giãn padding linh hoạt:
  - Nếu `constraints.maxWidth < 1150`: padding ngang = 14px, khoảng cách giữa các mục = 16px.
  - Nếu `constraints.maxWidth >= 1150`: padding ngang = 28px, khoảng cách = 24px.
- Đặt ô `Nhập mã PT...` thành `Flexible(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 160), child: TextField(...)))` để chống tràn màn hình.

- [ ] **Step 4: Chạy test để xác nhận test pass**

Run: `flutter test test/widgets/top_nav_bar_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/top_nav_bar.dart test/widgets/top_nav_bar_test.dart
git commit -m "feat(nav): surface 5 core hot bar items for all users with responsive layout"
git push origin main
```

---

### Task 3: Trang chủ HomeScreen với Chế độ Làm việc (Workspace Mode Switcher)

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Test: `test/screens/home_screen_test.dart`

**Interfaces:**
- Produces: Thanh gạt `🎓 Học tập & Thi thử` ⇄ `📝 Soạn đề & Quản lý` trên Trang chủ, lưu trạng thái vào `SharedPreferences`.

- [ ] **Step 1: Viết test cho HomeScreen Workspace Mode Switcher**

Tạo/cập nhật `test/screens/home_screen_test.dart`:
- Kiểm tra sự hiện diện của thanh gạt chế độ làm việc.
- Kiểm tra khi nhấn chuyển chế độ sang "Soạn đề & Quản lý", giao diện hiển thị các chỉ số tạo đề và danh sách phòng/đề.

- [ ] **Step 2: Chạy test để xác nhận test fail**

Run: `flutter test test/screens/home_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Cập nhật HomeScreen**

Trong `lib/screens/home/home_screen.dart`:
- Bổ sung biến trạng thái `String _workspaceMode = 'learning'; // 'learning' hoặc 'authoring'`.
- Tải và lưu `_workspaceMode` từ `SharedPreferences` (`active_workspace_mode`).
- Xây dựng widget thanh gạt chế độ đẹp mắt với AnimatedContainer:
  - `🎓 Học tập & Thi thử`
  - `📝 Soạn đề & Quản lý`
- Khi `_workspaceMode == 'learning'`:
  - Hiển thị thống kê điểm số, chuỗi ngày học (`_studentStats`).
  - Lưới 4 tính năng: Luyện thi theo môn, Lịch sử làm bài, Bảng xếp hạng học sinh, Bộ sưu tập huy hiệu.
  - Danh sách bài tập đã nộp gần đây.
- Khi `_workspaceMode == 'authoring'`:
  - Hiển thị thống kê soạn đề: Số đề đã tạo, Số phòng thi đã mở, Thí sinh tham gia (`_teacherStats`).
  - Lưới 4 tính năng: Tạo đề thi mới, Tạo phòng thi mới, Danh sách đề của tôi, Thống kê kết quả thi của học sinh.
  - Danh sách đề thi và phòng thi gần đây của tác giả.

- [ ] **Step 4: Chạy test để xác nhận test pass**

Run: `flutter test test/screens/home_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home/home_screen.dart test/screens/home_screen_test.dart
git commit -m "feat(home): add workspace mode switcher between learning and authoring"
git push origin main
```

---

### Task 4: Hồ sơ Cá nhân ProfileScreen 2 Tab Chuyên biệt

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/core/providers/auth_provider.dart`
- Test: `test/screens/profile_screen_test.dart`

**Interfaces:**
- Produces: `ProfileScreen` hiển thị TabBar với 2 Tab (🎓 Học tập & Thành tích | 📚 Đề thi & Phòng thi của tôi); loại bỏ lệnh gọi `updateActiveRole` gây lỗi 42501.

- [ ] **Step 1: Viết test cho ProfileScreen 2 Tab**

Cập nhật `test/screens/profile_screen_test.dart`:
- Kiểm tra 2 tab "Học tập & Thành tích" và "Đề thi & Phòng thi của tôi" được render đầy đủ.
- Xác nhận không có ngoại lệ RLS 42501 khi mở hồ sơ.

- [ ] **Step 2: Chạy test để xác nhận test fail**

Run: `flutter test test/screens/profile_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Cập nhật ProfileScreen & AuthProvider**

Trong `lib/screens/profile/profile_screen.dart`:
- Chuyển `_isRoleAutoDetected` và khối nút chuyển đổi vai trò thành TabController 2 Tab:
  - Tab 1: `Học tập & Thành tích`
  - Tab 2: `Đề thi & Phòng thi của tôi`
- Loại bỏ lệnh tự động gọi `authProvider.setRole(UserRole.teacher)` gây xung đột RLS.
Trong `lib/core/providers/auth_provider.dart`:
- Trong `updateActiveRole`: Bọc lệnh gọi Supabase bằng `try/catch` an toàn và `SupabaseRetryHelper.run`, lưu vai trò vào `SharedPreferences` để không bao giờ làm gián đoạn trải nghiệm người dùng.

- [ ] **Step 4: Chạy test để xác nhận test pass**

Run: `flutter test test/screens/profile_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/profile/profile_screen.dart lib/core/providers/auth_provider.dart test/screens/profile_screen_test.dart
git commit -m "feat(profile): introduce 2-tab layout for learning and authored exams without role friction"
git push origin main
```

---

### Task 5: Điều hướng Thông minh khi Nhập mã Phòng thi (Chủ phòng vs Thí sinh)

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/shared/widgets/top_nav_bar.dart`
- Test: `test/screens/join_room_flow_test.dart`

**Interfaces:**
- Produces: Hàm xử lý tham gia phòng kiểm tra `room.teacher_id == current_teacher_id`, nếu đúng điều hướng vào `TeacherWaitingRoomScreen` / `LiveDashboardScreen`.

- [ ] **Step 1: Viết test cho flow điều hướng chủ phòng**

Cập nhật `test/screens/join_room_flow_test.dart`:
- Kiểm tra khi người tạo phòng nhập mã phòng của chính mình -> điều hướng tới màn hình quản trị phòng thay vì màn hình thí sinh.

- [ ] **Step 2: Chạy test để xác nhận test fail**

Run: `flutter test test/screens/join_room_flow_test.dart`
Expected: FAIL.

- [ ] **Step 3: Cập nhật hàm `_handleJoinRoom`**

Trong `home_screen.dart` và `top_nav_bar.dart`:
- Trước khi vào phòng chờ thí sinh, kiểm tra thông tin phòng qua `roomRepo.dashboard(roomId)` hoặc kiểm tra mã phòng:
  - Nếu tài khoản hiện tại là chủ tạo phòng -> `context.go('/teacher_waiting_room?roomId=$roomId')`.
  - Nếu không phải chủ phòng -> thực hiện luồng vào phòng của thí sinh bình thường (`/student_waiting_room`).

- [ ] **Step 4: Chạy test để xác nhận test pass**

Run: `flutter test test/screens/join_room_flow_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home/home_screen.dart lib/shared/widgets/top_nav_bar.dart test/screens/join_room_flow_test.dart
git commit -m "feat(room): route room creator directly to host dashboard when entering code"
git push origin main
```

---

### Task 6: Đánh dấu Lượt thi Tác giả (Author Preview) & Không tính Điểm ảo vào Leaderboard

**Files:**
- Modify: `lib/core/repositories/assessment_repository.dart`
- Modify: `lib/screens/exam/taking_exam_screen.dart`
- Test: `test/repositories/assessment_snapshot_test.dart`

**Interfaces:**
- Produces: Cờ `is_author_preview` được kích hoạt khi tác giả làm bài thi của chính mình; hiển thị banner xem trước trên màn hình thi.

- [ ] **Step 1: Viết test cho Author Preview**

Cập nhật test xác nhận lượt thi xem trước được truyền đúng cờ `is_author_preview`.

- [ ] **Step 2: Cập nhật Repository & Màn hình làm bài**

- Trong `TakingExamScreen`: Nếu `exam.teacher_id == current_user_teacher_id`, hiển thị thanh thông báo nhỏ trên đầu: *"Chế độ xem trước của tác giả (không tính vào Bảng xếp hạng công khai)"*.
- Trong `AssessmentRepository`: Khi tác giả làm bài, truyền cờ preview để đánh dấu lượt thi.

- [ ] **Step 3: Chạy test xác nhận pass**

Run: `flutter test test/repositories/assessment_snapshot_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/core/repositories/assessment_repository.dart lib/screens/exam/taking_exam_screen.dart test/repositories/assessment_snapshot_test.dart
git commit -m "feat(exam): add author preview mode to prevent self-exam leaderboard skew"
git push origin main
```

---

### Task 7: Kiểm thử Toàn diện & Đồng bộ CI/CD lên GitHub Pages

**Files:**
- Toàn bộ codebase

- [ ] **Step 1: Chạy toàn bộ test suite của dự án**

Run: `flutter test`
Expected: Tất cả bài test đều PASS 100%.

- [ ] **Step 2: Kiểm tra trạng thái Git**

Run: `git status` trong `thi_nhanh` và parent `CODE`.
Expected: Working tree clean.

- [ ] **Step 3: Đồng bộ Submodule & Push lên Main**

Run:
```bash
cd c:\Users\ADMINE\Desktop\CODE
git add thi_nhanh
git commit -m "chore: sync unified user experience and RLS improvements"
git push origin main
```
Expected: GitHub Actions kích hoạt và deploy bản build mới nhất lên GitHub Pages.
