# Quản Lý & Lịch Sử Phòng Thi Đã Tạo (Teacher Room History) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng màn hình chuyên biệt "Quản lý & Lịch sử phòng thi đã tạo" (`/teacher/rooms`) cho giáo viên/người tổ chức với bộ lọc trạng thái, tìm kiếm mã phòng, sao chép mã code, vào lại phòng chờ/bảng điều khiển/bảng xếp hạng và kết nối từ ProfileScreen và TopNavBar.

**Architecture:** Màn hình độc lập `TeacherRoomsHistoryScreen` kết nối `RoomRepository` và `ProfileService`, hỗ trợ dependency injection `testRooms` phục vụ kiểm thử cô lập TDD, thiết kế giao diện responsive chống tràn khung, phân trang bằng `GooglePaginationBar`.

**Tech Stack:** Flutter, GoRouter, Provider (`AuthProvider`), Supabase Flutter (`rooms` table).

## Global Constraints

- Tuân thủ quy tắc Auto-push: Hoàn thành mỗi task phải chạy `flutter test`, `git commit` và `git push origin main`.
- Áp dụng triệt để TDD: Viết test failing trước, chạy xác nhận fail, hiện thực code tối thiểu để pass, chạy test xác nhận pass.
- Đảm bảo 100% không phát sinh lỗi tràn khung (`RenderFlex overflow`) trên mọi kích thước màn hình kể cả di động nhỏ (360x640).

---

### Task 1: Mở Rộng Model `TeacherRoomData` & Data Service

**Files:**
- Modify: `lib/core/services/profile_service.dart:129-180`
- Modify: `lib/core/services/profile_service.dart:740-800`
- Test: `test/services/teacher_room_service_test.dart`

**Interfaces:**
- Consumes: Supabase `rooms` table
- Produces: `TeacherRoomData` with fields (`id`, `title`, `roomCode`, `date`, `studentsCount`, `statusLabel`, `statusType`, `examTitle`, `examSubject`, `durationMinutes`) and `ProfileService.fetchTeacherRoomsSecure(...)`

- [ ] **Step 1: Viết test cho `TeacherRoomData` và hàm truy vấn trong `teacher_room_service_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('TeacherRoomData & Service Tests', () {
    test('TeacherRoomData parses extended fields correctly', () {
      final room = TeacherRoomData(
        id: 'r1',
        title: 'Phòng kiểm tra 15 phút Toán',
        roomCode: 'PT123456',
        date: '04/10/2026',
        studentsCount: 25,
        statusLabel: 'Đang diễn ra',
        statusType: 'live',
        examTitle: 'Đề Toán Giải Tích 12',
        examSubject: 'Toán',
        durationMinutes: 15,
      );

      expect(room.id, 'r1');
      expect(room.roomCode, 'PT123456');
      expect(room.examTitle, 'Đề Toán Giải Tích 12');
      expect(room.examSubject, 'Toán');
      expect(room.durationMinutes, 15);
      expect(room.statusType, 'live');
    });
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test fail**

Run: `flutter test test/services/teacher_room_service_test.dart`
Expected: FAIL do các trường `examTitle`, `examSubject`, `durationMinutes` chưa được định nghĩa trong `TeacherRoomData`.

- [ ] **Step 3: Mở rộng `TeacherRoomData` và cập nhật hàm nạp trong `ProfileService`**

Trong `lib/core/services/profile_service.dart`:
```dart
class TeacherRoomData {
  final String id;
  final String title;
  final String roomCode;
  final String date;
  final int studentsCount;
  final String statusLabel;
  final String statusType; // 'live', 'ended', 'upcoming'
  final String? examTitle;
  final String? examSubject;
  final int? durationMinutes;

  TeacherRoomData({
    required this.id,
    required this.title,
    required this.roomCode,
    required this.date,
    required this.studentsCount,
    required this.statusLabel,
    required this.statusType,
    this.examTitle,
    this.examSubject,
    this.durationMinutes,
  });
}
```

- [ ] **Step 4: Chạy lại test để xác nhận test pass**

Run: `flutter test test/services/teacher_room_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit và Push**

```bash
git add lib/core/services/profile_service.dart test/services/teacher_room_service_test.dart ; git commit -m "feat(room): extend TeacherRoomData with exam metadata" ; git push origin main
```

---

### Task 2: Đăng Ký Tuyến Đường `/teacher/rooms` & Smart Back Navigation

**Files:**
- Create: `lib/screens/teacher/teacher_rooms_history_screen.dart`
- Modify: `lib/main.dart`
- Test: `test/screens/teacher_rooms_navigation_test.dart`

**Interfaces:**
- Consumes: GoRouter context
- Produces: Màn hình khung `TeacherRoomsHistoryScreen` và route `/teacher/rooms`

- [ ] **Step 1: Viết test cho route điều hướng và nút back thông minh**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/teacher/teacher_rooms_history_screen.dart';

void main() {
  testWidgets('TeacherRoomsHistoryScreen renders basic title and handles back button', (tester) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (ctx, _) => Scaffold(
            body: ElevatedButton(
              onPressed: () => ctx.push('/teacher/rooms'),
              child: const Text('Go To Rooms'),
            ),
          ),
        ),
        GoRoute(
          path: '/teacher/rooms',
          builder: (_, __) => const TeacherRoomsHistoryScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go To Rooms'));
    await tester.pumpAndSettle();

    expect(find.text('🏛️ Quản Lý Phòng Thi Đã Tạo'), findsOneWidget);

    final backBtn = find.byTooltip('Quay lại');
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('Go To Rooms'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Tạo màn hình khung `TeacherRoomsHistoryScreen` và đăng ký route trong `main.dart`**

Trong `lib/screens/teacher/teacher_rooms_history_screen.dart`:
Tạo `StatefulWidget` hỗ trợ tham số `testRooms` và nút back dùng `context.canPop() ? context.pop() : context.go('/profile')`.
Trong `lib/main.dart`:
Import và thêm `GoRoute(path: '/teacher/rooms', ...)` vào nhánh ShellRoute có TopNavBar.

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/teacher_rooms_navigation_test.dart`
Expected: PASS

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/teacher/teacher_rooms_history_screen.dart lib/main.dart test/screens/teacher_rooms_navigation_test.dart ; git commit -m "feat(room): register /teacher/rooms route with smart back navigation" ; git push origin main
```

---

### Task 3: Kết Nối Điểm Truy Cập (ProfileScreen & TopNavBar Avatar Menu)

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart:1305-1320`
- Modify: `lib/shared/widgets/top_nav_bar.dart:160-205`
- Test: `test/screens/profile_screen_history_test.dart`
- Test: `test/widgets/top_nav_bar_test.dart`

**Interfaces:**
- Consumes: `context.go('/teacher/rooms')`
- Produces: Direct navigation from ProfileScreen room section and TopNavBar avatar menu

- [ ] **Step 1: Viết test cho nút "Xem tất cả phòng thi" và Menu Avatar**

Trong `test/screens/profile_screen_history_test.dart`: Thêm test kiểm tra nhấn "Xem tất cả phòng thi" điều hướng sang `/teacher/rooms`.
Trong `test/widgets/top_nav_bar_test.dart`: Thêm test kiểm tra Avatar PopupMenu có mục "Phòng thi đã tạo".

- [ ] **Step 2: Cập nhật `ProfileScreen` và `TopNavBar`**

1. Trong `lib/screens/profile/profile_screen.dart`:
Thay thế `onPressed: () => _showSnackBar('Tất cả phòng thi đã được hiển thị')` bằng `onPressed: () => context.go('/teacher/rooms')`.
2. Trong `lib/shared/widgets/top_nav_bar.dart`:
Bổ sung `PopupMenuItem(value: 'created_rooms', child: ... Text('Phòng thi đã tạo'))` và xử lý điều hướng `context.go('/teacher/rooms')`.

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/profile_screen_history_test.dart test/widgets/top_nav_bar_test.dart`
Expected: PASS

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/profile/profile_screen.dart lib/shared/widgets/top_nav_bar.dart test/screens/profile_screen_history_test.dart test/widgets/top_nav_bar_test.dart ; git commit -m "feat(nav): connect ProfileScreen and TopNavBar to /teacher/rooms" ; git push origin main
```

---

### Task 4: Bộ Lọc Trạng Thái (4 Tabs), Tìm Kiếm & Bố Cục Mobile Responsive

**Files:**
- Modify: `lib/screens/teacher/teacher_rooms_history_screen.dart`
- Test: `test/screens/teacher_rooms_history_screen_test.dart`

**Interfaces:**
- Consumes: Screen constraints (<650px, <900px, >=900px)
- Produces: Search bar (name/code), 4 tabs (`all`, `live`, `waiting`, `closed`), zero overflow on 360x640 mobile screen

- [ ] **Step 1: Viết test cho tìm kiếm, chuyển tab trạng thái và responsive mobile**

```dart
testWidgets('TeacherRoomsHistoryScreen filters by search, switches status tabs and renders without overflow on 360x640', (tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // pump TeacherRoomsHistoryScreen with testRooms (1 live, 1 waiting, 1 closed)
  // Verify 4 tabs exist: Tất cả, Đang diễn ra, Đang chờ, Đã kết thúc
  // Search code 'PT111' -> verify filtering
  // Tap tab 'Đang diễn ra' -> verify filtering
  // Verify 0 overflow exception
});
```

- [ ] **Step 2: Hiện thực Hộp tìm kiếm, 4 Tab lọc và Bố cục Responsive**

1. Khai báo `_searchQuery`, `_statusFilter = 'all'`.
2. Hàm lọc `_filteredRooms`: lọc theo từ khóa tìm kiếm (tên phòng, mã code) và lọc theo tab trạng thái.
3. Hộp tìm kiếm bo góc 16px, icon kính lúp, nút xóa `x`.
4. Hàng 4 Tab trạng thái bọc trong container bo góc 14px với `Flexible` text chống tràn.
5. `LayoutBuilder` tự động thích ứng với màn hình nhỏ (< 650px).

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/teacher_rooms_history_screen_test.dart`
Expected: PASS không có bất kỳ RenderFlex overflow nào.

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/teacher/teacher_rooms_history_screen.dart test/screens/teacher_rooms_history_screen_test.dart ; git commit -m "feat(room): implement search, status tabs and responsive layout" ; git push origin main
```

---

### Task 5: Thiết Kế Thẻ Phòng Thi (`TeacherRoomCard`), Sao Chép Mã & Nút Hành Động

**Files:**
- Modify: `lib/screens/teacher/teacher_rooms_history_screen.dart`
- Test: `test/screens/teacher_rooms_history_screen_test.dart`

**Interfaces:**
- Consumes: `TeacherRoomData` (`statusType`, `roomCode`, `studentsCount`, etc.)
- Produces: Thẻ phòng thi hoàn chỉnh với 1-click copy mã phòng, nút điều hướng tương ứng với từng trạng thái phòng, phân trang `GooglePaginationBar`.

- [ ] **Step 1: Viết test cho Thẻ phòng thi và các nút hành động theo trạng thái**

```dart
testWidgets('TeacherRoomCard displays code, copies to clipboard, and shows contextual action buttons', (tester) async {
  // Test room waiting -> button "Vào phòng chờ"
  // Test room live -> button "Bảng theo dõi trực tiếp"
  // Test room closed -> button "Bảng xếp hạng & Kết quả"
  // Test 1-click copy code
});
```

- [ ] **Step 2: Hiện thực `TeacherRoomCard` và thanh phân trang**

1. Thẻ phòng thi thiết kế hiện đại, viền `0xFFEBE6FC`, hiệu ứng bo góc 16px.
2. Badge trạng thái màu sắc phân cấp:
   - `live`: Nền xanh lá `0xFFDCFCE7`, chữ `0xFF166534`.
   - `waiting`: Nền vàng `0xFFFEF3C7`, chữ `0xFFB45309`.
   - `closed`: Nền xám tím `0xFFF3F4F6`, chữ `0xFF4B5563`.
3. Badge mã phòng kèm nút sao chép `Clipboard.setData(ClipboardData(text: room.roomCode))` + `ScaffoldMessenger.showSnackBar('Đã sao chép mã phòng: ...')`.
4. Nút hành động tương ứng:
   - `waiting` -> `context.go('/teacher_waiting_room?roomId=${room.id}')`
   - `live` -> `context.go('/live_dashboard?roomId=${room.id}')`
   - `closed` -> `context.go('/student/leaderboard?roomId=${room.id}')`
5. Tích hợp `GooglePaginationBar` khi danh sách vượt quá 10 phòng.

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/teacher_rooms_history_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/teacher/teacher_rooms_history_screen.dart test/screens/teacher_rooms_history_screen_test.dart ; git commit -m "feat(room): design TeacherRoomCard with copy code, contextual actions and pagination" ; git push origin main
```

---

### Task 6: Kiểm Thử Toàn Diện & Toàn Bộ Hệ Thống (Regression Suite)

**Files:**
- Toàn bộ test suite trong thư mục `test/`

- [ ] **Step 1: Chạy toàn bộ test suite**

Run: `flutter test`
Expected: 100% test cases pass không có lỗi.

- [ ] **Step 2: Commit & Push xác nhận cuối cùng**

```bash
git status
git push origin main
```
