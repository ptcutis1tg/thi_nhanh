# Developer Mode & Floating Error Log Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a hidden Developer Mode activated by entering secret room codes (`18366767` for Standard error logs, `67676767` for Verbose debug logs) that displays a persistent, scrollable floating log overlay in the bottom-right corner of the app with one-click copy and clear capabilities.

**Architecture:** A global `DeveloperModeService` (`ChangeNotifier`) persists state in `SharedPreferences`, intercepts `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `debugPrint`, and red error SnackBars via `AppErrorReporter`. The UI is mounted over the entire app stack using `MaterialApp.builder` so the floating badge and log console remain active across all route transitions.

**Tech Stack:** Flutter / Dart, Provider, GoRouter, SharedPreferences, Flutter Services (Clipboard).

## Global Constraints
- Secret codes `18366767` and `67676767` must silently toggle without noisy dialogs, clearing the room code input field.
- Mode state must persist in `SharedPreferences` across browser refreshes (F5).
- Overlay must be pinned at bottom-right, scrollable, and fit small screen bounds cleanly.
- Must preserve existing 31+ tests with 100% pass rate.
- Per user guidelines, once completed, automatically commit and push to remote repository for GitHub Actions deployment.

---

### Task 1: DeveloperModeService & Data Models

**Files:**
- Create: `lib/core/services/developer_mode_service.dart`
- Test: `test/services/developer_mode_service_test.dart`

**Interfaces:**
- Produces:
  - `enum DevModeLevel { none, standard, verbose }`
  - `enum DevLogLevel { error, debug }`
  - `class DevLogEntry(id, timestamp, level, title, details, stackTrace)`
  - `class DeveloperModeService extends ChangeNotifier`:
    - `DevModeLevel level`
    - `bool isExpanded`
    - `List<DevLogEntry> logs`
    - `Future<void> init({SharedPreferences? prefs})`
    - `Future<bool> handleRoomCode(String rawCode)`
    - `void recordError(String title, {dynamic error, dynamic stackTrace})`
    - `void recordDebug(String message)`
    - `void clearLogs()`
    - `void toggleExpanded()`
    - `void setExpanded(bool expanded)`

- [ ] **Step 1: Write unit tests for DeveloperModeService**
Create `test/services/developer_mode_service_test.dart` testing `handleRoomCode('18366767')` toggle, `handleRoomCode('67676767')` toggle, persistence in `SharedPreferences`, `recordError`, `recordDebug`, and `clearLogs`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/services/developer_mode_service_test.dart`
Expected: FAIL (file not found / class not defined).

- [ ] **Step 3: Implement DeveloperModeService**
Create `lib/core/services/developer_mode_service.dart` with full logic:
- `handleRoomCode`: handles `18366767` (toggles `standard` <-> `none`), `67676767` (toggles `verbose` <-> `none`).
- Saves `developer_mode_level` to `SharedPreferences`.
- Formats logs into clean copyable strings.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/services/developer_mode_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit Task 1**
```bash
git add lib/core/services/developer_mode_service.dart test/services/developer_mode_service_test.dart
git commit -m "feat(dev_mode): implement DeveloperModeService and unit tests"
```

---

### Task 2: Floating DeveloperLogOverlay Widget

**Files:**
- Create: `lib/shared/widgets/developer_log_overlay.dart`
- Test: `test/widgets/developer_log_overlay_test.dart`

**Interfaces:**
- Consumes: `DeveloperModeService` from `Provider`
- Produces: `class DeveloperLogOverlay extends StatelessWidget`

- [ ] **Step 1: Write widget tests for DeveloperLogOverlay**
Create `test/widgets/developer_log_overlay_test.dart`:
- When `level == DevModeLevel.none`, renders `SizedBox.shrink()` (hidden).
- When `level == DevModeLevel.standard`, renders collapsed badge with log count.
- Tapping badge expands console container.
- Verifies "Sao chép tất cả", "Xóa log", "Thu nhỏ" actions and copy-to-clipboard call.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/widgets/developer_log_overlay_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement DeveloperLogOverlay**
Create `lib/shared/widgets/developer_log_overlay.dart`:
- Bottom-right positioned floating overlay.
- Collapsed: pill badge `[🐞 Dev (count)]`.
- Expanded: Dark styled card (`#0F172A`, `#1E293B`), max-height 340px, width 380px.
- Action buttons: Copy all, Clear, Minimize.
- Each log item has timestamp, badge, title, expandable stack trace, and single-item copy button.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/widgets/developer_log_overlay_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit Task 2**
```bash
git add lib/shared/widgets/developer_log_overlay.dart test/widgets/developer_log_overlay_test.dart
git commit -m "feat(dev_mode): implement DeveloperLogOverlay widget and tests"
```

---

### Task 3: Error Reporter & Root App Integration

**Files:**
- Create: `lib/core/utils/app_error_reporter.dart`
- Modify: `lib/main.dart`
- Test: `test/widgets/root_developer_overlay_test.dart`

**Interfaces:**
- Produces: `AppErrorReporter.showErrorSnackBar(BuildContext context, String message, {dynamic error, dynamic stackTrace})`
- Modifies `lib/main.dart`:
  - Registers `ChangeNotifierProvider.value(value: devModeService)`.
  - Overrides `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `debugPrint`.
  - Wraps `MaterialApp.router` with `builder: (context, child) => Stack(children: [child!, const DeveloperLogOverlay()])`.

- [ ] **Step 1: Write integration widget test for root overlay**
Create `test/widgets/root_developer_overlay_test.dart` verifying that `DeveloperLogOverlay` stays mounted over child routes and catches logged errors.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/widgets/root_developer_overlay_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement AppErrorReporter and update main.dart**
- Create `lib/core/utils/app_error_reporter.dart`.
- In `lib/main.dart`, initialize `DeveloperModeService`, bind error handlers, provide service in `MultiProvider`, and add `builder` in `MaterialApp.router`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/widgets/root_developer_overlay_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit Task 3**
```bash
git add lib/core/utils/app_error_reporter.dart lib/main.dart test/widgets/root_developer_overlay_test.dart
git commit -m "feat(dev_mode): integrate DeveloperModeService into main.dart root overlay and error handlers"
```

---

### Task 4: Connect Secret Codes in Room Inputs

**Files:**
- Modify: `lib/screens/home/home_screen.dart:70-80`
- Modify: `lib/screens/exam/exam_detail_screen.dart:295-315`
- Test: `test/screens/developer_mode_trigger_test.dart`

**Interfaces:**
- Consumes: `DeveloperModeService.handleRoomCode(code)`

- [ ] **Step 1: Write test for room code input triggering Developer Mode**
Create `test/screens/developer_mode_trigger_test.dart` testing typing `18366767` in HomeScreen room code field, clicking "Vào phòng", verifying input clears, dev mode toggles, and no navigation/error occurs.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/screens/developer_mode_trigger_test.dart`
Expected: FAIL.

- [ ] **Step 3: Update HomeScreen and ExamDetailScreen**
- In `_handleJoinRoom(context)` in `lib/screens/home/home_screen.dart`:
  - Check `await devModeService.handleRoomCode(code)`. If true, `_joinRoomController.clear(); return;`.
- In `_ExamStartCard` in `lib/screens/exam/exam_detail_screen.dart`:
  - Before starting/joining, check `await devModeService.handleRoomCode(code)`. If true, clear controller and return.
- Connect existing red SnackBars to `AppErrorReporter` where appropriate.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/screens/developer_mode_trigger_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit Task 4**
```bash
git add lib/screens/home/home_screen.dart lib/screens/exam/exam_detail_screen.dart test/screens/developer_mode_trigger_test.dart
git commit -m "feat(dev_mode): wire secret codes 18366767 and 67676767 into room code input handlers"
```

---

### Task 5: Complete Verification, Git Push & Remote Synchronization

- [ ] **Step 1: Run full test suite**
Run: `flutter test`
Expected: All 35+ tests pass (100%).

- [ ] **Step 2: Push commit to remote GitHub repository**
Per user rule: Auto-push upon feature completion to trigger GitHub Actions deployment:
```bash
git push origin main
```
Also update submodule pointer in parent `CODE` repository and push if applicable.
