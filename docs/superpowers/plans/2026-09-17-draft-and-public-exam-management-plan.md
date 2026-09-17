# Quản Lý Đề Nháp Và Công Khai Đề (Draft & Public Exam Management) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng tính năng quản lý đề nháp và công khai đề trong màn hình "Đề của tôi" (`/teacher_exams`), đồng thời bổ sung nút "Lưu & Xuất bản ngay" trong màn hình Tạo đề (`/create_exam`), giải quyết triệt để lỗi không tìm thấy đề vừa tạo do RLS.

**Architecture:** Sử dụng trực tiếp RPC Supabase `teacher_exam_summaries` và `publish_teacher_exam` thông qua `TeacherExamRepository`, nâng cấp màn hình `TeacherExamsScreen` thành trung tâm quản lý với 3 Tab (Tất cả, Đề nháp, Đã công khai), Search theo tên/mã đề, Filter chip môn học, và các Dialog xác nhận Public / Xóa nháp an toàn.

**Tech Stack:** Flutter, Dart, Supabase RPC, GoRouter, Provider.

## Global Constraints
- Nền tảng: Flutter 3.x trên Web & Mobile
- Mọi thay đổi hoàn thành phải chạy `flutter test` xác minh thành công.
- Tự động `git commit` và `git push` theo quy tắc dự án sau khi hoàn thành.
- Không sửa schema database backend nếu RPC đã có sẵn đáp ứng đủ yêu cầu.

---

### Task 1: Nâng cấp `TeacherExamSummary` Model và `TeacherExamRepository`

**Files:**
- Modify: `lib/core/repositories/teacher_exam_repository.dart`
- Create/Modify: `test/repositories/teacher_exam_repository_test.dart`

**Interfaces:**
- Consumes: Supabase RPC `teacher_exam_summaries`, `publish_teacher_exam`, bảng `exams`
- Produces: 
  - `TeacherExamSummary` với các thuộc tính: `id`, `code`, `title`, `subject`, `durationMinutes`, `questionCount`, `status`, `createdAt`, `isDraft`, `isPublished`.
  - `TeacherExamRepository.deleteDraft(String examId)` trả về `Future<void>`.

- [ ] **Step 1: Viết failing unit test cho `TeacherExamSummary` và `deleteDraft`**

```dart
// test/repositories/teacher_exam_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';

void main() {
  group('TeacherExamSummary Model', () {
    test('parses all fields from json correctly including code and createdAt', () {
      final json = {
        'id': 'exam-123',
        'code': 'DT001234',
        'title': 'Đề thi Toán học kỳ 1',
        'subject': 'Toán',
        'durationMinutes': 60,
        'questionCount': 25,
        'status': 'draft',
        'createdAt': '2026-09-17T10:00:00Z',
      };

      final summary = TeacherExamSummary.fromJson(json);

      expect(summary.id, 'exam-123');
      expect(summary.code, 'DT001234');
      expect(summary.title, 'Đề thi Toán học kỳ 1');
      expect(summary.subject, 'Toán');
      expect(summary.durationMinutes, 60);
      expect(summary.questionCount, 25);
      expect(summary.status, 'draft');
      expect(summary.isDraft, true);
      expect(summary.isPublished, false);
      expect(summary.createdAt, isNotNull);
    });

    test('isPublished returns true when status is published', () {
      final json = {
        'id': 'exam-456',
        'code': 'DT005678',
        'title': 'Đề thi Vật lý',
        'subject': 'Vật lý',
        'durationMinutes': 45,
        'questionCount': 30,
        'status': 'published',
      };

      final summary = TeacherExamSummary.fromJson(json);

      expect(summary.isDraft, false);
      expect(summary.isPublished, true);
    });
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test fail**

Run: `flutter test test/repositories/teacher_exam_repository_test.dart`
Expected: FAIL (do chưa có getter `isDraft`, `isPublished`, trường `code`, `createdAt`)

- [ ] **Step 3: Cập nhật `TeacherExamSummary` và bổ sung `deleteDraft` trong `TeacherExamRepository`**

```dart
// lib/core/repositories/teacher_exam_repository.dart
class TeacherExamSummary {
  const TeacherExamSummary({
    required this.id,
    required this.title,
    required this.subject,
    required this.durationMinutes,
    required this.questionCount,
    required this.status,
    this.code = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String subject;
  final int durationMinutes;
  final int questionCount;
  final String status;
  final String code;
  final DateTime? createdAt;

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';

  factory TeacherExamSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['createdAt'] as String);
      } catch (_) {}
    }

    return TeacherExamSummary(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Đề thi',
      subject: json['subject'] as String? ?? 'Chung',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      code: json['code'] as String? ?? '',
      createdAt: parsedDate,
    );
  }
}
```

Và thêm trong `TeacherExamRepository`:
```dart
  Future<void> deleteDraft(String examId) => SupabaseRetryHelper.run(
        () => _client.from('exams').delete().eq('id', examId).eq('status', 'draft'),
      );
```

- [ ] **Step 4: Chạy lại test để xác nhận test pass**

Run: `flutter test test/repositories/teacher_exam_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/repositories/teacher_exam_repository.dart test/repositories/teacher_exam_repository_test.dart
git commit -m "feat: enhance TeacherExamSummary model and add deleteDraft method"
```

---

### Task 2: Xây dựng các Dialog xác nhận: `PublishConfirmDialog` và `DeleteDraftConfirmDialog`

**Files:**
- Create: `lib/screens/teacher/widgets/publish_confirm_dialog.dart`
- Create: `lib/screens/teacher/widgets/delete_draft_confirm_dialog.dart`
- Create: `test/widgets/exam_management_dialogs_test.dart`

**Interfaces:**
- Consumes: `TeacherExamSummary`, theme constants
- Produces:
  - `PublishConfirmDialog(summary: ..., onConfirmed: () async {})`
  - `DeleteDraftConfirmDialog(summary: ..., onConfirmed: () async {})`

- [ ] **Step 1: Viết failing test cho `PublishConfirmDialog` và `DeleteDraftConfirmDialog`**

```dart
// test/widgets/exam_management_dialogs_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/teacher/widgets/publish_confirm_dialog.dart';
import 'package:onthi_community/screens/teacher/widgets/delete_draft_confirm_dialog.dart';

void main() {
  const summary = TeacherExamSummary(
    id: 'exam-1',
    code: 'DT123456',
    title: 'Kiểm tra 15 phút Vật Lý 12',
    subject: 'Vật lý',
    durationMinutes: 15,
    questionCount: 10,
    status: 'draft',
  );

  testWidgets('PublishConfirmDialog renders exam details and checklist', (tester) async {
    bool confirmed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PublishConfirmDialog(
          summary: summary,
          onConfirmed: () async {
            confirmed = true;
          },
        ),
      ),
    ));

    expect(find.text('Xuất bản đề thi'), findsOneWidget);
    expect(find.textContaining('Kiểm tra 15 phút Vật Lý 12'), findsOneWidget);
    expect(find.text('Xác nhận Xuất bản'), findsOneWidget);

    await tester.tap(find.text('Xác nhận Xuất bản'));
    await tester.pumpAndSettle();
    expect(confirmed, true);
  });

  testWidgets('DeleteDraftConfirmDialog renders delete warning', (tester) async {
    bool deleted = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeleteDraftConfirmDialog(
          summary: summary,
          onConfirmed: () async {
            deleted = true;
          },
        ),
      ),
    ));

    expect(find.text('Xóa bản nháp'), findsOneWidget);
    expect(find.textContaining('không thể khôi phục'), findsOneWidget);

    await tester.tap(find.text('Xóa vĩnh viễn'));
    await tester.pumpAndSettle();
    expect(deleted, true);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run: `flutter test test/widgets/exam_management_dialogs_test.dart`
Expected: FAIL (files chưa tồn tại)

- [ ] **Step 3: Tạo `PublishConfirmDialog` và `DeleteDraftConfirmDialog`**

Tạo `lib/screens/teacher/widgets/publish_confirm_dialog.dart`:
- Thiết kế Dialog trực quan:
  - Header với icon rocket/public.
  - Thẻ thông tin đề: Tên đề, Môn học, Thời gian, Số câu hỏi.
  - Danh sách checklist hợp lệ:
    - [x] Có ít nhất 1 câu hỏi (hiển thị cảnh báo đỏ nếu `questionCount == 0`).
    - [x] Tiêu đề từ 3 ký tự trở lên.
  - Nút Hủy và Nút Xác nhận Xuất bản (có loading state).

Tạo `lib/screens/teacher/widgets/delete_draft_confirm_dialog.dart`:
- Header với icon thùng rác màu đỏ.
- Nội dung cảnh báo xóa vĩnh viễn không khôi phục.
- Nút Hủy và Nút Xóa vĩnh viễn.

- [ ] **Step 4: Chạy lại test để xác nhận pass**

Run: `flutter test test/widgets/exam_management_dialogs_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/teacher/widgets/ test/widgets/exam_management_dialogs_test.dart
git commit -m "feat: add PublishConfirmDialog and DeleteDraftConfirmDialog components"
```

---

### Task 3: Nâng cấp Màn hình Quản Lý Đề Thi (`TeacherExamsScreen`)

**Files:**
- Modify: `lib/screens/teacher/teacher_exams_screen.dart`
- Modify/Create: `test/screens/teacher_manage_exams_screen_test.dart`

**Interfaces:**
- Consumes: `TeacherExamRepository.summaries()`, `TeacherExamRepository.publish()`, `TeacherExamRepository.deleteDraft()`, `AuthProvider`
- Produces: Màn hình `/teacher_exams` hoàn chỉnh với 3 Tab, Search theo tên/mã đề, Chip môn học, và Contextual Cards.

- [ ] **Step 1: Viết failing widget test cho `TeacherExamsScreen`**

```dart
// test/screens/teacher_manage_exams_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/teacher/teacher_exams_screen.dart';

class MockTeacherExamRepository implements TeacherExamRepository {
  List<TeacherExamSummary> mockList = [
    const TeacherExamSummary(
      id: 'exam-1',
      code: 'DT001',
      title: 'Đề Nháp Số 1',
      subject: 'Toán',
      durationMinutes: 45,
      questionCount: 10,
      status: 'draft',
    ),
    const TeacherExamSummary(
      id: 'exam-2',
      code: 'DT002',
      title: 'Đề Công Khai Số 1',
      subject: 'Vật lý',
      durationMinutes: 60,
      questionCount: 20,
      status: 'published',
    ),
  ];

  @override
  Future<List<TeacherExamSummary>> summaries() async => mockList;

  @override
  Future<void> publish(String examId) async {}

  @override
  Future<void> deleteDraft(String examId) async {
    mockList.removeWhere((e) => e.id == examId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TeacherExamsScreen renders 3 tabs with badges and filters by tab', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockTeacherExamRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>.value(value: mockRepo),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TeacherExamsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 3 tabs present
    expect(find.textContaining('Tất cả'), findsOneWidget);
    expect(find.textContaining('Đề nháp'), findsOneWidget);
    expect(find.textContaining('Đã công khai'), findsOneWidget);

    // Initial tab 'Tất cả' should show both exams
    expect(find.text('Đề Nháp Số 1'), findsOneWidget);
    expect(find.text('Đề Công Khai Số 1'), findsOneWidget);

    // Tap tab 'Đề nháp'
    await tester.tap(find.textContaining('Đề nháp'));
    await tester.pumpAndSettle();

    expect(find.text('Đề Nháp Số 1'), findsOneWidget);
    expect(find.text('Đề Công Khai Số 1'), findsNothing);
    expect(find.text('Public đề'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run: `flutter test test/screens/teacher_manage_exams_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Viết triển khai hoàn thiện cho `TeacherExamsScreen`**

Nâng cấp `lib/screens/teacher/teacher_exams_screen.dart`:
- Đọc danh sách bằng `context.read<TeacherExamRepository>().summaries()` (bảo vệ bằng try-catch và `mounted`).
- Xử lý trạng thái chưa đăng nhập (`!authProvider.isAuthenticated`): hiển thị Banner gợi ý đăng nhập đẹp mắt.
- Thêm TabBar 3 mục: `Tất cả (${allCount})`, `Đề nháp (${draftCount})`, `Đã công khai (${publishedCount})`.
- Thêm Filter chip môn học: `Tất cả môn`, `Toán`, `Vật lý`, `Hóa học`, `Tiếng Anh`...
- Ô tìm kiếm lọc theo cả `title` và `code`.
- Mỗi thẻ đề hiển thị trạng thái `Bản nháp` hoặc `Đã xuất bản`.
- Nút `Public đề` trên đề nháp mở `PublishConfirmDialog` -> gọi `repo.publish(id)` -> thành công chuyển tab sang Đã công khai và hiển thị SnackBar kèm nút `Tạo phòng ngay`.
- Nút `Xóa nháp` mở `DeleteDraftConfirmDialog` -> gọi `repo.deleteDraft(id)` -> refresh danh sách.
- Nút `Chỉnh sửa` chuyển tới `/create_exam?examId=...`.
- Nút `Tạo phòng thi` chuyển tới `/create_room?examId=...`.

- [ ] **Step 4: Chạy lại test để xác nhận pass**

Run: `flutter test test/screens/teacher_manage_exams_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/teacher/teacher_exams_screen.dart test/screens/teacher_manage_exams_screen_test.dart
git commit -m "feat: upgrade TeacherExamsScreen with 3 tabs, search, filters and contextual actions"
```

---

### Task 4: Nâng cấp Màn hình Tạo Đề (`CreateExamScreen`) với Nút "Lưu & Xuất Bản Ngay"

**Files:**
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Modify: `test/screens/create_exam_screen_test.dart`

**Interfaces:**
- Consumes: `TeacherExamRepository.saveDraft()`, `TeacherExamRepository.publish()`
- Produces: Nút `Lưu bản nháp` và `Lưu & Xuất bản ngay`, kiểm tra validation từng câu hỏi chi tiết.

- [ ] **Step 1: Viết failing test cho nút "Lưu & Xuất bản ngay" trong `CreateExamScreen`**

```dart
// test/screens/create_exam_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/exam/create_exam_screen.dart';

class MockExamRepo implements TeacherExamRepository {
  @override
  Future<String> saveDraft({String? examId, required String title, required String subject, required int durationMinutes, required List<Map<String, dynamic>> questions}) async => 'new-id';

  @override
  Future<void> publish(String examId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CreateExamScreen setup and bottom bar shows publish button', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>(create: (_) => MockExamRepo()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: CreateExamScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill setup form
    await tester.enterText(find.byKey(const Key('setup-name')), 'Đề kiểm tra đại số');
    await tester.tap(find.byKey(const Key('setup-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toán').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup-continue')));
    await tester.pumpAndSettle();

    // Bottom action bar should have both "Lưu nháp" and "Lưu & Xuất bản ngay"
    expect(find.text('Lưu nháp'), findsOneWidget);
    expect(find.text('Lưu & Xuất bản ngay'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run: `flutter test test/screens/create_exam_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Triển khai cập nhật `CreateExamScreen`**

- Thêm phương thức `_validateQuestions()` trả về index của câu hỏi lỗi hoặc null nếu tất cả hợp lệ.
- Thêm phương thức `_publishExam()`:
  1. Kiểm tra validation các câu hỏi. Nếu có lỗi, chuyển `_activeQuestionIndex` đến câu đó và hiện SnackBar thông báo: "Hãy nhập nội dung và đủ đáp án cho Câu X".
  2. Gọi `_saveDraft()`.
  3. Gọi `context.read<TeacherExamRepository>().publish(_examId!)`.
  4. Hiển thị Dialog chúc mừng xuất bản thành công với mã đề (nếu có) và 2 lựa chọn: "Tạo phòng thi ngay" (`/create_room?examId=$_examId`) hoặc "Xem danh sách đề" (`/teacher_exams`).
- Cập nhật nút dưới bottom bar:
  - `Lưu bản nháp`: Lưu nháp và ở lại màn hình, báo SnackBar xanh.
  - `Lưu & Xuất bản ngay`: Nút Primary nổi bật với icon rocket/publish.

- [ ] **Step 4: Chạy lại test để xác nhận pass**

Run: `flutter test test/screens/create_exam_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/create_exam_screen.dart test/screens/create_exam_screen_test.dart
git commit -m "feat: add save and publish directly from CreateExamScreen"
```

---

### Task 5: Kiểm tra toàn bộ Test Suite và Xác minh Hợp nhất

**Files:**
- Toàn bộ test suite trong thư mục `test/`

- [ ] **Step 1: Chạy toàn bộ test**

Run: `flutter test`
Expected: Tất cả các test đều PASS không có lỗi.

- [ ] **Step 2: Kiểm tra Linting và Static Analysis**

Run: `flutter analyze`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Commit & Push lên Git**

```bash
git commit -m "chore: verify tests and finalize draft and public exam feature"
git push origin main
```
