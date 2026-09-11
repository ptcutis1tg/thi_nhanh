# Live Exam Rooms End-to-End Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete E2E Live Exam Room lifecycle for Thi Nhanh, from room creation, PIN-based student joining with guest/auth support, Supabase Realtime synchronization, live taking exam routing, to live leaderboard tracking.

**Architecture:** 
- Supabase Postgres RPCs (Security Definer) handle participant admissions, state transitions, scoring, and leaderboard queries.
- Flutter `RoomRepository` orchestrates both Supabase Realtime event listeners and fallback timers (3s interval).
- UI screens (`HomeScreen`, `StudentWaitingRoomScreen`, `TeacherWaitingRoomScreen`, `TakingExamScreen`, `LiveLeaderboardDialog`) bind reactively to the room state stream.

**Tech Stack:** Flutter / Dart, Supabase Flutter SDK, GoRouter, Provider.

## Global Constraints
- All database mutations must use Security Definer RPCs to protect answer keys and credentials.
- All Flutter screens must maintain responsive layout and clean Material 3 design system tokens (`AppTheme`).
- Support both authenticated users and anonymous guests with display names.
- Auto-push commits to remote repository via git commit/push per workspace rules.

---

### Task 1: Supabase Migrations & RPCs for Live Rooms E2E

**Files:**
- Create: `supabase/migrations/202609030001_live_rooms_e2e.sql`
- Test: Manual / local DB migration script check

**Interfaces:**
- Consumes: `public.rooms`, `public.room_participants`, `public.attempts`, `public.profiles`
- Produces: `public.join_student_room`, `public.get_student_room_state`, `public.submit_room_attempt`, `public.get_room_leaderboard`

- [ ] **Step 1: Write the Supabase SQL migration for Live Rooms RPCs**
- [ ] **Step 2: Verify SQL syntax and function security definitions**
- [ ] **Step 3: Commit migration file**

```bash
git add supabase/migrations/202609030001_live_rooms_e2e.sql
git commit -m "feat(db): add RPCs for student join, room state, submit attempt, and leaderboard"
```

---

### Task 2: Update Room Models and RoomRepository

**Files:**
- Modify: `lib/core/repositories/room_repository.dart`
- Test: `test/repositories/room_repository_test.dart`

**Interfaces:**
- Consumes: Supabase Client & RPC responses
- Produces: `RoomParticipant`, `StudentRoomState`, `RoomLeaderboardEntry`, `RoomRepository.joinRoom`, `RoomRepository.getStudentRoomState`, `RoomRepository.getRoomLeaderboard`, `RoomRepository.submitRoomAttempt`

- [ ] **Step 1: Write failing unit test for `RoomRepository` student flow and leaderboard in `test/repositories/room_repository_test.dart`**
- [ ] **Step 2: Run `flutter test test/repositories/room_repository_test.dart` to verify failure**
- [ ] **Step 3: Implement data models (`StudentRoomState`, `RoomLeaderboardEntry`) and methods in `lib/core/repositories/room_repository.dart`**
- [ ] **Step 4: Re-run `flutter test test/repositories/room_repository_test.dart` to verify pass**
- [ ] **Step 5: Commit changes**

```bash
git add lib/core/repositories/room_repository.dart test/repositories/room_repository_test.dart
git commit -m "feat(repo): add student room state, join flow, and leaderboard methods to RoomRepository"
```

---

### Task 3: Enhance HomeScreen PIN Join & Guest Name Modal

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Create: `lib/screens/room/widgets/join_room_guest_dialog.dart`
- Test: `test/screens/home_screen_join_test.dart`

**Interfaces:**
- Consumes: `RoomRepository.joinRoom`, `AuthProvider.isAuthenticated`, `AuthProvider.userName`
- Produces: Navigation to `/student_waiting_room?roomId=...&participantId=...`

- [ ] **Step 1: Write widget test verifying PIN code parsing and Guest dialog trigger**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Build `join_room_guest_dialog.dart` and integrate with `HomeScreen` PIN input**
- [ ] **Step 4: Run test to verify pass**
- [ ] **Step 5: Commit changes**

```bash
git add lib/screens/home/home_screen.dart lib/screens/room/widgets/join_room_guest_dialog.dart test/screens/home_screen_join_test.dart
git commit -m "feat(room): add PIN join flow with guest name modal and error feedback"
```

---

### Task 4: Dynamic Student Waiting Room & Realtime Auto-Start Transition

**Files:**
- Modify: `lib/screens/room/student_waiting_room_screen.dart`
- Modify: `lib/main.dart` (ensure router passes `roomId` and `participantId` query params)
- Test: `test/screens/student_waiting_room_screen_test.dart`

**Interfaces:**
- Consumes: `RoomRepository.getStudentRoomState`, `RoomRepository.dashboard`
- Produces: Reactive UI listening to room status; navigates to `/taking_exam` when room is live.

- [ ] **Step 1: Write widget test for `StudentWaitingRoomScreen` reactive state updates**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement dynamic state binding, avatar list, and polling/realtime auto-start listener**
- [ ] **Step 4: Run test to verify pass**
- [ ] **Step 5: Commit changes**

```bash
git add lib/screens/room/student_waiting_room_screen.dart lib/main.dart test/screens/student_waiting_room_screen_test.dart
git commit -m "feat(room): make student waiting room dynamic with realtime auto-start transition"
```

---

### Task 5: Live Leaderboard View for Teacher and Student

**Files:**
- Create: `lib/screens/room/widgets/live_leaderboard_view.dart`
- Modify: `lib/screens/room/teacher_waiting_room_screen.dart`
- Modify: `lib/screens/exam/taking_exam_screen.dart` (trigger leaderboard upon exam submission)
- Test: `test/screens/live_leaderboard_test.dart`

**Interfaces:**
- Consumes: `RoomRepository.getRoomLeaderboard`
- Produces: Reusable `LiveLeaderboardView` with podium medals, live scores, and completion metrics.

- [ ] **Step 1: Write widget test for `LiveLeaderboardView`**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Build `LiveLeaderboardView` and embed in Teacher monitoring & Student post-exam modal**
- [ ] **Step 4: Run test to verify pass**
- [ ] **Step 5: Commit changes**

```bash
git add lib/screens/room/widgets/live_leaderboard_view.dart lib/screens/room/teacher_waiting_room_screen.dart lib/screens/exam/taking_exam_screen.dart test/screens/live_leaderboard_test.dart
git commit -m "feat(room): add realtime live leaderboard view for proctors and participants"
```

---

### Task 6: End-to-End Verification & Automated Testing Suite

**Files:**
- Test: Run all flutter tests (`flutter test`)
- Verify Web build (`flutter build web`)

- [ ] **Step 1: Run full test suite `flutter test`**
- [ ] **Step 2: Verify zero compiler or analyzer warnings (`flutter analyze`)**
- [ ] **Step 3: Push all commits to remote repo (GitHub Actions auto-deploy)**

```bash
git push origin main
```
