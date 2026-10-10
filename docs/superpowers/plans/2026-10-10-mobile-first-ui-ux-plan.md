# Mobile-First UI/UX Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Thi Nhanh web application into a premier mobile-first experience with a dedicated 5-icon Bottom Navigation Bar, compact header with exit/back button on sub-screens, thumb-zone optimized exam taking screen, and responsive layouts across all core pages.

**Architecture:** Implement a responsive navigation shell where desktop (`width >= 600px`) keeps the full `TopNavBar`, while mobile (`width < 600px`) displays `MobileBottomNavBar` (5 icon tabs) strictly on the 5 core tabs (`/home`, `/search`, `/teacher_exams`, `/create_room`, `/student/history`). On sub-screens, the bottom bar hides and a top-left back/exit button appears. Redesign `TakingExamScreen`, `SearchScreen`, `ExamDetailScreen`, and `HomeScreen` with touch-friendly controls, horizontal quick-strips, and zero overflow on narrow 360px viewports.

**Tech Stack:** Flutter 3.x, GoRouter, Provider, Custom Responsive LayoutBuilder, Material 3, AppTheme Tokens.

## Global Constraints
- Clean responsive breakpoints: Mobile (`width < 600px`), Tablet/Compact (`600px <= width < 1100px`), Desktop (`width >= 1100px`).
- Mobile 5 core tabs use pure icons: Home (`/home`), Search (`/search`), My Exams (`/teacher_exams`), Create Room (`/create_room`), History (`/student/history`).
- Strict visibility: Bottom bar only appears when in the 5 core tabs. Any other route hides the bottom bar and shows an exit/back arrow in the top header.
- Zero `RenderFlex overflowed` errors on 360px mobile viewport width.
- 100% test pass rate across all new and existing tests.
- Auto-push to GitHub remote on both `thi_nhanh` and root `CODE` repositories upon completion.

---

## Tasks

### Task 1: Mobile Navigation Shell (`MobileBottomNavBar` & `TopNavBar` Refactor)

**Files:**
- Create: `lib/shared/widgets/mobile_bottom_nav_bar.dart`
- Modify: `lib/shared/widgets/top_nav_bar.dart`
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/screens/home/search_screen.dart`
- Modify: `lib/screens/teacher/teacher_exams_screen.dart`
- Modify: `lib/screens/teacher/create_room_screen.dart`
- Modify: `lib/screens/student/student_history_screen.dart`
- Test: `test/widgets/mobile_bottom_nav_bar_test.dart`
- Modify Test: `test/widgets/top_nav_bar_test.dart`

- [x] **Step 1: Write failing widget test for `MobileBottomNavBar`**
  - Create `test/widgets/mobile_bottom_nav_bar_test.dart` testing:
    - 5 icon tabs render correctly: Home, Search, Book, Add Room, History.
    - Active tab highlights with Stitch purple color `#6557E8` and purple capsule background.
    - Tapping an icon triggers navigation to the respective route (`/home`, `/search`, `/teacher_exams`, `/create_room`, `/student/history`).
  - Run `flutter test test/widgets/mobile_bottom_nav_bar_test.dart` and verify it fails (file not created yet).

- [x] **Step 2: Implement `MobileBottomNavBar`**
  - Create `lib/shared/widgets/mobile_bottom_nav_bar.dart`:
    - Pure icon buttons with custom tooltips/accessibility semantics.
    - Styled with `AppTheme.surface`, top border, subtle shadow, and safe area padding.
    - Active state: `#6557E8` icon in `#F4F3FE` rounded capsule.
    - Inactive state: `#9CA3AF` icon with smooth transition.

- [x] **Step 3: Update `TopNavBar` for Mobile Viewport**
  - In `lib/shared/widgets/top_nav_bar.dart`:
    - On mobile (`width < 600px`):
      - If on 5 core tabs: Show compact logo + app name, quick PIN action button (opens join room dialog), and user avatar menu. Hide horizontal text navigation menu.
      - If on sub-screens outside 5 core tabs: Show round back/exit button (`Icons.arrow_back_rounded`) on the left, centered title, and optional actions on the right.
    - On desktop (`width >= 600px`): Preserve existing full desktop navigation bar.

- [x] **Step 4: Integrate `MobileBottomNavBar` into 5 Core Screens**
  - In `HomeScreen`, `SearchScreen`, `TeacherExamsScreen`, `CreateRoomScreen`, `StudentHistoryScreen`:
    - Add `bottomNavigationBar: LayoutBuilder(builder: (ctx, constraints) => MediaQuery.of(ctx).size.width < 600 ? const MobileBottomNavBar() : const SizedBox.shrink())` (or equivalent responsive helper).

- [x] **Step 5: Run tests and verify**
  - Run `flutter test test/widgets/mobile_bottom_nav_bar_test.dart test/widgets/top_nav_bar_test.dart`.
  - Commit Task 1 changes.

---

### Task 2: TakingExamScreen Mobile Optimization (`TakingExamScreen`)

**Files:**
- Modify: `lib/screens/exam/taking_exam_screen.dart`
- Test: `test/screens/taking_exam_mobile_layout_test.dart`

- [x] **Step 1: Write failing widget test for `TakingExamScreen` mobile layout**
  - Create `test/screens/taking_exam_mobile_layout_test.dart` on viewport size `360x800`:
    - Tests that top header shows exit button, title, and Fira Code timer countdown.
    - Tests that horizontal Quick-Strip questions bar (1..N) renders and is scrollable.
    - Tests that tapping the grid icon opens a Modal Bottom Sheet showing all questions in a matrix.
    - Tests that bottom action bar (Câu trước, Cờ, Câu sau / Nộp bài) is fixed at the bottom with touch-friendly buttons.
    - Tests that radio options A, B, C, D render as spacious cards with min-height >= 52px.
  - Run test and verify failure or missing mobile elements.

- [x] **Step 2: Implement Mobile Layout & Quick-Strip in `TakingExamScreen`**
  - In `lib/screens/exam/taking_exam_screen.dart`:
    - Detect `isMobile = MediaQuery.of(context).size.width < 600`.
    - Mobile Header: Back button on top-left (with `_onWillPop` confirmation dialog), truncated title, and timer pill.
    - Mobile Question Quick-Strip: Horizontal list with status indicator colors:
      - Neutral grey: Unanswered.
      - Purple / Green: Answered.
      - Purple border: Current question.
      - Amber flag badge: Flagged.
    - Add `_showQuestionGridBottomSheet()`: Opens a clean modal sheet showing all questions in a 5-column grid.
    - Bottom Action Bar: Fixed bottom container with `SafeArea`, thumb-friendly buttons for "Câu trước", "Cờ", "Câu sau" / "Nộp bài".
    - Option cards: Touch-friendly vertical stack with 52px+ height, active glowing border.

- [x] **Step 3: Run tests and verify**
  - Run `flutter test test/screens/taking_exam_mobile_layout_test.dart test/screens/taking_exam_expired_guard_test.dart test/screens/taking_exam_anti_cheat_test.dart test/screens/taking_exam_spam_submission_test.dart`.
  - Commit Task 2 changes.

---

### Task 3: SearchScreen & HomeScreen Mobile Polish

**Files:**
- Modify: `lib/screens/home/search_screen.dart`
- Modify: `lib/screens/home/home_screen.dart`
- Test: `test/screens/search_screen_mobile_test.dart`
- Test: `test/screens/home_mobile_layout_test.dart`

- [x] **Step 1: Write failing tests for mobile search & home layout**
  - Create `test/screens/search_screen_mobile_test.dart`:
    - Test 8 GDPT horizontal subject chips bar under search bar.
    - Test filter button toggling collapsible filter panel / bottom sheet.
    - Test exam cards rendering with touch-friendly 1-column layout and "Vào thi" & "Lưu đề" buttons.
  - Create `test/screens/home_mobile_layout_test.dart`:
    - Test responsive hero banner, workspace mode toggle, vertical active attempt cards on 360px viewport.
  - Run tests and verify expectations.

- [x] **Step 2: Implement Mobile Enhancements in `SearchScreen`**
  - In `lib/screens/home/search_screen.dart`:
    - On mobile, display horizontal scrollable subject chips bar directly below the search bar.
    - Add compact filter icon button next to search input that expands/collapses the advanced filter options (grades, sort, duration).
    - Refactor exam card layout on mobile: Title with 2-line ellipsis, tags row, and 2 full-width or split action buttons ("Vào thi" and "Lưu đề") with no overflow.

- [x] **Step 3: Polish `HomeScreen` for Mobile Viewport**
  - In `lib/screens/home/home_screen.dart`:
    - Optimize hero banner padding and typography for mobile.
    - Ensure quick room PIN code field is compact and easy to tap.
    - Verify vertical stacking of "Bài Đang Làm" and "Phòng Đang Diễn Ra" cards has zero flex overflow on 360px.
    - Render gamified cards in a clean 2-column or 1-column responsive grid on mobile.

- [x] **Step 4: Run tests and verify**
  - Run `flutter test test/screens/search_screen_mobile_test.dart test/screens/home_mobile_layout_test.dart test/screens/home_smart_navigation_test.dart test/screens/search_screen_subject_filter_test.dart`.
  - Commit Task 3 changes.

---

### Task 4: ExamDetailScreen & Management Screens Mobile Polish

**Files:**
- Modify: `lib/screens/exam/exam_detail_screen.dart`
- Modify: `lib/screens/teacher/create_room_screen.dart`
- Modify: `lib/screens/teacher/teacher_exams_screen.dart`
- Test: `test/screens/exam_detail_mobile_test.dart`

- [x] **Step 1: Write failing test for `ExamDetailScreen` mobile layout**
  - Create `test/screens/exam_detail_mobile_test.dart`:
    - Test on 360x800: Top-left back button, exam header summary, prominent "Bắt đầu làm bài" and "Lưu đề" buttons, preview questions list without 300px fixed sidebar overflow.
  - Run test and verify.

- [x] **Step 2: Optimize `ExamDetailScreen` for Mobile**
  - In `lib/screens/exam/exam_detail_screen.dart`:
    - On mobile (`width < 600px`):
      - Remove fixed 300px sidebar from horizontal row layout.
      - Add Quick-Jump question numbers bar or modal sheet trigger.
      - Stack action buttons ("Bắt đầu làm bài" & "Lưu đề") with large tap targets.
      - Ensure question body, math formulas, and explanation text wrap properly without horizontal viewport overflow.

- [x] **Step 3: Polish `CreateRoomScreen` & `TeacherExamsScreen` for Mobile**
  - In `lib/screens/teacher/create_room_screen.dart`:
    - Responsive card layout for exam selection (my exams vs saved exams), full-width inputs and switches.
  - In `lib/screens/teacher/teacher_exams_screen.dart`:
    - 3-tab filter selector with `Flexible` text, touch-friendly exam cards and action icons (Edit, Room, Delete, Preview).

- [x] **Step 4: Run tests and verify**
  - Run `flutter test test/screens/exam_detail_mobile_test.dart test/screens/exam_detail_preview_test.dart test/screens/create_room_with_saved_exam_test.dart`.
  - Commit Task 4 changes.

---

### Task 5: Full Verification, Documentation & Auto-Push

**Files:**
- Modify: `docs/system_architecture_and_deep_evaluation.md`
- Sync: Artifact `system_architecture_and_deep_evaluation.md`

- [x] **Step 1: Run complete test suite**
  - Run `flutter test` across all files to confirm 100% PASS with zero failures or regressions.

- [x] **Step 2: Update System Architecture Documentation**
  - Document Stage 9: Full Mobile-First UI/UX Overhaul in `docs/system_architecture_and_deep_evaluation.md` and sync with IDE artifact.

- [x] **Step 3: Auto-Commit and Auto-Push to GitHub**
  - Commit all changes in `thi_nhanh` and push to `origin/main`.
  - Update submodule in root `CODE` repo and push to `origin/main`.

