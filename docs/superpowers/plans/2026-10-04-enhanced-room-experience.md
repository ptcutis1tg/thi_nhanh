# Implementation Plan: Nâng Cao Trải Nghiệm Phòng Thi (Chống Gian Lận Đa Tầng, Xáo Trộn Đề & Đếm Ngược Đồng Bộ)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai cơ chế chống gian lận đa tầng (Xáo trộn câu hỏi & đáp án tất định theo thí sinh, phát hiện chuyển tab / rời màn hình phạt tối đa 3 lần cảnh báo và thu bài ở lần 4, khóa sao chép câu hỏi), đồng bộ cờ vi phạm lên Live Dashboard của giáo viên, và hiệu ứng đếm ngược 3-2-1 kịch tính khi bắt đầu thi.

**Architecture:** 
- Xáo trộn câu hỏi & đáp án tất định qua `ExamShuffleHelper` với seed từ `attemptId` hoặc `userId + roomId`.
- Phát hiện rời màn hình qua `WidgetsBindingObserver` (`AppLifecycleState.paused / inactive / hidden`) với cơ chế guard chống cảnh báo giả.
- Hộp thoại cảnh báo vi phạm 4 cấp độ và cưỡng chế nộp bài (`_submitExam()`) ở lần vi phạm thứ 4.
- `CountdownOverlayWidget` với ScaleTransition cho đếm ngược 3-2-1 tại phòng chờ học sinh.
- Hiển thị cờ đỏ 🚩 vi phạm trên `LiveDashboardScreen`.

**Tech Stack:** Flutter 3.x, Dart 3.x, Supabase Flutter, GoRouter, Provider, Material 3, TDD with `flutter_test`.

## Global Constraints
- Tuân thủ nghiêm ngặt quy tắc Auto-push: `flutter test`, `git commit` và `git push origin main` sau khi hoàn thành mỗi task.
- 100% không để xảy ra lỗi `RenderFlex overflow` trên mọi màn hình, đặc biệt là màn hình nhỏ di động (360x640).
- Tuân thủ quy trình TDD: Viết test failing trước $\rightarrow$ Hiện thực mã nguồn $\rightarrow$ Xác nhận test pass $\rightarrow$ Commit & Push.

---

### Task 1: Tiện Ích Xáo Trộn Tất Định (`ExamShuffleHelper`) & Unit Tests

**Files:**
- Create: `lib/core/utils/exam_shuffle_helper.dart`
- Test: `test/utils/exam_shuffle_helper_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class ExamShuffleHelper {
    static List<Map<String, dynamic>> shuffleQuestionsAndOptions(
      List<Map<String, dynamic>> questions, {
      required int seed,
      bool shuffleQuestions = true,
      bool shuffleOptions = true,
    );
  }
  ```

- [ ] **Step 1: Viết failing unit tests cho `ExamShuffleHelper`**

```dart
// test/utils/exam_shuffle_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/exam_shuffle_helper.dart';

void main() {
  final sampleQuestions = [
    {
      'id': 'q1',
      'body': 'Câu hỏi 1',
      'question_options': [
        {'id': 'opt1', 'body': 'A', 'is_correct': true},
        {'id': 'opt2', 'body': 'B', 'is_correct': false},
      ],
    },
    {
      'id': 'q2',
      'body': 'Câu hỏi 2',
      'question_options': [
        {'id': 'opt3', 'body': 'C', 'is_correct': false},
        {'id': 'opt4', 'body': 'D', 'is_correct': true},
      ],
    },
    {
      'id': 'q3',
      'body': 'Câu hỏi 3',
      'question_options': [
        {'id': 'opt5', 'body': 'E', 'is_correct': true},
        {'id': 'opt6', 'body': 'F', 'is_correct': false},
      ],
    },
  ];

  test('ExamShuffleHelper produces deterministic order for same seed', () {
    final shuffled1 = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 12345);
    final shuffled2 = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 12345);
    expect(shuffled1.map((q) => q['id']).toList(), equals(shuffled2.map((q) => q['id']).toList()));
  });

  test('ExamShuffleHelper produces different order for different seeds', () {
    final shuffled1 = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 11111);
    final shuffled2 = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 99999);
    // Across 3 questions, order should differ or options differ
    expect(shuffled1.toString() != shuffled2.toString(), isTrue);
  });

  test('ExamShuffleHelper preserves question and option IDs and correctness', () {
    final shuffled = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 42);
    expect(shuffled.length, equals(3));
    for (final q in shuffled) {
      final opts = q['question_options'] as List;
      expect(opts.length, equals(2));
      expect(opts.any((o) => o['is_correct'] == true), isTrue);
    }
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận FAIL**

Run: `flutter test test/utils/exam_shuffle_helper_test.dart`  
Expected: Compilation failure (chưa có file `ExamShuffleHelper`).

- [ ] **Step 3: Hiện thực `ExamShuffleHelper`**

Tạo `lib/core/utils/exam_shuffle_helper.dart` với thuật toán xáo trộn bản sao sâu (deep copy) sử dụng `Random(seed)`.

- [ ] **Step 4: Chạy test kiểm thử**

Run: `flutter test test/utils/exam_shuffle_helper_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit và Push**

```bash
git add lib/core/utils/exam_shuffle_helper.dart test/utils/exam_shuffle_helper_test.dart ; git commit -m "feat(room): implement deterministic exam shuffle helper with unit tests" ; git push origin main
```

---

### Task 2: Widget Đếm Ngược Khởi Động Đồng Bộ (`CountdownOverlayWidget`) & Tests

**Files:**
- Create: `lib/screens/room/widgets/countdown_overlay_widget.dart`
- Test: `test/screens/room/widgets/countdown_overlay_widget_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class CountdownOverlayWidget extends StatefulWidget {
    final VoidCallback onCountdownComplete;
    final int initialSeconds; // default: 3
    const CountdownOverlayWidget({super.key, required this.onCountdownComplete, this.initialSeconds = 3});
  }
  ```

- [ ] **Step 1: Viết failing widget test cho `CountdownOverlayWidget`**

```dart
// test/screens/room/widgets/countdown_overlay_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/room/widgets/countdown_overlay_widget.dart';

void main() {
  testWidgets('CountdownOverlayWidget counts down 3, 2, 1, and triggers callback', (tester) async {
    bool isCompleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountdownOverlayWidget(
            initialSeconds: 3,
            onCountdownComplete: () => isCompleted = true,
          ),
        ),
      ),
    );

    // Initial value: 3
    expect(find.text('3'), findsOneWidget);

    // Advance 1 second -> 2
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    // Advance 1 second -> 1
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    // Advance 1 second -> BẮT ĐẦU!
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BẮT ĐẦU!'), findsOneWidget);

    // Advance animation completion -> callback triggered
    await tester.pumpAndSettle();
    expect(isCompleted, isTrue);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận FAIL**

Run: `flutter test test/screens/room/widgets/countdown_overlay_widget_test.dart`  
Expected: Compilation failure.

- [ ] **Step 3: Hiện thực `CountdownOverlayWidget`**

Trong `lib/screens/room/widgets/countdown_overlay_widget.dart`:
- `AnimatedSwitcher` / `ScaleTransition` mượt mà với màu sắc nổi bật (Primary Violet & Gold).
- Timer mỗi giây giảm biến đếm, khi về 0 hiển thị "BẮT ĐẦU!" và gọi `widget.onCountdownComplete()`.

- [ ] **Step 4: Chạy test kiểm thử**

Run: `flutter test test/screens/room/widgets/countdown_overlay_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit và Push**

```bash
git add lib/screens/room/widgets/countdown_overlay_widget.dart test/screens/room/widgets/countdown_overlay_widget_test.dart ; git commit -m "feat(room): implement synchronized countdown overlay widget" ; git push origin main
```

---

### Task 3: Bổ Sung Tùy Chọn Anti-Cheat & Shuffle trong `CreateRoomScreen`

**Files:**
- Modify: `lib/screens/room/create_room_screen.dart`
- Test: `test/screens/room/create_room_screen_anti_cheat_test.dart`

**Interfaces:**
- Consumes: Screen UI controls
- Produces: Switch `_shuffleQuestions` (default true) and `_enableAntiCheat` (default true)

- [ ] **Step 1: Viết failing widget test cho các nút gạt cấu hình phòng thi**

Kiểm tra:
- Màn hình hiển thị 2 switch: "Xáo trộn câu hỏi & đáp án" và "Giám sát chống gian lận".
- Trạng thái mặc định là bật (`value: true`).
- Có thể bật/tắt công tắc này.

- [ ] **Step 2: Cập nhật giao diện `CreateRoomScreen`**

Trong `lib/screens/room/create_room_screen.dart`:
- Bổ sung `bool _shuffleQuestions = true;` và `bool _enableAntiCheat = true;`.
- Thêm Card thiết kế đẹp mắt "Cài đặt phòng thi & Bảo mật" chứa 2 SwitchListTile với icon khiên bảo vệ `Icons.security_rounded` và icon xáo trộn `Icons.shuffle_rounded`.

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/room/create_room_screen_anti_cheat_test.dart`  
Expected: PASS.

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/room/create_room_screen.dart test/screens/room/create_room_screen_anti_cheat_test.dart ; git commit -m "feat(room): add anti-cheat and shuffle toggles in create room screen" ; git push origin main
```

---

### Task 4: Tích Hợp Đếm Ngược 3-2-1 vào `StudentWaitingRoomScreen`

**Files:**
- Modify: `lib/screens/room/student_waiting_room_screen.dart`
- Test: `test/screens/student_waiting_room_screen_countdown_test.dart`

**Interfaces:**
- Consumes: `CountdownOverlayWidget`
- Produces: Hiển thị đếm ngược 3-2-1 khi phòng chuyển sang `live` trước khi điều hướng sang `/taking_exam`.

- [ ] **Step 1: Viết failing test cho luồng đếm ngược khi phòng chuyển sang live**

Kiểm tra khi nhận được status `live`, hiển thị `CountdownOverlayWidget`, sau khi đếm ngược xong mới chuyển sang `/taking_exam`.

- [ ] **Step 2: Cập nhật `StudentWaitingRoomScreen`**

Thêm cờ `_isCountingDown = false;`. Khi nhận trạng thái `live`, đặt `_isCountingDown = true` và hiển thị `CountdownOverlayWidget(onCountdownComplete: () => context.go(...))`.

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/student_waiting_room_screen_countdown_test.dart`  
Expected: PASS.

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/room/student_waiting_room_screen.dart test/screens/student_waiting_room_screen_countdown_test.dart ; git commit -m "feat(room): integrate 3-2-1 countdown overlay into student waiting room" ; git push origin main
```

---

### Task 5: Chống Gian Lận Đa Tầng trong `TakingExamScreen` (Focus Monitor, Cảnh Báo, Thu Bài & Chặn Copy)

**Files:**
- Modify: `lib/screens/exam/taking_exam_screen.dart`
- Test: `test/screens/taking_exam_anti_cheat_test.dart`

**Interfaces:**
- Consumes: `ExamShuffleHelper`, `WidgetsBindingObserver`
- Produces: 
  - `SelectionContainer.disabled` chặn copy câu hỏi
  - Xáo trộn câu hỏi và đáp án tự động
  - Cảnh báo vi phạm lần 1, 2, 3
  - Tự động nộp bài ở lần thứ 4

- [ ] **Step 1: Viết failing test cho cơ chế phát hiện chuyển tab & cảnh báo**

```dart
testWidgets('TakingExamScreen detects tab switch, increments violations, warns 1-3, and auto-submits on 4th', (tester) async {
  // Test simulated lifecycle state changes
  // Verify violation dialog appears with correct count
  // On 4th violation verify _submitExam is triggered
});
```

- [ ] **Step 2: Cập nhật `TakingExamScreen`**

1. Khóa bôi đen: Bọc toàn bộ vùng hiển thị câu hỏi và đáp án trong `SelectionContainer.disabled(...)`.
2. Xáo trộn đề: Gọi `ExamShuffleHelper.shuffleQuestionsAndOptions` với seed từ `widget.attemptId?.hashCode ?? ...`.
3. Giám sát vòng đời: `with WidgetsBindingObserver`, triển khai `didChangeAppLifecycleState`:
   - Kiểm tra `AppLifecycleState.paused / inactive / hidden`.
   - Bỏ qua nếu `_hasSubmitted == true` hoặc đang hiển thị hộp thoại cảnh báo.
   - Tăng `_violationCount++`.
   - Nếu `_violationCount <= 3`: hiển thị Alert Dialog cảnh báo vi phạm màu đỏ rực rỡ với đếm số lần vi phạm.
   - Nếu `_violationCount >= 4`: hiển thị thông báo cưỡng chế thu bài và gọi ngay `_submitExam()`.

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/taking_exam_anti_cheat_test.dart`  
Expected: PASS không có RenderFlex overflow trên màn hình 360x640.

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/exam/taking_exam_screen.dart test/screens/taking_exam_anti_cheat_test.dart ; git commit -m "feat(exam): implement multi-layer anti-cheat, focus monitoring, and copy lock" ; git push origin main
```

---

### Task 6: Hiển Thị Giám Sát Vi Phạm trên Live Dashboard Giáo Viên

**Files:**
- Modify: `lib/screens/exam/live_dashboard_screen.dart`
- Test: `test/screens/live_dashboard_violations_test.dart`

**Interfaces:**
- Consumes: Student violation count
- Produces: Cờ đỏ 🚩 `${student['violations']} vi phạm` trên danh sách thí sinh.

- [ ] **Step 1: Viết failing test kiểm tra hiển thị cờ đỏ vi phạm trên Live Dashboard**

- [ ] **Step 2: Cập nhật `LiveDashboardScreen`**

Hiển thị chip cảnh báo `🚩 X vi phạm` bên cạnh tên thí sinh nếu số lần vi phạm $\ge 1$, hoặc huy hiệu `⛔ Thu bài do vi phạm` nếu $\ge 4$.

- [ ] **Step 3: Chạy test kiểm thử**

Run: `flutter test test/screens/live_dashboard_violations_test.dart`  
Expected: PASS.

- [ ] **Step 4: Commit và Push**

```bash
git add lib/screens/exam/live_dashboard_screen.dart test/screens/live_dashboard_violations_test.dart ; git commit -m "feat(exam): display live violation indicators on teacher dashboard" ; git push origin main
```

---

### Task 7: Kiểm Thử Toàn Diện Bộ Hồi Quy (Full Regression Suite) & Tổng Kết

**Files:**
- Full test suite: `test/`

- [ ] **Step 1: Chạy toàn bộ bộ kiểm thử hồi quy**

Run: `flutter test`  
Expected: 155+ bài kiểm thử đạt 100% green.

- [ ] **Step 2: Cập nhật tài liệu tiến độ và đẩy lên GitHub**

```bash
git add . ; git commit -m "chore: complete enhanced room experience feature suite" ; git push origin main
```
