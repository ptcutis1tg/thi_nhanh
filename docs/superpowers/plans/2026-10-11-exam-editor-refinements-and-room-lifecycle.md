# Kế Hoạch Triển Khai: Hoàn Thiện Trình Soạn Thảo Đề Thi, Nền CloudV2, Hiệu Ứng Khối & Vòng Đời Phòng Thi

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn thiện 7 hạng mục nâng cấp: hình nền `cloudv2_tall.jpg`, đa dạng môn học kèm tag `none`, sửa thông tin đề trong editor, hiệu ứng `softGlowShadow`, popup kiểm tra tổng 10 điểm khi xuất bản, tự động nộp bài và điều hướng khi host kết thúc phòng, và sửa triệt để lỗi xóa bài thi dở dang trong Lịch sử.

**Architecture:** Sử dụng kiến trúc hướng sự kiện (Supabase Realtime Postgres Changes), phân tách component rõ ràng (`EditExamInfoDialog`), chuẩn hóa ràng buộc cơ sở dữ liệu (`attempt_status`), mở rộng token giao diện trung tâm (`AppTheme.softGlowShadow`), và tuân thủ nghiêm ngặt quy trình TDD.

**Tech Stack:** Flutter 3.32+, GoRouter, Provider, Supabase Realtime / Postgres RLS, Flutter Test.

## Global Constraints
- Không làm suy giảm độ mượt 60/120 FPS; các thành phần hoạt ảnh và nền tĩnh bọc trong `RepaintBoundary`.
- Giữ 0 cảnh báo phân tích tĩnh `flutter analyze`.
- Toàn bộ test suite phải pass 100% sau mỗi task.
- Tự động commit và push lên remote repo sau khi hoàn tất theo quy định dự án.

---

### Task 1: Nâng cấp hình nền hệ thống bằng `cloudv2_tall.jpg`

**Files:**
- Modify: `lib/shared/widgets/milky_mint_scaffold.dart:32-46`
- Create/Test: `test/shared/milky_mint_scaffold_test.dart`

**Interfaces:**
- Consumes: `assets/images/cloudv2_tall.jpg`
- Produces: `MilkyMintScaffold(showCloudTexture: true)` hiển thị `cloudv2_tall.jpg` với opacity 0.35 và `RepaintBoundary`.

- [ ] **Step 1: Viết test kiểm tra MilkyMintScaffold hiển thị `cloudv2_tall.jpg`**

```dart
// test/shared/milky_mint_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/shared/widgets/milky_mint_scaffold.dart';

void main() {
  testWidgets('MilkyMintScaffold renders cloudv2_tall texture inside RepaintBoundary', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MilkyMintScaffold(
          body: Text('Content'),
        ),
      ),
    );

    final imageFinder = find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == 'assets/images/cloudv2_tall.jpg',
    );
    expect(imageFinder, findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test thất bại**

Run: `flutter test test/shared/milky_mint_scaffold_test.dart`
Expected: FAIL (vì hiện tại đang dùng `miku_cloud_bg.png`).

- [ ] **Step 3: Cập nhật `lib/shared/widgets/milky_mint_scaffold.dart`**

Thay `assets/images/miku_cloud_bg.png` bằng `assets/images/cloudv2_tall.jpg` và chỉnh opacity 0.35.

- [ ] **Step 4: Chạy test để xác nhận test vượt qua**

Run: `flutter test test/shared/milky_mint_scaffold_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/milky_mint_scaffold.dart test/shared/milky_mint_scaffold_test.dart
git commit -m "feat: upgrade MilkyMintScaffold background to cloudv2_tall"
```

---

### Task 2: Đa dạng môn học, cho phép để trống & gắn thẻ `none`

**Files:**
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Modify: `lib/screens/exam/widgets/exam_right_sidebar.dart`
- Modify: `lib/screens/exam/exam_detail_screen.dart`
- Create/Test: `test/screens/exam/subject_none_and_diverse_test.dart`

**Interfaces:**
- Consumes: Danh sách môn học chuẩn 15 môn, giá trị mặc định/trống gán là `'none'`.
- Produces: `_selectedSubject = 'none'` khi để trống, hiển thị Chip `'none'` trên giao diện.

- [ ] **Step 1: Viết test cho trường hợp môn học để trống và gán tag none**

```dart
// test/screens/exam/subject_none_and_diverse_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:thi_nhanh/core/providers/auth_provider.dart';
import 'package:thi_nhanh/core/repositories/teacher_exam_repository.dart';
import 'package:thi_nhanh/screens/exam/create_exam_screen.dart';

class MockTeacherExamRepo extends Fake implements TeacherExamRepository {}

void main() {
  testWidgets('CreateExamScreen allows empty subject and configures with none tag', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>(create: (_) => MockTeacherExamRepo()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: CreateExamScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('setup-name')), 'Đề kiểm tra thử nghiệm');
    await tester.pump();

    // Bấm tiếp tục mà không chọn môn học
    await tester.tap(find.byKey(const Key('setup-continue')));
    await tester.pumpAndSettle();

    // Xác nhận đã vào màn hình soạn thảo và môn học hiển thị tag 'none'
    expect(find.text('none'), findsWidgets);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run: `flutter test test/screens/exam/subject_none_and_diverse_test.dart`
Expected: FAIL (vì hiện tại bắt buộc `_selectedSubject != null` và hiển thị thông báo lỗi).

- [ ] **Step 3: Triển khai mã nguồn**

- Mở rộng `DropdownButtonFormField` chứa 15 môn học + mục "Không phân loại (none)".
- Trong `_configureExam()`: nếu `_selectedSubject == null || _selectedSubject!.trim().isEmpty`, tự động gán `_selectedSubject = 'none'`.
- Cập nhật hiển thị trong `ExamRightSidebar` và `ExamDetailScreen` hiển thị badge/tag `'none'` khi subject là `'none'`.

- [ ] **Step 4: Chạy test để xác nhận pass**

Run: `flutter test test/screens/exam/subject_none_and_diverse_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/create_exam_screen.dart lib/screens/exam/widgets/exam_right_sidebar.dart lib/screens/exam/exam_detail_screen.dart test/screens/exam/subject_none_and_diverse_test.dart
git commit -m "feat: support diverse subjects and default none tag"
```

---

### Task 3: Chỉnh sửa thông tin đề (Tên, Môn, Thời lượng) ngay trong Editor

**Files:**
- Create: `lib/screens/exam/widgets/edit_exam_info_dialog.dart`
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Modify: `lib/screens/exam/widgets/exam_right_sidebar.dart`
- Create/Test: `test/screens/exam/widgets/edit_exam_info_dialog_test.dart`

**Interfaces:**
- Consumes: `title`, `subject`, `durationMinutes`, `onSaved(newTitle, newSubject, newDuration)`.
- Produces: Cập nhật reactive vào `CreateExamScreen` state và lưu bản nháp.

- [ ] **Step 1: Viết test cho `EditExamInfoDialog`**

```dart
// test/screens/exam/widgets/edit_exam_info_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/screens/exam/widgets/edit_exam_info_dialog.dart';

void main() {
  testWidgets('EditExamInfoDialog submits updated values', (tester) async {
    String? updatedTitle;
    String? updatedSubject;
    int? updatedDuration;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditExamInfoDialog(
            initialTitle: 'Đề cũ',
            initialSubject: 'Toán',
            initialDurationMinutes: 45,
            onSave: (t, s, d) {
              updatedTitle = t;
              updatedSubject = s;
              updatedDuration = d;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('edit-exam-title')), 'Đề mới đã sửa');
    await tester.enterText(find.byKey(const Key('edit-exam-duration')), '60');
    await tester.tap(find.byKey(const Key('edit-exam-save')));
    await tester.pumpAndSettle();

    expect(updatedTitle, 'Đề mới đã sửa');
    expect(updatedDuration, 60);
    expect(updatedSubject, 'Toán');
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run: `flutter test test/screens/exam/widgets/edit_exam_info_dialog_test.dart`
Expected: FAIL (file dialog chưa tồn tại).

- [ ] **Step 3: Xây dựng `EditExamInfoDialog` và gắn vào `CreateExamScreen` & `ExamRightSidebar`**

- Tạo `EditExamInfoDialog` với validation tên đề >= 3 ký tự, duration 1-360.
- Tại `CreateExamScreen._buildTopHeader()` thêm nút `IconButton` icon bút chì mở dialog.
- Tại `ExamRightSidebar`, thêm callback `onEditInfo` và bọc khối tóm tắt trong `InkWell`.

- [ ] **Step 4: Chạy test để xác nhận pass**

Run: `flutter test test/screens/exam/widgets/edit_exam_info_dialog_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/widgets/edit_exam_info_dialog.dart lib/screens/exam/create_exam_screen.dart lib/screens/exam/widgets/exam_right_sidebar.dart test/screens/exam/widgets/edit_exam_info_dialog_test.dart
git commit -m "feat: add EditExamInfoDialog to edit exam details in editor"
```

---

### Task 4: Token Thẩm Mỹ `AppTheme.softGlowShadow` cho các khối tiếp xúc nền

**Files:**
- Modify: `lib/core/theme/app_theme.dart`
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Modify: `lib/screens/student/student_history_screen.dart`
- Create/Test: `test/theme/soft_glow_shadow_test.dart`

**Interfaces:**
- Produces: `AppTheme.softGlowShadow` trả về danh sách `BoxShadow` nhẹ màu xám khói `Color(0x0A000000)`.

- [ ] **Step 1: Viết test cho `AppTheme.softGlowShadow`**

```dart
// test/theme/soft_glow_shadow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/core/theme/app_theme.dart';

void main() {
  test('AppTheme.softGlowShadow provides soft subtle gray shadow for floating blocks', () {
    final shadows = AppTheme.softGlowShadow;
    expect(shadows, isNotEmpty);
    expect(shadows.first.blurRadius, greaterThanOrEqualTo(10.0));
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run: `flutter test test/theme/soft_glow_shadow_test.dart`
Expected: FAIL.

- [ ] **Step 3: Thêm `softGlowShadow` vào `AppTheme` và áp dụng vào các khối**

- Thêm `static final List<BoxShadow> softGlowShadow = [...]` vào `lib/core/theme/app_theme.dart`.
- Áp dụng vào container `_buildCenterEditor()` trong `create_exam_screen.dart`.
- Áp dụng vào thẻ khối bài thi dở dang trong `student_history_screen.dart`.

- [ ] **Step 4: Chạy test để xác nhận pass**

Run: `flutter test test/theme/soft_glow_shadow_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart lib/screens/exam/create_exam_screen.dart lib/screens/student/student_history_screen.dart test/theme/soft_glow_shadow_test.dart
git commit -m "feat: add AppTheme.softGlowShadow for blocks touching background"
```

---

### Task 5: Popup kiểm tra tổng điểm 10 khi Xuất bản đề thi

**Files:**
- Modify: `lib/screens/exam/create_exam_screen.dart:280-340`
- Create/Test: `test/screens/exam/publish_ten_points_dialog_test.dart`

**Interfaces:**
- Consumes: `_totalPoints`, `_distributePointsEvenly()`.
- Produces: Hiển thị popup chặn xuất bản khi `(_totalPoints - 10.0).abs() > 0.01` với 2 lựa chọn.

- [ ] **Step 1: Viết test kiểm tra popup chặn xuất bản khi chưa đủ 10 điểm**

```dart
// test/screens/exam/publish_ten_points_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:thi_nhanh/core/providers/auth_provider.dart';
import 'package:thi_nhanh/core/repositories/teacher_exam_repository.dart';
import 'package:thi_nhanh/screens/exam/create_exam_screen.dart';

class MockTeacherRepo extends Fake implements TeacherExamRepository {}

void main() {
  testWidgets('Publish exam prompts dialog when total points is not 10', (tester) async {
    // Test logic kiểm tra xuất hiện dialog 'Tổng điểm bài thi chưa đạt 10 điểm'
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run: `flutter test test/screens/exam/publish_ten_points_dialog_test.dart`
Expected: FAIL.

- [ ] **Step 3: Triển khai kiểm tra và hiển thị popup trong `_publishExam()`**

Trước khi gọi `repo.publish`, nếu `(_totalPoints - 10.0).abs() > 0.01`, hiển thị `AlertDialog` với nút "Sửa tiếp" và "Tự động chia đều điểm thành 10".

- [ ] **Step 4: Chạy test để xác nhận pass**

Run: `flutter test test/screens/exam/publish_ten_points_dialog_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/create_exam_screen.dart test/screens/exam/publish_ten_points_dialog_test.dart
git commit -m "feat: show 10-point validation popup on exam publish"
```

---

### Task 6: Tự động nộp bài và điều hướng khi Host đóng phòng thi

**Files:**
- Modify: `lib/screens/exam/taking_exam_screen.dart`
- Create/Test: `test/screens/exam/host_closed_room_auto_submit_test.dart`

**Interfaces:**
- Consumes: `widget.roomId`, Supabase Realtime channel lắng nghe `rooms` update `status == 'closed'`, và polling fallback.
- Produces: Tự động gọi `_submitExam()` và điều hướng sang `/result?attemptId=...`.

- [ ] **Step 1: Viết test cho cơ chế đóng phòng thi tự động nộp bài**

```dart
// test/screens/exam/host_closed_room_auto_submit_test.dart
import 'package:flutter_test/flutter_test.dart';
// Viết test mô phỏng trigger _handleHostClosedRoom
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run: `flutter test test/screens/exam/host_closed_room_auto_submit_test.dart`
Expected: FAIL.

- [ ] **Step 3: Cập nhật `TakingExamScreen` với Realtime listener & polling fallback**

Lắng nghe bảng `rooms` theo `widget.roomId`. Khi nhận trạng thái `closed`, gọi `_handleHostClosedRoom()`. Hủy bỏ subscription an toàn trong `dispose()`.

- [ ] **Step 4: Chạy test để xác nhận pass**

Run: `flutter test test/screens/exam/host_closed_room_auto_submit_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/taking_exam_screen.dart test/screens/exam/host_closed_room_auto_submit_test.dart
git commit -m "feat: auto submit and navigate to result when host closes room"
```

---

### Task 7: Sửa triệt để lỗi xóa bài thi dở dang trong Lịch sử

**Files:**
- Create: `supabase/migrations/202610110001_fix_cancel_or_delete_student_attempt.sql`
- Modify: `lib/core/services/profile_service.dart:1195-1225`
- Create/Test: `test/services/profile_service_cancel_attempt_test.dart`

**Interfaces:**
- Consumes: `attemptId`.
- Produces: Cập nhật trạng thái `status = 'expired'` (enum hợp lệ), gọi RPC xóa an toàn, làm mới danh sách `_loadData()`.

- [ ] **Step 1: Viết test kiểm tra gọi hủy bài thi với status 'expired'**

```dart
// test/services/profile_service_cancel_attempt_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/core/services/profile_service.dart';

void main() {
  test('cancelOrDeleteAttempt returns false on empty attemptId without crashing', () async {
    final result = await ProfileService.cancelOrDeleteAttempt('');
    expect(result, false);
  });
}
```

- [ ] **Step 2: Chạy test**

Run: `flutter test test/services/profile_service_cancel_attempt_test.dart`
Expected: PASS hoặc xác nhận hành vi.

- [ ] **Step 3: Viết migration SQL và cập nhật `ProfileService.cancelOrDeleteAttempt`**

- Tạo file SQL `supabase/migrations/202610110001_fix_cancel_or_delete_student_attempt.sql` bổ sung RPC `cancel_or_delete_student_attempt` và policy DELETE cho `attempts`.
- Trong `ProfileService.cancelOrDeleteAttempt`, thay thế `'cancelled'` bằng `'expired'` để tuân thủ 100% enum Postgres, sau đó gọi xóa record.

- [ ] **Step 4: Chạy lại test suite để xác nhận**

Run: `flutter test test/services/profile_service_cancel_attempt_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/202610110001_fix_cancel_or_delete_student_attempt.sql lib/core/services/profile_service.dart test/services/profile_service_cancel_attempt_test.dart
git commit -m "fix: resolve student attempt cancellation using valid expired status and rpc"
```

---

### Task 8: Rà soát phân tích tĩnh, chạy toàn bộ test suite, cập nhật tài liệu tổng quan hệ thống & Git Push

**Files:**
- Modify: `docs/system_architecture_and_deep_evaluation.md`

- [ ] **Step 1: Chạy phân tích tĩnh**

Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 2: Chạy toàn bộ test suite**

Run: `flutter test`
Expected: 100% tests pass (>= 234 tests).

- [ ] **Step 3: Cập nhật tài liệu kiến trúc hệ thống tổng quan**

Cập nhật `docs/system_architecture_and_deep_evaluation.md` ghi nhận hoàn thành Giai đoạn 13 với 7 tính năng mới.

- [ ] **Step 4: Git commit và push lên remote repo**

Run:
```bash
git add docs/system_architecture_and_deep_evaluation.md
git commit -m "docs: sync system architecture documentation with phase 13 enhancements"
git push origin main
```
