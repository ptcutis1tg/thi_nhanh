# Saved Community Exams & Exam Detail Preview with Quick-Jump Navigator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm tính năng lưu đề thi từ thẻ tìm kiếm về kho cá nhân để mở phòng thi trực tiếp với đề thi của cộng đồng (không nhân bản rác database), đồng thời nâng cấp màn hình Chi tiết đề thi (`ExamDetailScreen`) với nút Lưu đề, mũi tên chỉ báo cuộn mượt và vùng xem trước toàn bộ câu hỏi, đáp án, lời giải kèm bảng con Quick-Jump Navigator để nhảy nhanh đến từng câu.

**Architecture:** Sử dụng kiến trúc Lưu tham chiếu có quyền Host (Host-Authorized Bookmark) qua bảng `public.saved_exams` và mở rộng kiểm tra trong RPC `public.create_teacher_room`. Tầng giao diện sử dụng `SavedExamRepository` tích hợp `MultiProvider`, `ExamDetailScreen` được thiết kế 2 tầng (Hero Overview và Detailed Question Section với Sidebar Jump Controller), thẻ `SearchScreen` tích hợp nút Lưu nhanh 1 chạm, và `CreateRoomScreen` bổ sung bộ lọc chọn đề cộng đồng đã lưu.

**Tech Stack:** Flutter 3.x, Dart 3.x, GoRouter, Provider, Supabase PostgreSQL with RLS, GoogleFonts (Be Vietnam Pro & Fira Code), Material 3.

## Global Constraints
- Bảo toàn tuyệt đối 100% logic chống gian lận, điều hướng 4 mục trên `TopNavBar` và tỷ lệ vượt qua của toàn bộ **186/186 bài kiểm thử hiện có** (`flutter test`).
- Không sinh bản sao đề thi trùng lặp trên trang Tìm kiếm (`SearchScreen`).
- Hỗ trợ đầy đủ chế độ khách (Guest): Nếu người dùng chưa đăng nhập bấm "Lưu đề" thì hiển thị thông báo yêu cầu đăng nhập.

---

### Task 1: Migration Cơ Sở Dữ Liệu & Phân Quyền Mở Phòng Thi

**Files:**
- Create: `supabase/migrations/202610090001_saved_exams_and_host_permission.sql`
- Test: `test/migrations/saved_exams_migration_test.dart`

**Interfaces:**
- Consumes: Bảng `public.exams`, `auth.users`, hàm `public.ensure_current_teacher()`
- Produces: Bảng `public.saved_exams`, chính sách RLS, hàm `public.create_teacher_room` được cập nhật cho phép đề đã lưu

- [ ] **Step 1: Viết test xác nhận migration SQL hợp lệ và các mệnh đề cần thiết**

Tạo `test/migrations/saved_exams_migration_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved_exams migration contains table creation, RLS, and updated create_teacher_room', () {
    final file = File('supabase/migrations/202610090001_saved_exams_and_host_permission.sql');
    expect(file.existsSync(), isTrue, reason: 'Migration file must exist');

    final content = file.readAsStringSync();
    expect(content, contains('create table if not exists public.saved_exams'));
    expect(content, contains('references public.exams(id)'));
    expect(content, contains('enable row level security'));
    expect(content, contains('create or replace function public.create_teacher_room'));
    expect(content, contains('public.saved_exams se'));
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test thất bại**

Run: `flutter test test/migrations/saved_exams_migration_test.dart`
Expected: FAIL (File not found)

- [ ] **Step 3: Viết migration SQL**

Tạo `supabase/migrations/202610090001_saved_exams_and_host_permission.sql`:
```sql
-- Migration: 202610090001_saved_exams_and_host_permission.sql
-- Description: Table for saving community exams & authorization to host rooms from saved exams

create table if not exists public.saved_exams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, exam_id)
);

alter table public.saved_exams enable row level security;

-- Drop old policies if exist
drop policy if exists "users can manage their own saved exams" on public.saved_exams;
drop policy if exists "users can view their saved exams" on public.saved_exams;

create policy "users can manage their own saved exams"
on public.saved_exams
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can view their saved exams"
on public.saved_exams
for select
to authenticated
using (auth.uid() = user_id);

-- Update create_teacher_room to allow creating room from saved published exams
create or replace function public.create_teacher_room(
  p_exam_id uuid, p_name text, p_password text default null, p_max_participants integer default 50
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_teacher_id uuid; v_room public.rooms;
begin
  v_teacher_id := public.ensure_current_teacher();
  if char_length(trim(p_name)) < 3 then raise exception 'Room name must have at least 3 characters'; end if;
  if p_max_participants not between 1 and 1000 then raise exception 'Participant limit must be between 1 and 1000'; end if;
  
  if not exists (
    select 1 from public.exams e
    where e.id = p_exam_id and e.status = 'published'
    and (
      e.teacher_id = v_teacher_id
      or exists (
        select 1 from public.saved_exams se
        where se.exam_id = e.id and se.user_id = auth.uid()
      )
    )
  ) then
    raise exception 'Chỉ có thể tạo phòng từ đề đã xuất bản của bạn hoặc đề bạn đã lưu từ cộng đồng';
  end if;

  insert into public.rooms (code, exam_id, teacher_id, name, password_hash, max_participants)
  values (
    public.next_room_code(), p_exam_id, v_teacher_id, trim(p_name),
    case when nullif(trim(coalesce(p_password, '')), '') is null then null else extensions.crypt(p_password, extensions.gen_salt('bf')) end,
    p_max_participants
  ) returning * into v_room;
  
  return jsonb_build_object('id', v_room.id, 'code', v_room.code, 'name', v_room.name, 'status', v_room.status);
end;
$$;

grant execute on function public.create_teacher_room(uuid, text, text, integer) to authenticated;
```

- [ ] **Step 4: Chạy lại test migration để xác nhận PASS**

Run: `flutter test test/migrations/saved_exams_migration_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 1**

```bash
git add supabase/migrations/202610090001_saved_exams_and_host_permission.sql test/migrations/saved_exams_migration_test.dart
git commit -m "feat(db): add saved_exams table and update create_teacher_room RPC"
```

---

### Task 2: Xây Dựng `SavedExamRepository` & Đăng Ký Provider

**Files:**
- Create: `lib/core/repositories/saved_exam_repository.dart`
- Modify: `lib/main.dart`
- Test: `test/repositories/saved_exam_repository_test.dart`

**Interfaces:**
- Consumes: `SupabaseClient?`, `TeacherExamSummary`
- Produces: `SavedExamRepository` với `isExamSaved`, `toggleSaveExam`, `getSavedExams`, `savedExamIds`

- [ ] **Step 1: Viết test cho `SavedExamRepository`**

Tạo `test/repositories/saved_exam_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';

void main() {
  group('SavedExamRepository Tests', () {
    test('local fallback tracks saved state in memory when Supabase is uninitialized', () async {
      final repo = SavedExamRepository(null);

      expect(await repo.isExamSaved('exam-1'), isFalse);
      
      final isNowSaved = await repo.toggleSaveExam('exam-1');
      expect(isNowSaved, isTrue);
      expect(await repo.isExamSaved('exam-1'), isTrue);

      final isUnsaved = await repo.toggleSaveExam('exam-1');
      expect(isUnsaved, isFalse);
      expect(await repo.isExamSaved('exam-1'), isFalse);
    });

    test('getSavedExams returns empty or local list gracefully', () async {
      final repo = SavedExamRepository(null);
      final list = await repo.getSavedExams();
      expect(list, isA<List>());
    });
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test thất bại**

Run: `flutter test test/repositories/saved_exam_repository_test.dart`
Expected: FAIL (File not found)

- [ ] **Step 3: Viết triển khai `SavedExamRepository`**

Tạo `lib/core/repositories/saved_exam_repository.dart`:
```dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_exam_repository.dart';
import '../utils/supabase_retry_helper.dart';

class SavedExamRepository {
  SavedExamRepository(this._client);
  final SupabaseClient? _client;

  final Set<String> _localSavedExamIds = <String>{};

  Set<String> get localSavedExamIds => Set.unmodifiable(_localSavedExamIds);

  Future<bool> isExamSaved(String examId) async {
    if (examId.isEmpty) return false;
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return _localSavedExamIds.contains(examId);
    }

    try {
      final res = await SupabaseRetryHelper.run(
        () => client
            .from('saved_exams')
            .select('id')
            .eq('exam_id', examId)
            .eq('user_id', client.auth.currentUser!.id)
            .maybeSingle(),
      );
      final isSaved = res != null;
      if (isSaved) {
        _localSavedExamIds.add(examId);
      } else {
        _localSavedExamIds.remove(examId);
      }
      return isSaved;
    } catch (_) {
      return _localSavedExamIds.contains(examId);
    }
  }

  Future<bool> toggleSaveExam(String examId) async {
    if (examId.isEmpty) return false;
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      if (_localSavedExamIds.contains(examId)) {
        _localSavedExamIds.remove(examId);
        return false;
      } else {
        _localSavedExamIds.add(examId);
        return true;
      }
    }

    final userId = client.auth.currentUser!.id;
    final currentlySaved = await isExamSaved(examId);

    try {
      if (currentlySaved) {
        await SupabaseRetryHelper.run(
          () => client
              .from('saved_exams')
              .delete()
              .eq('exam_id', examId)
              .eq('user_id', userId),
        );
        _localSavedExamIds.remove(examId);
        return false;
      } else {
        await SupabaseRetryHelper.run(
          () => client.from('saved_exams').insert({
            'exam_id': examId,
            'user_id': userId,
          }),
        );
        _localSavedExamIds.add(examId);
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi toggle save exam: $e');
      if (_localSavedExamIds.contains(examId)) {
        _localSavedExamIds.remove(examId);
        return false;
      } else {
        _localSavedExamIds.add(examId);
        return true;
      }
    }
  }

  Future<List<TeacherExamSummary>> getSavedExams() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return [];
    }

    try {
      final res = await SupabaseRetryHelper.run(
        () => client
            .from('saved_exams')
            .select('exam_id, exams(id, code, title, subject, duration_minutes, status, created_at, questions(count))')
            .eq('user_id', client.auth.currentUser!.id)
            .order('created_at', ascending: false),
      );

      final list = res as List<dynamic>;
      final List<TeacherExamSummary> summaries = [];
      for (final item in list) {
        final examMap = item['exams'] as Map<String, dynamic>?;
        if (examMap == null) continue;
        final questions = examMap['questions'] as List<dynamic>?;
        final count = (questions != null && questions.isNotEmpty)
            ? ((questions.first as Map<String, dynamic>?)?['count'] as num?)?.toInt() ?? 0
            : 0;

        summaries.add(
          TeacherExamSummary(
            id: examMap['id']?.toString() ?? '',
            code: examMap['code']?.toString() ?? '',
            title: examMap['title']?.toString() ?? 'Đề thi đã lưu',
            subject: examMap['subject']?.toString() ?? 'Chung',
            durationMinutes: (examMap['duration_minutes'] as num?)?.toInt() ?? 45,
            questionCount: count,
            status: examMap['status']?.toString() ?? 'published',
            createdAt: DateTime.tryParse(examMap['created_at']?.toString() ?? ''),
          ),
        );
      }
      return summaries;
    } catch (e) {
      debugPrint('Lỗi tải danh sách đề đã lưu: $e');
      return [];
    }
  }
}
```

- [ ] **Step 4: Đăng ký `SavedExamRepository` trong `lib/main.dart`**

Thêm `Provider<SavedExamRepository>` trong `MultiProvider` tại `lib/main.dart`:
```dart
Provider<SavedExamRepository>(
  create: (context) => SavedExamRepository(
    Supabase.instance.client,
  ),
),
```

- [ ] **Step 5: Chạy test xác nhận PASS**

Run: `flutter test test/repositories/saved_exam_repository_test.dart`
Expected: PASS

- [ ] **Step 6: Commit Task 2**

```bash
git add lib/core/repositories/saved_exam_repository.dart lib/main.dart test/repositories/saved_exam_repository_test.dart
git commit -m "feat(repo): create SavedExamRepository and register in MultiProvider"
```

---

### Task 3: Nâng Cấp Màn Hình Chi Tiết Đề Thi (`ExamDetailScreen`)

**Files:**
- Modify: `lib/screens/exam/exam_detail_screen.dart`
- Test: `test/screens/exam_detail_preview_test.dart`

**Interfaces:**
- Consumes: `SavedExamRepository`, `AssessmentRepository`, `AuthProvider`
- Produces: Màn hình chi tiết đề thi gồm:
  1. Top Section: Thẻ thông số, nút "Bắt đầu tự luyện", "Thêm vào yêu thích", "Lưu đề" (kèm state lưu).
  2. Bottom indicator: Mũi tên tròn nảy xuống + nhãn "Xem chi tiết câu hỏi & đáp án".
  3. Question Details Section: Toggle "Hiện đáp án & giải thích", danh sách câu hỏi A/B/C/D tô xanh đáp án đúng, khung giải thích chi tiết.
  4. Quick-Jump Navigator Sidebar: Bảng con số câu bấm vào cuộn mượt đến câu đó.

- [ ] **Step 1: Viết test cho màn hình `ExamDetailScreen`**

Tạo `test/screens/exam_detail_preview_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';
import 'package:onthi_community/screens/exam/exam_detail_screen.dart';

void main() {
  testWidgets('ExamDetailScreen renders action buttons and scroll indicator', (tester) async {
    final auth = AuthProvider(isSupabaseInitialized: false);
    final savedRepo = SavedExamRepository(null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          Provider<SavedExamRepository>.value(value: savedRepo),
        ],
        child: const MaterialApp(
          home: ExamDetailScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main action buttons
    expect(find.text('Bắt đầu tự luyện'), findsOneWidget);
    expect(find.text('Lưu đề'), findsOneWidget);
    expect(find.textContaining('Xem chi tiết câu hỏi'), findsOneWidget);

    // Verify quick-jump / question list toggle
    expect(find.text('Hiện đáp án & giải thích'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test thất bại**

Run: `flutter test test/screens/exam_detail_preview_test.dart`
Expected: FAIL

- [ ] **Step 3: Nâng cấp `ExamDetailScreen` trong `lib/screens/exam/exam_detail_screen.dart`**

Tích hợp:
- Bổ sung `SavedExamRepository` trong `initState` để lấy trạng thái `_isSaved`.
- Nút "Lưu đề": Khi bấm gọi `savedRepo.toggleSaveExam()`, cập nhật `_isSaved`, hiển thị SnackBar thông báo.
- Nút mũi tên nảy xuống: `ScaleTransition` + `_scrollController.animateTo(...)` cuộn mượt tới vị trí `_questionsKey`.
- Tải chi tiết câu hỏi và đáp án từ `questions` và `question_options`.
- Thanh Toggle: `SwitchListTile` / `FilterChip` *"Hiện đáp án & giải thích"*.
- Khung câu hỏi: Hiển thị A, B, C, D (tô xanh đáp án đúng khi bật toggle) và khung Lời giải chi tiết.
- Sidebar Quick-Jump Navigator: Danh sách số câu `1..N`, khi bấm dùng `Scrollable.ensureVisible` cuộn đến đúng câu hỏi đó.

- [ ] **Step 4: Chạy lại test `exam_detail_preview_test.dart` để xác nhận PASS**

Run: `flutter test test/screens/exam_detail_preview_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 3**

```bash
git add lib/screens/exam/exam_detail_screen.dart test/screens/exam_detail_preview_test.dart
git commit -m "feat(exam): enhance ExamDetailScreen with save exam button, scroll indicator, full question preview and quick-jump navigator"
```

---

### Task 4: Bổ Sung Nút Lưu Nhanh Trên Thẻ Tìm Kiếm (`SearchScreen`)

**Files:**
- Modify: `lib/screens/home/search_screen.dart`
- Test: `test/screens/search_screen_save_test.dart`

**Interfaces:**
- Consumes: `SavedExamRepository`
- Produces: Nút Icon Bookmark lưu nhanh 1 chạm trên mỗi thẻ đề thi trong `_ResultsGrid`.

- [ ] **Step 1: Viết test cho nút lưu nhanh trên thẻ tìm kiếm**

Tạo `test/screens/search_screen_save_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';
import 'package:onthi_community/screens/home/search_screen.dart';

void main() {
  testWidgets('SearchScreen renders bookmark button and toggles saved state', (tester) async {
    final auth = AuthProvider(isSupabaseInitialized: false);
    final savedRepo = SavedExamRepository(null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          Provider<SavedExamRepository>.value(value: savedRepo),
        ],
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final bookmarkButtons = find.byIcon(Icons.bookmark_border_rounded);
    expect(bookmarkButtons, findsWidgets);

    // Tap the first bookmark button
    await tester.tap(bookmarkButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.bookmark_rounded), findsWidgets);
    expect(find.textContaining('Đã lưu đề vào kho cá nhân'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test thất bại**

Run: `flutter test test/screens/search_screen_save_test.dart`
Expected: FAIL

- [ ] **Step 3: Cập nhật `_ResultsGrid` trong `lib/screens/home/search_screen.dart`**

Thêm nút `IconButton` ở góc thẻ đề thi:
- Icon `isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded`.
- Màu tím `AppTheme.primary`.
- Khi bấm: gọi `context.read<SavedExamRepository>().toggleSaveExam(item.id)`, cập nhật state và hiển thị SnackBar.

- [ ] **Step 4: Chạy lại test xác nhận PASS**

Run: `flutter test test/screens/search_screen_save_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 4**

```bash
git add lib/screens/home/search_screen.dart test/screens/search_screen_save_test.dart
git commit -m "feat(search): add quick one-tap bookmark button to search result cards"
```

---

### Task 5: Nâng Cấp Tạo Phòng Thi & Quản Lý Đề Với Đề Đã Lưu

**Files:**
- Modify: `lib/screens/room/create_room_screen.dart`
- Modify: `lib/screens/teacher/teacher_exams_screen.dart`
- Test: `test/screens/create_room_with_saved_exam_test.dart`

**Interfaces:**
- Consumes: `SavedExamRepository.getSavedExams()`, `TeacherExamRepository.summaries()`
- Produces: Lọc danh sách đề `Tất cả` | `Đề của tôi` | `Đề đã lưu từ cộng đồng`, tạo phòng thi thành công với đề đã lưu.

- [ ] **Step 1: Viết test cho màn hình Tạo phòng thi với đề đã lưu**

Tạo `test/screens/create_room_with_saved_exam_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';

void main() {
  testWidgets('CreateRoomScreen renders saved exams tab and allows selection', (tester) async {
    final savedRepo = SavedExamRepository(null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>.value(value: TeacherExamRepository(FakeSupabaseClient())),
          Provider<SavedExamRepository>.value(value: savedRepo),
          Provider<RoomRepository>.value(value: FakeRoomRepo()),
        ],
        child: const MaterialApp(
          home: CreateRoomScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Đề đã lưu'), findsWidgets);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận thất bại**

Run: `flutter test test/screens/create_room_with_saved_exam_test.dart`
Expected: FAIL

- [ ] **Step 3: Cập nhật `CreateRoomScreen` và `TeacherExamsScreen`**

- Trong `CreateRoomScreen`:
  - Tải đồng thời `summaries()` và `savedRepo.getSavedExams()`.
  - Thêm Segmented tab: `Tất cả` | `Đề của tôi` | `Đề đã lưu`.
  - Hiển thị nhãn *"Đã lưu"* trên thẻ đề thi cộng đồng.
- Trong `TeacherExamsScreen`:
  - Thêm Tab `Đề đã lưu` bên cạnh `Tất cả`, `Đã xuất bản`, `Bản nháp`.

- [ ] **Step 4: Chạy lại test xác nhận PASS**

Run: `flutter test test/screens/create_room_with_saved_exam_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 5**

```bash
git add lib/screens/room/create_room_screen.dart lib/screens/teacher/teacher_exams_screen.dart test/screens/create_room_with_saved_exam_test.dart
git commit -m "feat(room): support saved community exams in CreateRoomScreen and TeacherExamsScreen"
```

---

### Task 6: Kiểm Thử Toàn Diện, Cập Nhật Tài Liệu Kiến Trúc & Tự Động Push

**Files:**
- Modify: `docs/system_architecture_and_deep_evaluation.md`
- Sync: `C:\Users\ADMINE\.gemini\antigravity-ide\brain\d77ac794-44e9-475b-b3a4-5031b5e33f7e\system_architecture_and_deep_evaluation.md`

- [ ] **Step 1: Chạy toàn bộ test suite dự án**

Run: `flutter test`
Expected: PASS 100% (tất cả các bài test cũ và mới).

- [ ] **Step 2: Cập nhật tài liệu kiến trúc tổng quan**

Cập nhật `docs/system_architecture_and_deep_evaluation.md` ghi nhận:
- Bảng mới `public.saved_exams` và cơ chế phân quyền mở phòng từ đề đã lưu.
- Màn hình `ExamDetailScreen` với Question Preview & Quick-Jump Navigator.
- Thẻ tìm kiếm `SearchScreen` với nút Lưu nhanh 1 chạm.

- [ ] **Step 3: Tự động commit và push cả 2 repository**

```bash
# In thi_nhanh:
git add .
git commit -m "chore(docs): sync system architecture documentation with saved exams and quick-jump preview"
git push origin main

# In root CODE:
git add thi_nhanh docs
git commit -m "chore(submodule): update thi_nhanh to latest with saved exams feature"
git push origin main
```
