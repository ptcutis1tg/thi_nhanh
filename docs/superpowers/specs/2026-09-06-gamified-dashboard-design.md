# Gamified Dashboard & Role-Based Navigation Design

## Goal
Transform the main Home screen (`HomeScreen`) into a vibrant, gamified dashboard with dynamic layouts tailored to the active user role (Student vs. Teacher). Enable seamless role switching directly from the dashboard header, persistent state via `AuthProvider` and `SharedPreferences`, and updated `TopNavBar` visibility based on role.

---

## 1. User Roles & State Management

### Global State in `AuthProvider`
- Add `UserRole` enum (`student`, `teacher`).
- Property `currentRole` in `AuthProvider` (defaults to `student`, or auto-detected/restored from storage).
- Persist `user_role` in `SharedPreferences`.
- Method `setRole(UserRole role)` and `toggleRole()` that save state and notify listeners.
- Convenience getters: `isStudent`, `isTeacher`.

---

## 2. Header & Quick Actions Bar (`HomeScreen`)

- **User Info Card**: Displays Avatar, User Name, and Role Badge (`🎓 Học sinh` or `👨‍🏫 Giáo viên`).
- **Role Switcher Button**: Interactive toggle button to switch between Student and Teacher modes with instant UI update.
- **Quick-Join Room Input**: Prominent pill-shaped text field with `PTxxxxxx` placeholder and **"Vào ngay ➔"** action button.
- **Quick Stats Bar**:
  - *Student mode*: Streak count (🔥), Average score (🎯), Completed tests count (📝).
  - *Teacher mode*: Created exams count (📄), Active students in live rooms (👥), Completion rate (⚡).

---

## 3. Main Feature Grid (6 Large Gamified Cards)

Cards feature soft light-purple backgrounds (`#F7F5FE`), rounded corners (20px), custom icon & color per feature, hover elevation on Web, and staggered entry animations.

### Student Mode Cards:
1. 🚪 **Vào phòng thi**: Quick room code entry & active waiting room shortcut.
2. 🔍 **Tìm đề luyện tập**: Subject exam library browser (`/search`).
3. 📝 **Bài đang làm**: In-progress exams resumes.
4. 📊 **Lịch sử & Kết quả**: Past test results and answer reviews.
5. 🏆 **Thành tích cá nhân**: Unlocked badges, streak counters.
6. 🥇 **Bảng xếp hạng**: Top student leaderboards.

### Teacher Mode Cards:
1. ➕ **Tạo đề thi**: Exam creation form shortcut (`/create_exam`).
2. 📁 **Quản lý đề**: Exam set manager & editor.
3. 🏛️ **Tạo phòng thi**: Exam room launcher (`/create_room`).
4. 🔴 **Phòng đang diễn ra**: Live rooms list with pulsing green dot & online count indicator.
5. 📈 **Kết quả học sinh**: Submissions & grade reports.
6. 📊 **Thống kê giảng dạy**: Score distribution & question analysis.

---

## 4. Bottom Section & Extra Widgets
- **Recent Rooms & Exams**: Horizontal scroll list of recently accessed items.
- **Notifications**: Live alert list.
- **Help Center & FAQs**: Usage guide cards for students & teachers.
- **Utility Action Bar**: Settings and Sign Out buttons.

---

## 5. TopNavBar Updates
- `TopNavBar` consumes `AuthProvider.currentRole`.
- **Student Mode**: Displays `Home` (`/home`) and `Tìm kiếm` (`/search`).
- **Teacher Mode**: Displays `Home`, `Tìm kiếm`, `Tạo đề thi` (`/create_exam`), and `Tạo phòng thi` (`/create_room`).
