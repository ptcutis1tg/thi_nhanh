# Live Exam Rooms End-to-End Design Specification

## Overview
This specification details the complete End-to-End (E2E) Live Exam Room architecture for the **Thi Nhanh** platform. It covers teacher room creation, student PIN join with guest/auth support, Supabase Realtime synchronization with fallback polling, automatic exam launch transitions, attempt submission, and real-time live leaderboards.

---

## 1. User Flows & Personas

### 1.1 Teacher Persona
1. **Create Live Room**:
   - Teacher selects a published exam, sets room name, max participants, and optional PIN password.
   - Server RPC `create_teacher_room` returns a unique 6-digit room PIN code (e.g., `PT892341`).
2. **Teacher Waiting Room & Monitoring**:
   - Displays room PIN code, exam rules, and connected participant list in real-time.
   - Teacher clicks **"Bắt đầu thi"** -> calls `start_teacher_room`.
   - The room status changes from `'waiting'` to `'live'`.
   - Realtime channels and monitoring view switch to Live Proctoring & Leaderboard mode.
3. **Live Leaderboard & Submissions**:
   - Monitors student progress: Who is taking the exam, who has submitted, submission timestamps, and live scores.

### 1.2 Student Persona (Authenticated & Guest)
1. **Join by Room Code**:
   - From HomeScreen or Join Room dialog, student enters room PIN (e.g., `PT892341`).
   - If user is not logged in, system prompts for Display Name (Guest name).
   - If room is password-protected, prompts for room password.
   - Calls `join_student_room` RPC.
2. **Student Waiting Room**:
   - Shows exam info, proctor name, and avatar list of peers in the room.
   - Subscribes to Supabase Realtime room channel + 3s fallback polling.
   - When room status becomes `'live'`, the screen immediately transitions into `TakingExamScreen` with the created `attempt_id`.
3. **Taking Exam & Submitting**:
   - Real-time countdown timer bound to room started timestamp + duration.
   - On submit (or timeout), calls `submit_room_attempt` RPC.
   - Shows individual test score breakdown and opens the Live Room Leaderboard.

---

## 2. Database Schema & RPC Functions

### 2.1 Supabase Schema Migration (`202609030001_live_rooms_e2e.sql`)

1. **Table: `public.room_participants`**:
   - `id` (uuid, PK)
   - `room_id` (uuid, FK to rooms)
   - `user_id` (uuid, FK to profiles, nullable for guests)
   - `guest_name` (text, nullable)
   - `guest_access_token_hash` (text, nullable)
   - `status` (text: 'waiting', 'approved', 'in_progress', 'submitted', 'left')
   - `attempt_id` (uuid, FK to attempts, nullable)
   - `score` (numeric, nullable)
   - `correct_answers` (int, nullable)
   - `total_questions` (int, nullable)
   - `submitted_at` (timestamptz, nullable)
   - `requested_at` (timestamptz default now())

2. **RPC: `public.join_student_room`**:
   - Parameters: `p_code text`, `p_password text default null`, `p_guest_name text default null`
   - Validates room existence and password hash.
   - Creates or updates participant record.
   - Returns JSON:
     ```json
     {
       "roomId": "...",
       "participantId": "...",
       "code": "PT892341",
       "name": "Kiểm tra 15 phút",
       "status": "waiting",
       "examTitle": "Toán 12",
       "subject": "Toán Học",
       "durationMinutes": 45,
       "teacherName": "Thầy Nam",
       "attemptId": null
     }
     ```

3. **RPC: `public.get_student_room_state`**:
   - Parameters: `p_room_id uuid`, `p_participant_id uuid`
   - Returns current room status, participant count, peer avatars, and active `attempt_id` when live.

4. **RPC: `public.submit_room_attempt`**:
   - Parameters: `p_room_id uuid`, `p_attempt_id uuid`, `p_answers jsonb`
   - Calculates total score and correct answer count.
   - Updates `public.attempts` and `public.room_participants` (`status = 'submitted'`, `score`, `correct_answers`, `submitted_at = now()`).
   - Returns assessment score and summary.

5. **RPC: `public.get_room_leaderboard`**:
   - Parameters: `p_room_id uuid`
   - Returns sorted leaderboard list:
     ```json
     [
       {
         "rank": 1,
         "participantId": "...",
         "name": "Trần Văn A",
         "status": "submitted",
         "score": 10.0,
         "correctCount": 40,
         "totalQuestions": 40,
         "durationSeconds": 1420,
         "submittedAt": "2026-09-03T14:30:00Z"
       }
     ]
     ```

---

## 3. Flutter Architecture & Components

### 3.1 Repository & Providers
- **`RoomRepository`** (`lib/core/repositories/room_repository.dart`):
  - `joinRoom({required String code, String? password, String? guestName})`
  - `getStudentRoomState({required String roomId, required String participantId})`
  - `getRoomLeaderboard(String roomId)`
  - `startRoom(String roomId)`
  - `submitRoomAttempt({required String roomId, required String attemptId, required Map<String, dynamic> answers})`
  - `subscribeRoomChanges(String roomId, Function(String status) onStatusChanged)`

### 3.2 Screens & UI Flow
1. **`HomeScreen`** (`lib/screens/home/home_screen.dart`):
   - PIN input controller with formatting & validation.
   - If not logged in, shows `GuestNameDialog` before navigating.
2. **`StudentWaitingRoomScreen`** (`lib/screens/room/student_waiting_room_screen.dart`):
   - Dynamic data binding (exam title, teacher name, duration, participant list).
   - Realtime subscription + 3s timer polling `getStudentRoomState`.
   - Auto navigates to `/taking_exam?roomId=...&attemptId=...` once status is `'live'`.
3. **`TeacherWaitingRoomScreen`** (`lib/screens/room/teacher_waiting_room_screen.dart`):
   - Real-time participant counter and avatar list.
   - Start exam button.
   - Live proctoring leaderboard toggle once room starts.
4. **`LiveLeaderboardDialog / Widget`** (`lib/screens/room/widgets/live_leaderboard_view.dart`):
   - Top 3 medal badges (Gold, Silver, Bronze).
   - Real-time score, progress indicators, and submitted tags.

---

## 4. Verification & Testing Strategy
- **Unit & Repository Tests**:
  - Mock Supabase RPC responses for `join_student_room`, `get_student_room_state`, `submit_room_attempt`, `get_room_leaderboard`.
- **Widget Tests**:
  - Test `StudentWaitingRoomScreen` reactive state updates.
  - Test `TeacherWaitingRoomScreen` transition to live leaderboard.
  - Test PIN code input dialog and error validation on `HomeScreen`.
