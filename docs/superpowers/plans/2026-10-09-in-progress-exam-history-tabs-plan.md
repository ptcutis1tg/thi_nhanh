# Chuẩn Hóa Phân Hệ "Bài Đang Làm" — Quản Lý Tab Lịch Sử & Xử Lý Bài Thi Hết Hạn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Khắc phục triệt để lỗi thẻ "Bài Đang Làm" kẹt bài cũ/hết hạn tại Home, tạo Tab "Chưa hoàn thành" tại màn hình Lịch sử làm bài (`/student/history?tab=in_progress`) với đầy đủ các thao tác: tiếp tục làm, hủy bài dở dang, nộp bài hết hạn và xóa bài kẹt, đồng thời phòng vệ êm đẹp tại `TakingExamScreen`.

**Architecture:** Mở rộng `StudentTestHistoryData` và `StudentProfileData` trong `ProfileService` để lưu trữ và phân loại các bài thi dở dang; nâng cấp `StudentHistoryScreen` với 2 Tab chuẩn ("Đã hoàn thành" & "Chưa hoàn thành") kèm Badge đếm; chuyển hướng thẻ "Bài Đang Làm" tại `HomeScreen` sang `/student/history?tab=in_progress`; xử lý nhẹ nhàng bài thi hết hạn tại `TakingExamScreen`.

**Tech Stack:** Flutter / Dart, Provider, Supabase Flutter, GoRouter, SharedPreferences.

## Global Constraints
- Tuân thủ nghiêm ngặt quy tắc TDD: Viết test trước, kiểm chứng RED, viết code tối giản đạt GREEN.
- Thiết kế giao diện theo hệ thống token Stitch EdTech trong `AppTheme` (`pillRadius`, `cardRadius`, `surfaceLavender`, `primary`, `warning`, `error`).
- Giữ nguyên 100% tỷ lệ pass của toàn bộ 194+ tests hiện tại.
- Tự động cập nhật tài liệu kiến trúc `docs/system_architecture_and_deep_evaluation.md` và artifact IDE.
- Tự động commit và push sau khi hoàn thành.

---

### Task 1: Mở Rộng Data Model & Service Layer Cho Bài Thi Chưa Hoàn Thành

**Files:**
- Modify: `lib/core/services/profile_service.dart:20-80` (Model `StudentTestHistoryData`, `StudentProfileData`)
- Modify: `lib/core/services/profile_service.dart:290-480` (`fetchStudentData` phân loại `inProgressTests`)
- Modify: `lib/core/services/profile_service.dart:1040-1080` (`fetchActiveAttempt`, `cancelOrDeleteAttempt`)
- Test: `test/services/student_in_progress_data_test.dart`

**Interfaces:**
- Produces:
  - `StudentTestHistoryData`: `final String status`, `final DateTime? startedAt`, `final DateTime? expiresAt`, `bool get isExpired`.
  - `StudentProfileData`: `final List<StudentTestHistoryData> inProgressTests`.
  - `ProfileService.fetchActiveAttempt`: Bổ sung lọc `expires_at > now()`, trả về `inProgressCount`.
  - `ProfileService.cancelOrDeleteAttempt(String attemptId)`: Future<bool>.

- [ ] **Step 1: Viết failing unit test cho Data Model & Service**

Tạo tệp `test/services/student_in_progress_data_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('StudentTestHistoryData in-progress tests', () {
    test('isExpired returns true when expiresAt is in the past', () {
      final item = StudentTestHistoryData(
        id: 'att_expired',
        subjectIcon: '📐',
        title: 'Đề Toán 12',
        date: 'Hôm qua',
        score: '--',
        scoreValue: 0.0,
        status: 'in_progress',
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(item.status, 'in_progress');
      expect(item.isExpired, isTrue);
    });

    test('isExpired returns false when expiresAt is in the future', () {
      final item = StudentTestHistoryData(
        id: 'att_active',
        subjectIcon: '🔬',
        title: 'Đề Hóa 12',
        date: 'Vừa xong',
        score: '--',
        scoreValue: 0.0,
        status: 'in_progress',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 40)),
      );

      expect(item.isExpired, isFalse);
    });

    test('StudentProfileData.empty provides empty inProgressTests', () {
      final profile = StudentProfileData.empty();
      expect(profile.inProgressTests, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận RED**

Run: `flutter test test/services/student_in_progress_data_test.dart`  
Expected: FAIL do các tham số `status`, `expiresAt`, `startedAt`, `inProgressTests` chưa có trên model.

- [ ] **Step 3: Triển khai cập nhật trong `lib/core/services/profile_service.dart`**

Thêm các trường vào `StudentTestHistoryData`, `StudentProfileData`, cập nhật `StudentProfileData.empty()`, cập nhật `fetchStudentData` để gom bài `status == 'in_progress'` hoặc `(status == 'expired' && score == null)` vào `inProgressTests`, cập nhật `fetchActiveAttempt` kiểm tra `expires_at > now()`, thêm `cancelOrDeleteAttempt`.

- [ ] **Step 4: Chạy test để xác nhận GREEN**

Run: `flutter test test/services/student_in_progress_data_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/profile_service.dart test/services/student_in_progress_data_test.dart
git commit -m "feat(profile_service): add in-progress attempts support and expiration status"
```

---

### Task 2: Nâng Cấp Giao Diện Lịch Sử Làm Bài Với 2 Tab & Thao Tác Bài Dở Dang

**Files:**
- Modify: `lib/screens/student/student_history_screen.dart`
- Test: `test/screens/student_history_tabs_test.dart`

**Interfaces:**
- Consumes: `StudentProfileData.recentTests`, `StudentProfileData.inProgressTests`, `StudentTestHistoryData.isExpired`.
- Produces: `StudentHistoryScreen({super.key, this.testData, this.initialTab})`.

- [ ] **Step 1: Viết failing widget test cho `StudentHistoryScreen` 2 Tab**

Tạo tệp `test/screens/student_history_tabs_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';
import 'package:onthi_community/screens/student/student_history_screen.dart';

void main() {
  testWidgets('StudentHistoryScreen opens in-progress tab when initialTab is in_progress', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completedItem = StudentTestHistoryData(
      id: 'att_completed',
      subjectIcon: '📐',
      title: 'Đề Toán Đã Nộp',
      date: 'Hôm nay',
      score: '9.0',
      scoreValue: 9.0,
      status: 'submitted',
      submittedAt: DateTime.now(),
    );

    final inProgressItem = StudentTestHistoryData(
      id: 'att_active',
      subjectIcon: '🧪',
      title: 'Đề Hóa Đang Làm Dở',
      date: 'Vừa xong',
      score: '--',
      scoreValue: 0.0,
      status: 'in_progress',
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );

    final testData = StudentProfileData(
      completedTestsCount: 1,
      averageScore: 9.0,
      streakDays: 1,
      chartValues: [9.0],
      chartLabels: ['Bài 1'],
      highestScore: 9.0,
      totalTimeSpent: const Duration(minutes: 30),
      achievements: [],
      recentTests: [completedItem],
      inProgressTests: [inProgressItem],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentHistoryScreen(
            testData: testData,
            initialTab: 'in_progress',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Tab "Chưa hoàn thành" is selected and shows the in-progress card
    expect(find.text('Đề Hóa Đang Làm Dở'), findsOneWidget);
    expect(find.text('Tiếp tục làm bài'), findsOneWidget);
    expect(find.text('Hủy bài'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận RED**

Run: `flutter test test/screens/student_history_tabs_test.dart`  
Expected: FAIL do `initialTab` chưa tồn tại và chưa có tab "Chưa hoàn thành".

- [ ] **Step 3: Triển khai 2 Tab và Card bài thi dở dang trong `StudentHistoryScreen`**

- Thêm constructor `final String? initialTab`.
- Thêm state `String _selectedMainTab = widget.initialTab == 'in_progress' ? 'in_progress' : 'completed';`.
- Thêm thanh Tab con nhộng:
  - Tab 1: "Đã hoàn thành (${_data.recentTests.length})"
  - Tab 2: "Chưa hoàn thành (${_data.inProgressTests.length})"
- Xây dựng widget `_buildInProgressCard(StudentTestHistoryData item)`:
  - Phân nhánh hiển thị:
    - Nếu `item.isExpired`: Nhãn đỏ "Đã hết hạn làm bài", nút "Nộp bài chấm điểm" & nút "Xóa bài".
    - Nếu còn hạn: Nhãn cam "Đang làm dở", nút "Tiếp tục làm bài" (gọi `context.go('/taking_exam?attemptId=${item.id}')`) & nút "Hủy bài".
  - Dialog xác nhận khi bấm Hủy/Xóa bài.

- [ ] **Step 4: Chạy test để xác nhận GREEN**

Run: `flutter test test/screens/student_history_tabs_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/student/student_history_screen.dart test/screens/student_history_tabs_test.dart
git commit -m "feat(student_history): add in-progress tab with action buttons and tab query routing"
```

---

### Task 3: Cập Nhật Route Router & Thẻ "Bài Đang Làm" Tại Trang Chủ

**Files:**
- Modify: `lib/main.dart:250-270` (Route `/student/history`)
- Modify: `lib/screens/home/home_screen.dart:590-710, 1225-1245` (Thẻ "Bài Đang Làm" và hàm `_onCardTap`)
- Test: `test/screens/home_in_progress_navigation_test.dart`

**Interfaces:**
- Router: Truyền `state.uri.queryParameters['tab']` vào `StudentHistoryScreen(initialTab: ...)`.
- HomeScreen: Khi bấm vào "Bài Đang Làm" hoặc nút "Xem bài dở dang" -> gọi `context.go('/student/history?tab=in_progress')`.

- [ ] **Step 1: Viết failing widget test cho `HomeScreen` navigation**

Tạo `test/screens/home_in_progress_navigation_test.dart`:
Kiểm tra rằng khi nhấn vào nút trên thẻ "Bài Đang Làm", ứng dụng điều hướng sang `/student/history?tab=in_progress`.

- [ ] **Step 2: Chạy test để xác nhận RED**

Run: `flutter test test/screens/home_in_progress_navigation_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Triển khai cập nhật trong `main.dart` và `home_screen.dart`**

- `main.dart`:
  ```dart
  GoRoute(
    path: '/student/history',
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: StudentHistoryScreen(
        initialTab: state.uri.queryParameters['tab'],
      ),
    ),
  ),
  ```
- `home_screen.dart`:
  - Trong `_buildActiveAttemptCard`: hiển thị số lượng bài dở dang (nếu có), đổi nhãn nút thành "Xem bài dở dang".
  - Trong `_onCardTap`:
    ```dart
    if (title == 'Bài Đang Làm') {
      context.go('/student/history?tab=in_progress');
      return;
    }
    ```

- [ ] **Step 4: Chạy test để xác nhận GREEN**

Run: `flutter test test/screens/home_in_progress_navigation_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/screens/home/home_screen.dart test/screens/home_in_progress_navigation_test.dart
git commit -m "feat(home): route in-progress exam card directly to history tab"
```

---

### Task 4: Phòng Vệ An Toàn Khi Bài Thi Đã Hết Hạn Tại `TakingExamScreen`

**Files:**
- Modify: `lib/screens/exam/taking_exam_screen.dart:250-335`
- Test: `test/screens/taking_exam_expired_guard_test.dart`

**Interfaces:**
- Consumes: `AttemptPayload.status`, `AttemptPayload.expiresAt`.
- Handles: Hiển thị AlertDialog giải thích nhẹ nhàng khi bài thi hết hạn, không ném exception đỏ.

- [ ] **Step 1: Viết failing widget test cho `TakingExamScreen` expired dialog**

Tạo `test/screens/taking_exam_expired_guard_test.dart`:
Kiểm tra khi nạp attempt có `expiresAt` trong quá khứ hoặc `status == 'expired'`, màn hình hiển thị dialog thông báo hết giờ và cung cấp các lựa chọn nộp bài hoặc quay về lịch sử.

- [ ] **Step 2: Chạy test để xác nhận RED**

Run: `flutter test test/screens/taking_exam_expired_guard_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Triển khai xử lý êm đẹp trong `TakingExamScreen`**

Trong `_applyAttempt`:
Nếu `attempt.status == 'expired'` hoặc `attempt.expiresAt.isBefore(DateTime.now())`:
- Đặt `_remainingSeconds = 0`.
- Hiển thị Dialog: "Bài thi đã hết thời gian làm bài quy định".
  - Nút 1: "Nộp bài để lấy điểm" (gọi `_submitExam()`).
  - Nút 2: "Quay về Lịch sử bài làm" (gọi `context.go('/student/history?tab=in_progress')`).

- [ ] **Step 4: Chạy test để xác nhận GREEN**

Run: `flutter test test/screens/taking_exam_expired_guard_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/taking_exam_screen.dart test/screens/taking_exam_expired_guard_test.dart
git commit -m "feat(taking_exam): handle expired attempt gracefully with prompt dialog"
```

---

### Task 5: Kiểm Thử Toàn Diện, Cập Nhật Tài Liệu Hệ Thống & Tự Động Push

**Files:**
- Modify: `docs/system_architecture_and_deep_evaluation.md`
- Modify: Artifact `system_architecture_and_deep_evaluation.md`

- [ ] **Step 1: Chạy toàn bộ test suite dự án**

Run: `flutter test`  
Expected: 198+ tests ALL PASS (100%).

- [ ] **Step 2: Cập nhật tài liệu kiến trúc hệ thống**

Cập nhật Giai đoạn 8 trong `docs/system_architecture_and_deep_evaluation.md` và artifact IDE tương ứng.

- [ ] **Step 3: Tự động commit và push lên remote repositories**

```bash
git add .
git commit -m "feat: complete in-progress exam history tabs and expired attempt handling"
git push origin main
```
