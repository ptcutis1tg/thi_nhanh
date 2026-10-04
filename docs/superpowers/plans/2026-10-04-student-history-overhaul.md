# Kế Hoạch Triển Khai Nâng Cấp Tính Năng Lịch Sử Làm Bài (Student Test History Overhaul)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Khắc phục triệt để các lỗi logic (mất bài thi khi đóng phòng, nút quay lại cứng, trùng lặp route), xử lý dứt điểm lỗi tràn giao diện trên mobile, và nâng cấp toàn diện giao diện lịch sử bài làm học sinh với 3 Tab chế độ thi, thẻ bài giàu thông tin và menu truy cập nhanh trên TopNavBar.

**Architecture:** Mở rộng mô hình `StudentTestHistoryData` và dịch vụ `ProfileService` để hỗ trợ trạng thái `expired`, thời gian làm bài `durationSeconds`, mã phòng `roomCode` và trạng thái công bố điểm `resultReleased`. Tái cấu trúc giao diện `StudentHistoryScreen` sử dụng `LayoutBuilder` thích ứng với mobile (Wrap metric cards, ModalBottomSheet lọc), thêm 3 Tab phân loại và làm mới thiết kế thẻ bài thi. Bổ sung `PopupMenuButton` trên `TopNavBar` để truy cập trực tiếp 1 chạm.

**Tech Stack:** Flutter, Dart, Provider (`AuthProvider`), GoRouter, Supabase (`attempts`, `rooms`, `exams`), Flutter Test (`testWidgets`).

---

## Global Constraints

- Tuân thủ nguyên tắc TDD (Test-Driven Development): Viết bài kiểm thử trước, xác nhận test fail, sau đó mới viết mã hiện thực để pass.
- Đảm bảo tính tương thích giao diện trên màn hình di động nhỏ (360x640px) tuyệt đối không có lỗi RenderFlex overflow.
- Tự động chạy `flutter test`, `git commit` và `git push origin main` sau mỗi nhiệm vụ hoàn thành theo quy định của dự án.

---

## Danh Sách Nhiệm Vụ

### Task 1: Mở rộng Model `StudentTestHistoryData` và Khắc phục Lỗi Logic trong `ProfileService`

**Files:**
- Modify: `lib/core/services/profile_service.dart:21-48`
- Modify: `lib/core/services/profile_service.dart:270-325`
- Modify: `lib/core/services/profile_service.dart:429-470`
- Test: `test/services/student_history_service_test.dart`

**Interfaces:**
- Consumes: `attempts` table rows (`id, exam_id, room_id, score, status, started_at, submitted_at, result_released_at, exams(title, subject), rooms(code, name, status)`)
- Produces: `StudentTestHistoryData` with fields: `roomId`, `roomCode`, `durationSeconds`, `isLiveRoom`, `resultReleased`, `durationFormatted`

- [ ] **Step 1: Viết test kiểm tra phân tích Model và logic lọc trạng thái `expired`**

```dart
// test/services/student_history_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('StudentTestHistoryData Model & Logic Tests', () {
    test('parses extended fields including roomCode, duration and resultReleased', () {
      final item = StudentTestHistoryData(
        id: 'att-123',
        subjectIcon: '📐',
        title: 'Kiểm tra 15 phút Toán',
        date: '04/10/2026',
        score: '8.5 điểm',
        scoreValue: 8.5,
        subject: 'Toán',
        roomId: 'room-uuid-1',
        roomCode: 'PT123456',
        durationSeconds: 1110, // 18 phút 30 giây
        isLiveRoom: true,
        resultReleased: true,
      );

      expect(item.id, 'att-123');
      expect(item.roomCode, 'PT123456');
      expect(item.isLiveRoom, isTrue);
      expect(item.resultReleased, isTrue);
      expect(item.durationFormatted, '18:30');
    });

    test('durationFormatted formats seconds into mm:ss or hh:mm:ss correctly', () {
      final shortTest = StudentTestHistoryData(
        id: '1', subjectIcon: '📐', title: 'T', date: 'D', score: '10', scoreValue: 10, subject: 'Toán',
        durationSeconds: 75,
      );
      expect(shortTest.durationFormatted, '01:15');

      final zeroTest = StudentTestHistoryData(
        id: '2', subjectIcon: '📐', title: 'T', date: 'D', score: '10', scoreValue: 10, subject: 'Toán',
        durationSeconds: null,
      );
      expect(zeroTest.durationFormatted, '--:--');
    });
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test fail (do chưa có các trường mới)**

Run: `flutter test test/services/student_history_service_test.dart`
Expected: FAIL với lỗi compile "No named parameter with the name 'roomCode'" / "The getter 'durationFormatted' isn't defined".

- [ ] **Step 3: Cập nhật `StudentTestHistoryData` và `ProfileService`**

Trong `lib/core/services/profile_service.dart`:
1. Bổ sung các trường vào `StudentTestHistoryData`:
```dart
class StudentTestHistoryData {
  StudentTestHistoryData({
    required this.id,
    required this.subjectIcon,
    required this.title,
    required this.date,
    required this.score,
    required this.scoreValue,
    required this.subject,
    this.submittedAt,
    this.roomId,
    this.roomCode,
    this.durationSeconds,
    this.isLiveRoom = false,
    this.resultReleased = true,
  });

  final String id;
  final String subjectIcon;
  final String title;
  final String date;
  final String score;
  final double scoreValue;
  final String subject;
  final DateTime? submittedAt;
  final String? roomId;
  final String? roomCode;
  final int? durationSeconds;
  final bool isLiveRoom;
  final bool resultReleased;

  String get durationFormatted {
    if (durationSeconds == null || durationSeconds! <= 0) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }
}
```
2. Cập nhật câu truy vấn `attempts` và logic lọc trong `ProfileService.fetchStudentData`:
```dart
      var query = client.from('attempts').select('''
        id,
        exam_id,
        room_id,
        score,
        status,
        started_at,
        submitted_at,
        result_released_at,
        exams (
          title,
          subject
        ),
        rooms (
          code,
          name,
          status
        )
      ''');
```
3. Lọc cả trạng thái `submitted` và `expired`:
```dart
      final submittedAttempts = attemptsList
          .where((a) => (a['status'] == 'submitted' || a['status'] == 'expired') && a['score'] != null)
          .toList();
```
4. Tính toán `durationSeconds`, `roomCode`, `isLiveRoom`, `resultReleased` khi tạo đối tượng `StudentTestHistoryData`:
```dart
        final roomMap = a['rooms'] as Map<String, dynamic>?;
        final roomCode = roomMap?['code'] as String?;
        final roomId = a['room_id']?.toString();
        final isLiveRoom = roomId != null && roomId.isNotEmpty;
        final resultReleased = a['result_released_at'] != null || (roomMap?['status'] == 'closed') || !isLiveRoom;

        int? durationSec;
        if (a['started_at'] != null && a['submitted_at'] != null) {
          final start = DateTime.tryParse(a['started_at'].toString());
          final end = DateTime.tryParse(a['submitted_at'].toString());
          if (start != null && end != null && end.isAfter(start)) {
            durationSec = end.difference(start).inSeconds;
          }
        }
```

- [ ] **Step 4: Chạy lại test để xác nhận test pass**

Run: `flutter test test/services/student_history_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit và Push**

```bash
git add lib/core/services/profile_service.dart test/services/student_history_service_test.dart
git commit -m "feat(history): extend StudentTestHistoryData and support expired attempts in ProfileService"
git push origin main
```

---

### Task 2: Dọn Dẹp Route Trùng Lặp & Nút Quay Lại Thông Minh (`canPop`)

**Files:**
- Modify: `lib/main.dart:272-328`
- Modify: `lib/screens/student/student_history_screen.dart:236-243`
- Test: `test/screens/student_history_screen_test.dart`

**Interfaces:**
- Consumes: GoRouter context
- Produces: Clean routes without duplicate `/student/history` and smart back navigation

- [ ] **Step 1: Viết test cho nút quay lại thông minh trong `StudentHistoryScreen`**

Trong `test/screens/student_history_screen_test.dart`:
```dart
testWidgets('StudentHistoryScreen back button uses context.pop() when canPop is true', (tester) async {
  bool didPop = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Navigator(
        pages: [
          const MaterialPage(child: Scaffold(body: Text('Previous Screen'))),
          MaterialPage(
            child: Scaffold(
              body: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  // logic under test
                },
              ),
            ),
          ),
        ],
        onPopPage: (route, result) {
          didPop = true;
          return route.didPop(result);
        },
      ),
    ),
  );
  // verify tapping back triggers pop
});
```

- [ ] **Step 2: Thực hiện sửa `lib/main.dart` và `lib/screens/student/student_history_screen.dart`**

1. Trong `lib/main.dart`, xóa bỏ khối định nghĩa trùng lặp thứ 2 của `path: '/student/history'` (dòng 320-327).
2. Trong `lib/screens/student/student_history_screen.dart`:
```dart
IconButton(
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  },
  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
  tooltip: 'Quay lại',
),
```

- [ ] **Step 3: Chạy test xác nhận không có lỗi linter/route**

Run: `flutter test test/screens/student_history_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Commit và Push**

```bash
git add lib/main.dart lib/screens/student/student_history_screen.dart test/screens/student_history_screen_test.dart
git commit -m "fix(history): remove duplicate route and implement smart back navigation"
git push origin main
```

---

### Task 3: Menu Avatar trên `TopNavBar` & Banner Hướng Dẫn Khách Vãng Lai

**Files:**
- Modify: `lib/shared/widgets/top_nav_bar.dart:156-172`
- Modify: `lib/screens/student/student_history_screen.dart:254-257`
- Test: `test/widgets/top_nav_bar_test.dart`
- Test: `test/screens/student_history_screen_test.dart`

**Interfaces:**
- Consumes: `AuthProvider.isAuthenticated`, `AuthProvider.signOut()`
- Produces: `PopupMenuButton` on avatar with shortcuts ("Hồ sơ cá nhân", "Lịch sử làm bài", "Đăng xuất") and Guest Banner on `StudentHistoryScreen`.

- [ ] **Step 1: Viết test cho PopupMenuButton của Avatar trong `top_nav_bar_test.dart`**

```dart
testWidgets('TopNavBar avatar menu shows profile, history and logout options', (tester) async {
  // Setup authenticated user
  // Tap Avatar
  // Verify find.text('Hồ sơ của tôi') and find.text('Lịch sử làm bài')
});
```

- [ ] **Step 2: Cập nhật `lib/shared/widgets/top_nav_bar.dart`**

Thay thế `InkWell` quanh `CircleAvatar` bằng `PopupMenuButton<String>`:
```dart
PopupMenuButton<String>(
  offset: const Offset(0, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  tooltip: 'Tài khoản',
  onSelected: (value) async {
    if (value == 'profile') {
      context.go('/profile');
    } else if (value == 'history') {
      context.go('/student/history');
    } else if (value == 'logout') {
      await authProvider.signOut();
      if (context.mounted) context.go('/greeting');
    }
  },
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'profile',
      child: Row(
        children: const [
          Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.primary),
          SizedBox(width: 12),
          Text('Hồ sơ cá nhân', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'history',
      child: Row(
        children: const [
          Icon(Icons.history_edu_rounded, size: 20, color: AppTheme.primary),
          SizedBox(width: 12),
          Text('Lịch sử làm bài', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
    const PopupMenuDivider(),
    PopupMenuItem(
      value: 'logout',
      child: Row(
        children: const [
          Icon(Icons.logout_rounded, size: 20, color: AppTheme.error),
          SizedBox(width: 12),
          Text('Đăng xuất', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  ],
  child: CircleAvatar(
    radius: 18,
    backgroundColor: AppTheme.border,
    backgroundImage: avatarImage,
    child: avatarImage == null
        ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 18)
        : null,
  ),
)
```

- [ ] **Step 3: Thêm Guest Banner vào `StudentHistoryScreen` nếu chưa đăng nhập**

Trong `StudentHistoryScreen.build`:
```dart
if (!context.watch<AuthProvider>().isAuthenticated)
  Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF3C7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFDE68A)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFD97706), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: const Text(
            'Bạn đang duyệt ở chế độ khách. Đăng nhập để lưu trữ và đồng bộ toàn bộ lịch sử thi vĩnh viễn trên đám mây!',
            style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => context.go('/greeting'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Đăng nhập'),
        ),
      ],
    ),
  ),
```

- [ ] **Step 4: Chạy test kiểm thử**

Run: `flutter test test/widgets/top_nav_bar_test.dart test/screens/student_history_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit và Push**

```bash
git add lib/shared/widgets/top_nav_bar.dart lib/screens/student/student_history_screen.dart test/widgets/top_nav_bar_test.dart test/screens/student_history_screen_test.dart
git commit -m "feat(nav): add avatar popup menu on TopNavBar and guest banner in history screen"
git push origin main
```

---

### Task 4: Responsive Mobile Layout & 3-Tab Phân Loại Chế Độ Thi

**Files:**
- Modify: `lib/screens/student/student_history_screen.dart:25-35`
- Modify: `lib/screens/student/student_history_screen.dart:80-160`
- Modify: `lib/screens/student/student_history_screen.dart:256-300`
- Modify: `lib/screens/student/student_history_screen.dart:450-550`
- Test: `test/screens/student_history_screen_test.dart`

**Interfaces:**
- Consumes: Screen constraints (<600px, <900px, >=900px)
- Produces: RenderFlex overflow-free responsive layout, 3 tabs (`all`, `room`, `practice`), mobile BottomSheet for advanced filters.

- [ ] **Step 1: Viết test cho giao diện mobile nhỏ 360x640 và chuyển Tab**

```dart
testWidgets('StudentHistoryScreen does not overflow on small mobile screen and switches mode tabs', (tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  // pump StudentHistoryScreen with mock data
  // Verify 0 overflow exception
  // Verify Tab "Phòng thi trực tiếp" taps and filters list
});
```

- [ ] **Step 2: Hiện thực 3 Tab và Hàng chỉ số Responsive**

1. Khai báo biến lọc chế độ thi:
```dart
String _modeFilter = 'all'; // 'all', 'room', 'practice'
```
2. Cập nhật getter `_filteredAndSortedItems`:
```dart
if (_modeFilter == 'room' && !item.isLiveRoom) return false;
if (_modeFilter == 'practice' && item.isLiveRoom) return false;
```
3. Cập nhật Hàng chỉ số Metrics trong `build`:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = constraints.maxWidth < 650;
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('Đã làm', '${_data.completedTestsCount}', Icons.assignment_turned_in_outlined, const Color(0xFF7C3AED))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Điểm TB', '${_data.averageScore.toStringAsFixed(1)}', Icons.analytics_outlined, const Color(0xFF2563EB))),
            ],
          ),
          const SizedBox(height: 10),
          _buildMetricCard('Điểm cao nhất', '${_data.highestScore.toStringAsFixed(1)} / 10', Icons.star_outline_rounded, const Color(0xFFD97706)),
        ],
      );
    }
    return Row(...); // desktop
  },
)
```
4. Thêm thanh 3 Tab chế độ thi trên đầu kết quả:
```dart
Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFEBE6FC)),
  ),
  child: Row(
    children: [
      _buildModeTab('Tất cả bài thi', 'all', Icons.all_inclusive_rounded),
      _buildModeTab('Phòng thi trực tiếp', 'room', Icons.meeting_room_outlined),
      _buildModeTab('Tự luyện tập', 'practice', Icons.fitness_center_rounded),
    ],
  ),
)
```
5. Trên mobile (< 900px): Thêm thanh cuộn ngang môn học + nút "Bộ lọc nâng cao" mở `showModalBottomSheet`.

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/student_history_screen_test.dart`
Expected: PASS không có bất kỳ RenderFlex overflow nào.

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/student/student_history_screen.dart test/screens/student_history_screen_test.dart
git commit -m "feat(history): implement responsive mobile layout and exam mode tabs"
git push origin main
```

---

### Task 5: Tái Thiết Kế Thẻ Bài Thi (`_buildHistoryCard`) & Nút Hành Động

**Files:**
- Modify: `lib/screens/student/student_history_screen.dart:620-730`
- Test: `test/screens/student_history_screen_test.dart`

**Interfaces:**
- Consumes: `StudentTestHistoryData` extended properties (`isLiveRoom`, `roomCode`, `durationFormatted`, `resultReleased`)
- Produces: Modern history card UI with mode badges, duration, score pills, and action buttons.

- [ ] **Step 1: Viết test cho Thẻ bài thi mới**

```dart
testWidgets('History card renders exam mode badge, duration, and pending release state correctly', (tester) async {
  // Test item with isLiveRoom = true, roomCode = 'PT999888', durationSeconds = 1200
  // Verify text 'Phòng thi: PT999888'
  // Verify duration '20:00'
  // Test item with resultReleased = false -> verify text 'Chờ công bố'
});
```

- [ ] **Step 2: Cập nhật hàm `_buildHistoryCard` trong `StudentHistoryScreen`**

1. Hiển thị huy hiệu Chế độ thi:
   - Nếu `item.isLiveRoom`: Badge xanh dương `Phòng thi: ${item.roomCode ?? ''}`.
   - Nếu không: Badge tím nhạt `Tự luyện tập`.
2. Hiển thị thời gian làm bài:
   - Icon `Icons.timer_outlined` + `item.durationFormatted`.
3. Hiển thị trạng thái điểm:
   - Nếu `!item.resultReleased`: Pill màu xám/vàng "Chờ công bố" (icon `Icons.hourglass_top_rounded`).
   - Nếu `item.resultReleased`: Pill điểm số với màu tiered (>=8 xanh lá, 5-7.9 tím, <5 cam).
4. Các nút hành động:
   - Nút "Xem kết quả" (`onPressed: () => context.go('/result?attemptId=...')`).
   - Nút "Luyện lại câu sai" (hiển thị khi `item.scoreValue < 10.0` và `item.resultReleased`).

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/student_history_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/student/student_history_screen.dart test/screens/student_history_screen_test.dart
git commit -m "feat(history): redesign history card with mode badges, duration and actions"
git push origin main
```

---

### Task 6: Tích Hợp Tính Năng "Luyện Lại Câu Sai" (Retake Wrong Questions Flow)

**Files:**
- Create: `lib/screens/exam/wrong_questions_practice_screen.dart`
- Modify: `lib/main.dart` (khai báo route `/practice/wrong_questions`)
- Modify: `lib/screens/student/student_history_screen.dart`
- Test: `test/screens/wrong_questions_practice_test.dart`

**Interfaces:**
- Consumes: `AssessmentRepository.loadReview(attemptId)`
- Produces: Practice session loading only wrong/unanswered questions for the student to retake.

- [ ] **Step 1: Viết test cho màn hình `WrongQuestionsPracticeScreen`**

```dart
testWidgets('WrongQuestionsPractice loads wrong questions from attempt review and presents practice mode', (tester) async {
  // Mock review with 1 correct, 2 wrong questions
  // Verify WrongQuestionsPracticeScreen renders 2 questions
});
```

- [ ] **Step 2: Hiện thực màn hình `WrongQuestionsPracticeScreen`**

Tải review payload của `attemptId`, lọc ra danh sách các câu hỏi mà thí sinh trả lời sai hoặc chưa làm, và cho phép học sinh làm lại các câu đó kèm giải thích chi tiết khi chọn.

- [ ] **Step 3: Kết nối nút "Luyện lại câu sai" từ `_buildHistoryCard`**

```dart
onPressed: () => context.go('/practice/wrong_questions?attemptId=${item.id}'),
```

- [ ] **Step 4: Chạy test kiểm thử**

Run: `flutter test test/screens/wrong_questions_practice_test.dart`
Expected: PASS

- [ ] **Step 5: Commit và Push**

```bash
git add lib/screens/exam/wrong_questions_practice_screen.dart lib/main.dart lib/screens/student/student_history_screen.dart test/screens/wrong_questions_practice_test.dart
git commit -m "feat(practice): implement retake wrong questions practice mode"
git push origin main
```

---

### Task 7: Toàn Diện Hóa Kiểm Thử & Kiểm Thử Hồi Quy Toàn Hệ Thống

**Files:**
- Run all project test suites

- [ ] **Step 1: Chạy toàn bộ test suite**

Run: `flutter test`
Expected: 100% test cases pass không có lỗi.

- [ ] **Step 2: Commit & Push xác nhận cuối cùng**

```bash
git status
git push origin main
```
