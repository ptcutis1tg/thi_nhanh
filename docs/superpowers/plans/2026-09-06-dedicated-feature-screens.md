# Dedicated Role Feature Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create 6 dedicated feature screens for Student and Teacher roles using real Supabase database data, and update `HomeScreen` routes to navigate to them cleanly.

**Architecture:** Create dedicated screen widgets in `lib/screens/student/` and `lib/screens/teacher/`. Query real data from Supabase tables (`attempts`, `exams`, `rooms`, `teachers`) via `ProfileService` or Supabase client queries. Register routes in `main.dart` and update `HomeScreen` card tap handlers.

**Tech Stack:** Flutter / Dart, Supabase (`supabase_flutter`), Provider (`AuthProvider`), `GoRouter`.

## Global Constraints
- Real data only from Supabase queries (`attempts`, `exams`, `rooms`). If client/DB is empty, show clean real zero-state UI.
- Student routes: `/student/history`, `/student/achievements`, `/student/leaderboard`.
- Teacher routes: `/teacher/exams`, `/teacher/student_results`, `/teacher/analytics`.

---

### Task 1: Create Student Dedicated Screens (`lib/screens/student/`)

**Files:**
- Create: `d:\thi_nhanh\lib\screens\student\student_history_screen.dart`
- Create: `d:\thi_nhanh\lib\screens\student\student_achievements_screen.dart`
- Create: `d:\thi_nhanh\lib\screens\student\student_leaderboard_screen.dart`

**Interfaces:**
- Consumes: `AuthProvider`, `ProfileService.fetchStudentData()`, Supabase `attempts` table
- Produces: 3 student feature screens displaying real user exam history, achievement badges, and global leaderboards.

- [ ] **Step 1: Create `StudentHistoryScreen`**
  - Fetch real attempts from Supabase `attempts` table.
  - Display test title, subject icon, score, status, and submission date.

- [ ] **Step 2: Create `StudentAchievementsScreen`**
  - Compute real achievements from user's actual attempts data.
  - Display unlocked/locked badges with progress metrics.

- [ ] **Step 3: Create `StudentLeaderboardScreen`**
  - Query real student scores from Supabase `attempts`.
  - Display Top 3 podium, user rank card, and rankings table.

- [ ] **Step 4: Commit changes**
  `git commit -m "feat: add dedicated Student feature screens powered by real Supabase data"`

---

### Task 2: Create Teacher Dedicated Screens (`lib/screens/teacher/`)

**Files:**
- Create: `d:\thi_nhanh\lib\screens\teacher\teacher_exams_screen.dart`
- Create: `d:\thi_nhanh\lib\screens\teacher\teacher_student_results_screen.dart`
- Create: `d:\thi_nhanh\lib\screens\teacher\teacher_analytics_screen.dart`

**Interfaces:**
- Consumes: `AuthProvider`, `ProfileService.fetchTeacherData()`, Supabase `exams`, `rooms`, `attempts` tables
- Produces: 3 teacher feature screens for managing created exams, reviewing student test submissions, and analyzing teaching statistics.

- [ ] **Step 1: Create `TeacherExamsScreen`**
  - Query teacher's created exams from Supabase `exams` table.
  - Show exam title, subject, question count, creation date, and management actions.

- [ ] **Step 2: Create `TeacherStudentResultsScreen`**
  - Query student attempts from teacher's rooms via Supabase `attempts`.
  - Display student name, score, room code, and submission details.

- [ ] **Step 3: Create `TeacherAnalyticsScreen`**
  - Compute score distribution and room metrics from real teacher data.
  - Display score charts, completion rates, and question accuracy statistics.

- [ ] **Step 4: Commit changes**
  `git commit -m "feat: add dedicated Teacher feature screens powered by real Supabase data"`

---

### Task 3: Register Routes in `main.dart` & Update `HomeScreen` Card Routes

**Files:**
- Modify: `d:\thi_nhanh\lib\main.dart`
- Modify: `d:\thi_nhanh\lib\screens\home\home_screen.dart`

**Interfaces:**
- Consumes: Newly created screen widgets
- Produces: GoRouter routes `/student/history`, `/student/achievements`, `/student/leaderboard`, `/teacher/exams`, `/teacher/student_results`, `/teacher/analytics` and updated card onTap handlers in `HomeScreen`.

- [ ] **Step 1: Register 6 new routes in `main.dart` ShellRoute**
- [ ] **Step 2: Update `HomeScreen` grid card routes to navigate directly to dedicated screens**
- [ ] **Step 3: Verify build and routing functionality**
- [ ] **Step 4: Commit changes**
  `git commit -m "feat: register routes and connect HomeScreen cards to dedicated screens"`
