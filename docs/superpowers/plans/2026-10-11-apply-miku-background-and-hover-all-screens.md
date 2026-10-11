# Comprehensive Rollout of Miku Cloud Texture & Interactive Hover Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the Hatsune Miku dreamy cloud background (`miku_cloud_bg.png` / `MilkyMintScaffold`) and the interactive 3D highlight/hover effect (`AppInteractiveHoverCard` with desktop `-3px` lift, expanded cyan luminescence glow shadow, and zero-overhead static touch behavior on mobile) consistently across **all screens** in the Thi Nhanh application.

**Architecture:**
- Nested Primary Tabs (`HomeScreen`, `SearchScreen`, `TeacherExamsScreen`, `CreateRoomScreen`, `StudentHistoryScreen`, `ProfileScreen`) sit inside `MainLayoutScreen`'s root `MilkyMintScaffold`. Their scaffold backgrounds are set to `Colors.transparent` to reveal the dreamy cloud mesh without redundant layers.
- Standalone Screens (`JoinRoomScreen`, `ExamDetailScreen`, `ResultScreen`, `StudentLeaderboardScreen`, `StudentAchievementsScreen`, `TeacherRoomsHistoryScreen`, `TeacherAnalyticsScreen`, `QuestionReportsScreen`, `TeacherStudentResultsScreen`, `TakingExamScreen`, `LiveDashboardScreen`, `WrongQuestionsPracticeScreen`, `StudentWaitingRoomScreen`, `TeacherWaitingRoomScreen`) wrap their viewports in `MilkyMintScaffold`.
- Interactive Cards, List Items, Stat Metrics, and Detail Panels are wrapped with `AppInteractiveHoverCard` to provide the unified, enamel glass appearance and buttery smooth PC cursor response.

**Tech Stack:** Flutter 3.x, Dart 3.x, GoRouter, Provider, Supabase Flutter.

## Global Constraints
- Zero `BackdropFilter` real-time GPU blurs to guarantee 60/120 FPS performance even on low-end mobile devices.
- Desktop-only hover elevation (`Matrix4.translationValues(0, -3.0, 0)`) and luminescence glow shadow; mobile touch devices stay static.
- 100% test pass rate across the full test suite.
- Auto-commit and git push upon completion of tasks, and update system architecture evaluation documentation.

---

### Task 1: SearchScreen & CreateRoomScreen Background & Hover Cards

**Files:**
- Modify: `lib/screens/home/search_screen.dart`
- Modify: `lib/screens/room/create_room_screen.dart`
- Test: `test/screens/search_screen_test.dart`, `test/screens/create_room_screen_test.dart`

- [ ] **Step 1: Update SearchScreen cards with AppInteractiveHoverCard**
- [ ] **Step 2: Update CreateRoomScreen scaffold to transparent and wrap main forms & exam picker cards with AppInteractiveHoverCard**
- [ ] **Step 3: Run widget tests for search and create room**

---

### Task 2: Student Screens (History, Leaderboard, Achievements)

**Files:**
- Modify: `lib/screens/student/student_history_screen.dart`
- Modify: `lib/screens/student/student_leaderboard_screen.dart`
- Modify: `lib/screens/student/student_achievements_screen.dart`
- Test: `test/screens/student_history_screen_test.dart`, `test/screens/student_leaderboard_screen_test.dart`

- [ ] **Step 1: Set StudentHistoryScreen scaffold to transparent, wrap metric cards, history cards, and in-progress cards with AppInteractiveHoverCard**
- [ ] **Step 2: Wrap StudentLeaderboardScreen with MilkyMintScaffold and podium/rank cards with AppInteractiveHoverCard**
- [ ] **Step 3: Wrap StudentAchievementsScreen with MilkyMintScaffold and achievement tiles with AppInteractiveHoverCard**
- [ ] **Step 4: Run student screens test suite**

---

### Task 3: Teacher Management Screens (Rooms History, Analytics, Reports, Results)

**Files:**
- Modify: `lib/screens/teacher/teacher_rooms_history_screen.dart`
- Modify: `lib/screens/teacher/teacher_analytics_screen.dart`
- Modify: `lib/screens/teacher/question_reports_screen.dart`
- Modify: `lib/screens/teacher/teacher_student_results_screen.dart`
- Test: `test/screens/teacher_rooms_history_screen_test.dart`, `test/screens/teacher_analytics_screen_test.dart`

- [ ] **Step 1: Wrap TeacherRoomsHistoryScreen with MilkyMintScaffold and room cards with AppInteractiveHoverCard**
- [ ] **Step 2: Wrap TeacherAnalyticsScreen with MilkyMintScaffold and analytics tiles with AppInteractiveHoverCard**
- [ ] **Step 3: Wrap QuestionReportsScreen and TeacherStudentResultsScreen with MilkyMintScaffold and cards with AppInteractiveHoverCard**
- [ ] **Step 4: Run teacher screens test suite**

---

### Task 4: Exam Experience Screens (Detail, Result, Taking, Practice, Waiting Rooms)

**Files:**
- Modify: `lib/screens/exam/exam_detail_screen.dart`
- Modify: `lib/screens/exam/result_screen.dart`
- Modify: `lib/screens/exam/wrong_questions_practice_screen.dart`
- Modify: `lib/screens/room/join_room_screen.dart`
- Modify: `lib/screens/room/student_waiting_room_screen.dart`
- Modify: `lib/screens/room/teacher_waiting_room_screen.dart`
- Test: `test/screens/exam_detail_screen_test.dart`, `test/screens/result_screen_test.dart`

- [ ] **Step 1: Wrap ExamDetailScreen with MilkyMintScaffold, wrap summary, action, and question cards with AppInteractiveHoverCard**
- [ ] **Step 2: Wrap ResultScreen with MilkyMintScaffold and score/stats/review cards with AppInteractiveHoverCard**
- [ ] **Step 3: Wrap JoinRoomScreen, WrongQuestionsPracticeScreen, and WaitingRoom screens with MilkyMintScaffold and hover cards**
- [ ] **Step 4: Run exam flow test suite**

---

### Task 5: ProfileScreen & Verification & Documentation Sync

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `docs/system_architecture_and_deep_evaluation.md`
- Test: Full test suite (`flutter test`)

- [ ] **Step 1: Set ProfileScreen scaffold to transparent and wrap header, stats, recent activities, and teacher exam set cards with AppInteractiveHoverCard**
- [ ] **Step 2: Run full regression test suite `flutter test`**
- [ ] **Step 3: Update `docs/system_architecture_and_deep_evaluation.md` and sync artifact**
- [ ] **Step 4: Execute git commit and git push to both `thi_nhanh` and root `CODE` repositories**
