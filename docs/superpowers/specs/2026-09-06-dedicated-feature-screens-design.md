# Dedicated Role Feature Screens Design Specification

## Overview
Create 6 dedicated feature screens in `thi_nhanh` powered by real Supabase database data (no mock data). These screens remove duplication from `/profile` and provide focused interfaces for both Student and Teacher roles when launched from `HomeScreen` feature cards.

---

## 1. Student Feature Screens (`lib/screens/student/`)

### A. Lịch sử & Kết quả (`StudentHistoryScreen` -> `/student/history`)
- **Data source**: Real Supabase `attempts` joined with `exams` table.
- **Features**:
  - Full searchable & filterable table/list of completed test attempts.
  - Metrics: Total attempts count, average score, highest score.
  - Action buttons: "Xem lại đáp án" (routes to `/result` with attempt details).

### B. Thành tích cá nhân (`StudentAchievementsScreen` -> `/student/achievements`)
- **Data source**: Computed real-time from Supabase `attempts` history (streak days, 10/10 scores, rapid completions, top scores).
- **Features**:
  - Badge cards grid (🔥 Streak Master, 🎯 Perfect Score, ⚡ Speed Racer, 🏆 Top Performer).
  - Unlocked / Locked status with progress bars based on actual user data.

### C. Bảng xếp hạng (`StudentLeaderboardScreen` -> `/student/leaderboard`)
- **Data source**: Real Supabase `attempts` aggregated across users, ranked by top score & average score.
- **Features**:
  - Podium display for Top 1, Top 2, Top 3 students.
  - Ranked leaderboard list with avatar, name, exam count, and top score.
  - Highlighted card showing current user's actual rank.

---

## 2. Teacher Feature Screens (`lib/screens/teacher/`)

### A. Quản lý đề thi (`TeacherExamsScreen` -> `/teacher/exams`)
- **Data source**: Real Supabase `exams` table filtered by `created_by` or teacher ID.
- **Features**:
  - List of created exam sets with subject tags, question count, creation date.
  - Search bar to filter exams by title/subject.
  - Action buttons: "Tạo đề thi mới" (`/create_exam`), "Chỉnh sửa", "Sao chép mã đề".

### B. Kết quả học sinh (`TeacherStudentResultsScreen` -> `/teacher/student_results`)
- **Data source**: Real Supabase `attempts` joined with `rooms` and `exams` for teacher's created rooms.
- **Features**:
  - Student submissions table (Student Name, Room Code, Exam Title, Score, Status, Submission Date).
  - Filter by room or exam.
  - Overview cards: Total submissions, Average class score, Pass rate.

### C. Thống kê giảng dạy (`TeacherAnalyticsScreen` -> `/teacher/analytics`)
- **Data source**: Real Supabase `attempts`, `rooms`, and `exams` aggregated for the teacher.
- **Features**:
  - Performance analytics dashboard with grade distribution chart.
  - Room participation metrics (busiest room, total student participants).
  - Question accuracy insights (most difficult questions, completion speed).

---

## 3. Router & Navigation Updates
- Add new routes in `main.dart` GoRouter configuration:
  - `/student/history`
  - `/student/achievements`
  - `/student/leaderboard`
  - `/teacher/exams`
  - `/teacher/student_results`
  - `/teacher/analytics`
- Update `HomeScreen` feature cards to navigate directly to these routes.
