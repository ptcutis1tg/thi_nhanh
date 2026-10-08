# Dọn Dẹp Widget Thừa, Loại Bỏ Mã Mồ Côi & Chuẩn Hóa Logic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Quét sạch toàn bộ các widget không còn được sử dụng, xóa các tệp trùng lặp/mồ côi, loại bỏ các fallback demo UUID ảo, fix cảnh báo async context gap và duy trì 100% test suites màu xanh (green) mà tuyệt đối không thêm tính năng mới.

**Architecture:** Loại bỏ các thành phần dead code đã được xác định 0 tham chiếu (`profile_dialog.dart`, `topic_chip.dart`, `otp_mailer.dart`, `lib/screens/exam/teacher_exams_screen.dart`), chuẩn hóa điều hướng và trạng thái Not Found trong `ExamDetailScreen` và `HomeScreen`, đồng thời cập nhật bài test để kiểm thử màn hình chính thức.

**Tech Stack:** Flutter 3.x, Dart 3.x, Provider, GoRouter, Supabase Flutter, Flutter Test.

## Global Constraints
- Tuyệt đối KHÔNG thêm tính năng mới (Zero New Features).
- Bảo toàn 100% bài kiểm thử tự động, không để gãy bất kỳ test nào.
- Auto-push sau khi hoàn thành toàn bộ kiểm thử và đồng bộ tài liệu kiến trúc.

---

### Task 1: Xóa các widget & utility mồ côi (`profile_dialog.dart`, `topic_chip.dart`, `otp_mailer.dart`)

**Files:**
- Delete: `lib/shared/widgets/profile_dialog.dart`
- Delete: `lib/shared/widgets/topic_chip.dart`
- Delete: `lib/core/utils/otp_mailer.dart`

**Interfaces:**
- Consumes: Không có (các file này có 0 tham chiếu trong `lib/` và `test/`).
- Produces: Mã nguồn sạch sẽ, không còn file dead code.

- [ ] **Step 1: Xóa 3 tệp mồ côi khỏi thư mục dự án**

```powershell
Remove-Item -Path "lib/shared/widgets/profile_dialog.dart" -Force
Remove-Item -Path "lib/shared/widgets/topic_chip.dart" -Force
Remove-Item -Path "lib/core/utils/otp_mailer.dart" -Force
```

- [ ] **Step 2: Chạy static analysis xác nhận không gãy bất kỳ import nào**

Run: `dart analyze lib/shared/widgets`
Expected: 0 errors/issues liên quan đến các file vừa xóa.

- [ ] **Step 3: Chạy test suite xác nhận không ảnh hưởng đến bất kỳ test nào**

Run: `flutter test`
Expected: ALL PASS.

- [ ] **Step 4: Commit**

```bash
git add -u lib/shared/widgets/ lib/core/utils/
git commit -m "refactor(cleanup): remove orphan widgets and dead otp mailer"
```

---

### Task 2: Loại bỏ duplicate screen `lib/screens/exam/teacher_exams_screen.dart` & Cập nhật bài test

**Files:**
- Delete: `lib/screens/exam/teacher_exams_screen.dart`
- Modify: `test/screens/teacher_exams_screen_test.dart`

**Interfaces:**
- Consumes: `TeacherExamRepository`
- Produces: `test/screens/teacher_exams_screen_test.dart` kiểm thử trực tiếp `lib/screens/teacher/teacher_exams_screen.dart` (màn hình chính thức).

- [ ] **Step 1: Cập nhật `test/screens/teacher_exams_screen_test.dart` trỏ tới `screens/teacher/teacher_exams_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/teacher/teacher_exams_screen.dart';

class FakeTeacherExamRepository implements TeacherExamRepository {
  @override
  Future<List<TeacherExamSummary>> summaries() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the official teacher exam management empty state', (tester) async {
    await tester.pumpWidget(
      Provider<TeacherExamRepository>(
        create: (_) => FakeTeacherExamRepository(),
        child: const MaterialApp(home: TeacherExamsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quản lý đề thi'), findsOneWidget);
    expect(find.text('Chưa có đề thi nào trong mục này'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test pass với màn hình chính thức**

Run: `flutter test test/screens/teacher_exams_screen_test.dart`
Expected: PASS.

- [ ] **Step 3: Xóa tệp trùng lặp di sản `lib/screens/exam/teacher_exams_screen.dart`**

```powershell
Remove-Item -Path "lib/screens/exam/teacher_exams_screen.dart" -Force
```

- [ ] **Step 4: Chạy test xác nhận không còn bất kỳ tham chiếu nào gãy**

Run: `flutter test test/screens/teacher_manage_exams_screen_test.dart test/screens/teacher_exams_screen_test.dart`
Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add -u lib/screens/exam/ test/screens/
git commit -m "refactor(cleanup): remove redundant legacy teacher exams screen and point test to official screen"
```

---

### Task 3: Dọn dẹp UUID demo & chuẩn hóa Not Found state trong `ExamDetailScreen`

**Files:**
- Modify: `lib/screens/exam/exam_detail_screen.dart:18,110-125,185-195`

**Interfaces:**
- Consumes: `examId` từ router
- Produces: Trạng thái UI trung thực khi không tìm thấy đề thay vì tự động gán UUID demo ảo.

- [ ] **Step 1: Xóa hằng số `_demoExamId`, loại bỏ fallback ảo và xử lý khi đề không tồn tại**

Trong `lib/screens/exam/exam_detail_screen.dart`:
- Xóa `static const _demoExamId = '10000000-0000-4000-8000-000000000002';`
- Trong `_start()`:
```dart
    final currentExamId = _examData?['id']?.toString() ?? widget.examId;
    if (currentExamId == null || currentExamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin đề thi hợp lệ.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
```
- Trong `build()`: Nếu `!_isLoading && _examData == null`, hiển thị thông báo "Không tìm thấy đề thi hoặc đề thi đã bị xóa" và nút "Quay lại trang chủ" thay vì crash hoặc hiển thị trắng.
- Loại bỏ logic bookmark RAM ảo (`_saved`), thay bằng thông báo SnackBar: *"Tính năng lưu đề sẽ sớm hỗ trợ đồng bộ đám mây"*.

- [ ] **Step 2: Chạy static analysis xác nhận không có lỗi syntax**

Run: `dart analyze lib/screens/exam/exam_detail_screen.dart`
Expected: 0 errors.

- [ ] **Step 3: Chạy toàn bộ test suites**

Run: `flutter test`
Expected: ALL PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/exam/exam_detail_screen.dart
git commit -m "refactor(exam): remove demo uuid fallback and handle missing exam state gracefully"
```

---

### Task 4: Khắc phục cảnh báo async context gap trên `HomeScreen`

**Files:**
- Modify: `lib/screens/home/home_screen.dart:160-205`

**Interfaces:**
- Consumes: `ProfileService.fetchActiveAttempt`, `ProfileService.fetchActiveLiveRoom`
- Produces: Async navigation an toàn, có guard `if (!mounted) return;`.

- [ ] **Step 1: Thêm `if (!mounted) return;` trước mọi lệnh context navigation**

Trong `lib/screens/home/home_screen.dart`:
- Trong `_handleActiveAttemptClick`:
```dart
      final activeAttempt = await ProfileService.fetchActiveAttempt(
        userId: user?.id,
        userEmail: authProvider.userEmail,
        guestName: authProvider.guestName,
      );

      if (!mounted) return;

      if (activeAttempt != null) {
        final attemptId = activeAttempt['id'] as String;
        final examId = activeAttempt['exam_id'] as String;
        context.go('/taking_exam?examId=$examId&attemptId=$attemptId');
      } else {
        context.go('/search');
      }
```
- Trong `_handleActiveLiveRoomClick`:
```dart
      final activeRoom = await ProfileService.fetchActiveLiveRoom(
        userId: user?.id,
        userEmail: authProvider.userEmail,
        isTeacher: authProvider.isTeacher,
      );

      if (!mounted) return;

      if (activeRoom != null) {
        final roomId = activeRoom['id'] as String;
        final isHost = activeRoom['teacher_id'] == user?.id;
        if (isHost) {
          context.go('/teacher_waiting_room?roomId=$roomId');
        } else {
          context.go('/student_waiting_room?roomId=$roomId');
        }
      } else {
        context.go('/search');
      }
```

- [ ] **Step 2: Chạy static analysis xác nhận 0 cảnh báo `use_build_context_synchronously`**

Run: `dart analyze lib/screens/home/home_screen.dart`
Expected: 0 warnings for `use_build_context_synchronously`.

- [ ] **Step 3: Chạy test home smart navigation**

Run: `flutter test test/screens/home_smart_navigation_test.dart`
Expected: 4/4 PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/home/home_screen.dart
git commit -m "refactor(home): guard async context navigation with mounted checks"
```

---

### Task 5: Kiểm thử toàn diện, đồng bộ tài liệu kiến trúc & Auto-push

**Files:**
- Modify: `docs/system_architecture_and_deep_evaluation.md`
- Sync: Artifact IDE `system_architecture_and_deep_evaluation.md`

- [ ] **Step 1: Chạy toàn bộ test suite (173/173 tests PASS)**

Run: `flutter test`
Expected: 100% green.

- [ ] **Step 2: Cập nhật tài liệu kiến trúc tổng quan**
- [ ] **Step 3: Đồng bộ Artifact IDE**
- [ ] **Step 4: Git commit và push cả `thi_nhanh` và `CODE` lên GitHub**
