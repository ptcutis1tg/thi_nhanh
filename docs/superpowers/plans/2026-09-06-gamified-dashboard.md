# Gamified Dashboard & Role-Based Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a gamified role-aware home dashboard for `thi_nhanh` that dynamically renders student vs. teacher features, integrates global role management in `AuthProvider`, and updates top navigation links dynamically.

**Architecture:** Extend `AuthProvider` to manage role state (`UserRole.student` vs `UserRole.teacher`) with `SharedPreferences` persistence. Update `TopNavBar` to conditionally filter menu options based on active role. Rebuild `HomeScreen` with a modern gamified dashboard layout featuring a role header, stats bar, quick room entry, 6 feature cards grid (varying by role), recent activity, notifications, and help cards.

**Tech Stack:** Flutter / Dart, Provider (`AuthProvider`), `SharedPreferences`, `GoRouter`, Material 3 / Custom AppTheme styling.

## Global Constraints
- Role enum: `UserRole.student`, `UserRole.teacher`.
- Storage key: `active_user_role`.
- Student TopNavBar routes: `/home`, `/search`.
- Teacher TopNavBar routes: `/home`, `/search`, `/create_exam`, `/create_room`.

---

### Task 1: Add Role Management to `AuthProvider`

**Files:**
- Modify: `d:\thi_nhanh\lib\core\providers\auth_provider.dart`

**Interfaces:**
- Consumes: `SharedPreferences`
- Produces: `enum UserRole { student, teacher }`, `UserRole currentRole`, `bool isStudent`, `bool isTeacher`, `Future<void> setRole(UserRole role)`, `Future<void> toggleRole()`

- [ ] **Step 1: Define `UserRole` enum and add state variables in `AuthProvider`**

Add `enum UserRole { student, teacher }` and fields `UserRole _currentRole = UserRole.student;` in `auth_provider.dart`.

- [ ] **Step 2: Add getters and methods for role management**

```dart
enum UserRole { student, teacher }

// Inside AuthProvider:
UserRole _currentRole = UserRole.student;
UserRole get currentRole => _currentRole;
bool get isStudent => _currentRole == UserRole.student;
bool get isTeacher => _currentRole == UserRole.teacher;

Future<void> setRole(UserRole role) async {
  _currentRole = role;
  await _saveState();
  notifyListeners();
}

Future<void> toggleRole() async {
  _currentRole = _currentRole == UserRole.student ? UserRole.teacher : UserRole.student;
  await _saveState();
  notifyListeners();
}
```

- [ ] **Step 3: Update `_loadSavedState()` and `_saveState()` to persist role**

In `_loadSavedState()`:
```dart
final savedRole = prefs.getString('active_user_role');
if (savedRole == 'teacher') {
  _currentRole = UserRole.teacher;
} else if (savedRole == 'student') {
  _currentRole = UserRole.student;
}
```
In `_saveState()`:
```dart
await prefs.setString('active_user_role', _currentRole == UserRole.teacher ? 'teacher' : 'student');
```

- [ ] **Step 4: Verify AuthProvider compiles**

Run Flutter check or inspect for lint errors.

- [ ] **Step 5: Commit changes**

`git commit -m "feat: add global role management to AuthProvider"`

---

### Task 2: Update `TopNavBar` to Filter Items by Active Role

**Files:**
- Modify: `d:\thi_nhanh\lib\shared\widgets\top_nav_bar.dart`

**Interfaces:**
- Consumes: `authProvider.isTeacher`, `authProvider.isStudent`
- Produces: Dynamic list of menu items in `TopNavBar` header

- [ ] **Step 1: Update menu items builder in `TopNavBar`**

Modify `TopNavBar` build method to check `authProvider.isTeacher`:

```dart
final isTeacher = authProvider.isTeacher;

// In Row children:
Row(
  children: [
    _buildNavItem(context, 'Home', '/home', isActive: GoRouterState.of(context).matchedLocation == '/home'),
    const SizedBox(width: 32),
    _buildNavItem(context, 'Tìm kiếm', '/search', isActive: GoRouterState.of(context).matchedLocation == '/search'),
    if (isTeacher) ...[
      const SizedBox(width: 32),
      _buildNavItem(context, 'Tạo đề thi', '/create_exam', isActive: GoRouterState.of(context).matchedLocation == '/create_exam'),
      const SizedBox(width: 32),
      _buildNavItem(context, 'Tạo phòng thi', '/create_room', isActive: GoRouterState.of(context).matchedLocation == '/create_room'),
    ],
  ],
)
```

- [ ] **Step 2: Commit changes**

`git commit -m "feat: filter TopNavBar links based on active user role"`

---

### Task 3: Sync `ProfileScreen` Role Switcher with `AuthProvider`

**Files:**
- Modify: `d:\thi_nhanh\lib\screens\profile\profile_screen.dart`

**Interfaces:**
- Consumes: `authProvider.toggleRole()`, `authProvider.isStudent`
- Produces: Unified role switching in Profile screen

- [ ] **Step 1: Replace local `_isStudentRole` toggle with `authProvider.toggleRole()`**

Update `ProfileScreen` role toggle handler:

```dart
InkWell(
  onTap: () {
    authProvider.toggleRole();
    _showSnackBar('Đã chuyển góc nhìn sang ${authProvider.isStudent ? 'Học sinh' : 'Giáo viên'}');
  },
  child: ...
  Text(authProvider.isStudent ? '🎓 Học sinh' : '👨‍🏫 Giáo viên', ...)
)
```

- [ ] **Step 2: Commit changes**

`git commit -m "refactor: sync ProfileScreen role toggle with AuthProvider"`

---

### Task 4: Rebuild `HomeScreen` with Gamified Dashboard UI

**Files:**
- Modify: `d:\thi_nhanh\lib\screens\home\home_screen.dart`

**Interfaces:**
- Consumes: `authProvider.userName`, `authProvider.isStudent`, `authProvider.isTeacher`, `authProvider.toggleRole()`
- Produces: Complete Gamified Dashboard with 6 role-based cards, header stats, quick room entry, pulsing live indicators, and bottom utilities.

- [ ] **Step 1: Build Header Section with User info, Role switcher, and Quick-Join Room bar**

Include avatar, user name, role toggle button (`🎓 Học sinh` / `👨‍🏫 Giáo viên`), and room code input (`PTxxxxxx`).

- [ ] **Step 2: Build Stats Bar**

Display 3 quick statistics cards based on active role (Streak 🔥, Avg score 🎯, Tests 📝 for Student; Created exams 📄, Active students 👥, Completion rate ⚡ for Teacher).

- [ ] **Step 3: Build 6 Gamified Feature Cards Grid**

Implement grid of 6 styled cards with custom icons, colors, hover animation, and routes:
- *Student*: Vào phòng thi, Tìm đề luyện tập, Bài đang làm, Lịch sử kết quả, Thành tích cá nhân, Bảng xếp hạng.
- *Teacher*: Tạo đề thi, Quản lý đề, Tạo phòng thi, Phòng đang diễn ra (with pulsing green live dot), Kết quả học sinh, Thống kê giảng dạy.

- [ ] **Step 4: Build Bottom Section (Recent activity, Notifications, Help cards, Settings)**

Add recent rooms/exams horizontal slider, notification list preview, user guides, and settings/signout action bar.

- [ ] **Step 5: Verify build & layout rendering**

- [ ] **Step 6: Commit changes**

`git commit -m "feat: implement Gamified Dashboard layout for Student and Teacher roles"`
