# Real Exams Data Integration & Mock Removal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect the 24 real Supabase exams across 8 subjects to the application, eliminating mock placeholders in Search, Exam Detail, and Teacher Exams screens with robust network error handling.

**Architecture:** Flutter Web with GoRouter and Supabase client. Components consume `exams` rows with `snapshot_payload` and `teachers(display_name)` directly. Navigation transitions seamlessly from search to exam detail to taking exam using dynamic `examId`.

**Tech Stack:** Flutter / Dart, GoRouter, Supabase Flutter, Provider.

## Global Constraints
- Every screen must query real data from Supabase and use `snapshot_payload` for instant loading without referencing nonexistent columns like `total_questions`.
- Network errors must trigger a clear user-friendly Dialog or SnackBar with a "Thử lại" action.
- When Supabase is not connected (e.g. unit test runner without credentials), screens must handle the exception gracefully and maintain test compatibility.
- All 28+ tests in `flutter test` must remain passing.

---

### Task 1: Search Screen Real Data Integration & 8-Subject Filters

**Files:**
- Modify: `lib/screens/home/search_screen.dart`
- Test: `test/screens/search_screen_test.dart`

**Interfaces:**
- Produces: `_SearchItem(id, code, title, teacher, subject, type, questions, duration, activity)`
- Route: Navigates to `/exam_detail?examId={id}` on click.

- [ ] **Step 1: Write widget test for SearchScreen real items rendering and 8 subjects**
Create `test/screens/search_screen_test.dart` verifying search box, subject filter chips, and empty state.

- [ ] **Step 2: Update SearchScreen implementation**
- Add `id` and `code` fields to `_SearchItem`.
- Query `exams` with `select('id, code, title, subject, duration_minutes, created_at, snapshot_payload, teachers(display_name)')`.
- Replace subject list with 8 real subjects: `['Toán học', 'Vật lý', 'Hóa học', 'Sinh học', 'Tiếng Anh', 'Lịch sử', 'Địa lý', 'Tin học']`.
- Update click action from hardcoded `/exam/physics-12` to `context.go('/exam_detail?examId=${item.id}')`.
- Add network error popup dialog with "Thử lại" retry callback.

- [ ] **Step 3: Run search screen test**
Run: `flutter test test/screens/search_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Commit Task 1**
```bash
git add lib/screens/home/search_screen.dart test/screens/search_screen_test.dart
git commit -m "feat(search): connect real exams and 8 subject filters with dynamic navigation"
```

---

### Task 2: Dynamic Exam Detail Screen & GoRouter Registration

**Files:**
- Modify: `lib/screens/exam/exam_detail_screen.dart`
- Modify: `lib/main.dart`
- Test: `test/screens/exam_detail_screen_test.dart`

**Interfaces:**
- Consumes: `/exam_detail?examId={id}` query parameter
- Produces: Navigation to `/taking_exam?examId={id}`

- [ ] **Step 1: Update GoRouter in `lib/main.dart`**
Add route `/exam_detail` taking `state.uri.queryParameters['examId']`:
```dart
GoRoute(
  path: '/exam_detail',
  pageBuilder: (context, state) => buildPageWithSlideTransition(
    context: context,
    state: state,
    child: ExamDetailScreen(examId: state.uri.queryParameters['examId']),
  ),
),
```

- [ ] **Step 2: Update ExamDetailScreen**
- Accept `final String? examId;` in constructor.
- Query Supabase for the specific `examId` if passed, or default to the newest published exam.
- Parse `snapshot_payload` for question count and metadata.
- Connect "Bắt đầu làm bài" to navigate to `/taking_exam?examId=${_examData?['id']}`.
- Add network error dialog with "Thử lại" button.

- [ ] **Step 3: Write and run ExamDetailScreen test**
Create `test/screens/exam_detail_screen_test.dart` verifying dynamic exam rendering.
Run: `flutter test test/screens/exam_detail_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Commit Task 2**
```bash
git add lib/screens/exam/exam_detail_screen.dart lib/main.dart test/screens/exam_detail_screen_test.dart
git commit -m "feat(exam): support dynamic examId in ExamDetailScreen and register route"
```

---

### Task 3: Fix Teacher Exams Screen & Eliminate SQL Column Errors

**Files:**
- Modify: `lib/screens/teacher/teacher_exams_screen.dart`
- Test: `test/screens/teacher_exams_screen_test.dart`

- [ ] **Step 1: Fix query in `lib/screens/teacher/teacher_exams_screen.dart`**
- Replace `select('id, title, subject, total_questions, created_at, code')` with `select('id, title, subject, duration_minutes, created_at, code, snapshot_payload')`.
- Derive question count using `(e['snapshot_payload']?['total_questions'] as num?)?.toInt() ?? 10`.
- Wire card click to `/exam_detail?examId=${e['id']}`.
- Add network error dialog if connection fails.

- [ ] **Step 2: Run teacher exams test**
Run: `flutter test test/screens/teacher_exams_screen_test.dart`
Expected: PASS

- [ ] **Step 3: Commit Task 3**
```bash
git add lib/screens/teacher/teacher_exams_screen.dart
git commit -m "fix(teacher): correct exams query columns and support snapshot payload"
```

---

### Task 4: Comprehensive Verification, Evidence & Remote Push

- [ ] **Step 1: Run complete flutter test suite**
Run: `flutter test`
Expected: 30+ tests passing.

- [ ] **Step 2: Push changes to remote repository**
Push both submodule and parent repository to GitHub.
