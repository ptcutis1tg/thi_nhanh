# Exam History Screen & Profile Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the "Chi tiết" redirect bug in `ProfileScreen`, cap recent exams to 10 items, and implement a dedicated `StudentHistoryScreen` with instant keyword search, multi-criteria filters (subject, date, score), 20-item pagination using `GooglePaginationBar` (pages 1, 2, 3...), and direct navigation to exam results.

**Architecture:**
- Extend `StudentTestHistoryData` in `ProfileService` with `subject` and `submittedAt`.
- Fix `ProfileScreen` recent tests card to limit to 10 items and navigate to `/result?attemptId=...` for details, and `/student/history` for view-all.
- Wire `/student/history` inside `TopNavBar` shell in `main.dart`.
- Refactor `StudentHistoryScreen` to use a clean search box, filter panel (subject chips, date presets + range, score categories, sort), card-based attempt list, and `GooglePaginationBar` with 20 items per page.

**Tech Stack:**
- Flutter 3.x, Dart 3.x
- Provider, GoRouter
- `GooglePaginationBar` ([`lib/shared/widgets/google_pagination_bar.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/shared/widgets/google_pagination_bar.dart))
- Supabase Flutter

## Global Constraints
- Auto-push rule: Automatic `git commit` and `git push origin main` after completing work to trigger GitHub Actions.
- TDD: Write failing tests before implementation code for each task.
- Zero breaking changes to `ResultScreen` or existing profile calculations.

---

### Task 1: Extend `StudentTestHistoryData` Model & Data Extraction

**Files:**
- Modify: `lib/core/services/profile_service.dart:25-37,425-455`
- Test: `test/models/student_history_test.dart`

**Interfaces:**
- Produces: `StudentTestHistoryData` with fields `subject` (String) and `submittedAt` (DateTime?).

- [ ] **Step 1: Write the failing unit test**

Create `test/models/student_history_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('StudentTestHistoryData Tests', () {
    test('instantiates with subject and submittedAt fields', () {
      final now = DateTime(2026, 10, 2, 14, 30);
      final item = StudentTestHistoryData(
        id: 'att-123',
        subjectIcon: '📐',
        title: 'Đề thi Toán đại số',
        date: '02/10/2026',
        score: '8.5 điểm',
        scoreValue: 8.5,
        subject: 'Toán',
        submittedAt: now,
      );

      expect(item.id, 'att-123');
      expect(item.subject, 'Toán');
      expect(item.submittedAt, now);
      expect(item.scoreValue, 8.5);
    });

    test('defaults subject to Khác if not provided', () {
      final item = StudentTestHistoryData(
        id: 'att-456',
        subjectIcon: '📝',
        title: 'Đề tổng hợp',
        date: '01/10/2026',
        score: '5.0 điểm',
        scoreValue: 5.0,
      );

      expect(item.subject, 'Khác');
      expect(item.submittedAt, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/student_history_test.dart`  
Expected: FAIL compilation error (named parameters `subject` and `submittedAt` don't exist).

- [ ] **Step 3: Update `StudentTestHistoryData` and `ProfileService.fetchStudentData`**

In `lib/core/services/profile_service.dart`:
```dart
class StudentTestHistoryData {
  final String id;
  final String subjectIcon;
  final String title;
  final String date;
  final String score;
  final double scoreValue;
  final String subject;
  final DateTime? submittedAt;

  StudentTestHistoryData({
    required this.id,
    required this.subjectIcon,
    required this.title,
    required this.date,
    required this.score,
    required this.scoreValue,
    this.subject = 'Khác',
    this.submittedAt,
  });
}
```

And in `fetchStudentData`:
```dart
        final examMap = a['exams'] as Map<String, dynamic>?;
        final title = examMap?['title'] as String? ?? 'Bài kiểm tra';
        final subject = examMap?['subject'] as String? ?? 'Khác';
        final icon = getSubjectIcon(subject);

        String dateStr = 'Mới đây';
        DateTime? submittedAt;
        if (a['submitted_at'] != null) {
          final dt = DateTime.tryParse(a['submitted_at'].toString())?.toLocal();
          if (dt != null) {
            submittedAt = dt;
            dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          }
        }

        final scoreVal = (a['score'] as num).toDouble();

        recentTests.add(
          StudentTestHistoryData(
            id: a['id'].toString(),
            subjectIcon: icon,
            title: title,
            date: dateStr,
            score: '${scoreVal.toStringAsFixed(1)} điểm',
            scoreValue: scoreVal,
            subject: subject,
            submittedAt: submittedAt,
          ),
        );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/student_history_test.dart`  
Expected: PASS (2/2 tests pass).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/profile_service.dart test/models/student_history_test.dart
git commit -m "feat(profile): add subject and submittedAt to StudentTestHistoryData"
```

---

### Task 2: Fix `ProfileScreen` Chi Tiết Redirection & Cap to 10 Recent Tests

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart:1084-1210`
- Test: `test/screens/profile_screen_history_test.dart`

**Interfaces:**
- Consumes: `_studentData.recentTests`
- Produces: Navigation to `/result?attemptId=...` on detail tap, navigation to `/student/history` on all tests tap, cap display to 10 items.

- [ ] **Step 1: Write the failing widget test**

Create `test/screens/profile_screen_history_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/profile/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen shows recent tests card with view-all and detail buttons', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/profile',
            routes: [
              GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
              GoRoute(path: '/student/history', builder: (_, __) => const Scaffold(body: Text('History Screen'))),
              GoRoute(path: '/result', builder: (_, __) => const Scaffold(body: Text('Result Screen'))),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('🕘 Bài thi gần đây'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it executes**

Run: `flutter test test/screens/profile_screen_history_test.dart`

- [ ] **Step 3: Update `ProfileScreen` in `lib/screens/profile/profile_screen.dart`**

Modify `_buildRecentTestsCard`:
1. Limit to 10 tests:
```dart
final displayedTests = _studentData.recentTests.take(10).toList();
```
2. Update item loop:
```dart
for (int i = 0; i < displayedTests.length; i++) ...[
  if (i > 0) const Divider(color: AppTheme.border, height: 24),
  _buildTestHistoryRow(
    testId: displayedTests[i].id,
    subjectIcon: displayedTests[i].subjectIcon,
    title: displayedTests[i].title,
    date: displayedTests[i].date,
    score: displayedTests[i].score,
    scoreStatus: displayedTests[i].scoreValue >= 8.0
        ? _ScoreStatus.high
        : (displayedTests[i].scoreValue >= 5.0 ? _ScoreStatus.medium : _ScoreStatus.low),
  ),
],
```
3. Wire "Xem tất cả lịch sử":
```dart
TextButton.icon(
  onPressed: () => context.go('/student/history'),
  icon: const Text(
    'Xem tất cả lịch sử',
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
  ),
  label: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primary),
),
```
4. Wire "Chi tiết" in `_buildTestHistoryRow`:
Add `required String testId` parameter:
```dart
InkWell(
  key: Key('profile-test-detail-$testId'),
  onTap: () => context.go('/result?attemptId=${Uri.encodeComponent(testId)}'),
  borderRadius: BorderRadius.circular(8),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: const [
        Text(
          'Chi tiết',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textSecondary),
      ],
    ),
  ),
),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/profile_screen_history_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/profile/profile_screen.dart test/screens/profile_screen_history_test.dart
git commit -m "fix(profile): redirect detail button to result and cap recent tests to 10"
```

---

### Task 3: Implement Dedicated `StudentHistoryScreen` & Routing in `main.dart`

**Files:**
- Modify: `lib/main.dart:320`
- Modify: `lib/screens/student/student_history_screen.dart`
- Test: `test/screens/student_history_screen_test.dart`

**Interfaces:**
- Consumes: `ProfileService.fetchStudentData`, `GooglePaginationBar`
- Produces: Complete Exam History page with 20 items/page, `GooglePaginationBar`, SearchBox, multi-filters (Subject, Date, Score, Sort).

- [ ] **Step 1: Write widget test for `StudentHistoryScreen`**

Create `test/screens/student_history_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/student/student_history_screen.dart';
import 'package:onthi_community/shared/widgets/google_pagination_bar.dart';

void main() {
  testWidgets('StudentHistoryScreen renders search bar, filters and pagination', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/student/history',
            routes: [
              GoRoute(path: '/student/history', builder: (_, __) => const StudentHistoryScreen()),
              GoRoute(path: '/profile', builder: (_, __) => const Scaffold(body: Text('Profile'))),
              GoRoute(path: '/result', builder: (_, __) => const Scaffold(body: Text('Result'))),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and search
    expect(find.text('📊 Lịch Sử Làm Bài Thi'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify filter elements
    expect(find.text('Môn thi'), findsOneWidget);
    expect(find.text('Thời gian nộp'), findsOneWidget);
    expect(find.text('Điểm số'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it executes / fails**

Run: `flutter test test/screens/student_history_screen_test.dart`

- [ ] **Step 3: Update `main.dart` routing**

In `lib/main.dart`, import `screens/student/student_history_screen.dart` and add route inside `ShellRoute`:
```dart
GoRoute(
  path: '/student/history',
  pageBuilder: (context, state) => buildPageWithSlideTransition(
    context: context,
    state: state,
    child: const StudentHistoryScreen(),
  ),
),
```

- [ ] **Step 4: Implement `StudentHistoryScreen` in `lib/screens/student/student_history_screen.dart`**

Features:
- `_searchController` for search query with immediate filtering.
- `_selectedSubject`: `'Tất cả'` or specific subject.
- `_dateFilter`: `'all'`, `'today'`, `'7days'`, `'30days'`, or custom date range.
- `_scoreFilter`: `'all'`, `'high'` ($\ge 8.0$), `'medium'` ($5.0 - 7.9$), `'low'` ($< 5.0$).
- `_sort`: `'newest'`, `'oldest'`, `'highest'`, `'lowest'`.
- `_pageSize = 20`.
- `_currentPage`: clamp 1 to totalPages.
- `GooglePaginationBar(currentPage: _currentPage, totalPages: totalPages, onPageChanged: (page) => ... animateTo(0))`.
- Each attempt card:
  - Subject emoji & tag
  - Date & formatted time
  - Exam Title
  - Score badge
  - "Xem kết quả" button -> `context.go('/result?attemptId=${Uri.encodeComponent(test.id)}')`.
  - Tap card -> `context.go('/result?attemptId=${Uri.encodeComponent(test.id)}')`.

- [ ] **Step 5: Run tests to verify all pass**

Run: `flutter test test/screens/student_history_screen_test.dart`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/screens/student/student_history_screen.dart test/screens/student_history_screen_test.dart
git commit -m "feat(student): implement full-featured StudentHistoryScreen with pagination and filters"
```

---

### Task 4: Full Verification & Auto-Push

**Files:**
- All modified and test files

- [ ] **Step 1: Run complete test suite**

Run: `flutter test`  
Expected: All tests pass without errors.

- [ ] **Step 2: Git push to origin main**

Run: `git push origin main`  
Expected: Successfully pushed to trigger GitHub Actions.
