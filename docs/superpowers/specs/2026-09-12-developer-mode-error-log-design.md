# Developer Mode & Floating Error Log Overlay Design

## 1. Overview & Goals

This feature introduces a hidden **Developer Mode** into the application, activated via secret room codes entered in room PIN input fields.

When Developer Mode is enabled:
- A compact, non-intrusive floating Developer badge appears docked at the **bottom-right** of the screen across all routes.
- Any error popups (red SnackBars, error dialogs), runtime exceptions (Supabase errors, network timeouts, unhandled Flutter exceptions), and optionally system `debugPrint` logs are intercepted and buffered.
- The floating container auto-expands on new errors (or when clicked), displaying an interactive, scrollable dark-mode log console with detailed error messages, timestamps, and stack traces.
- Users can copy individual logs or all logs to the clipboard with one click, clear the log buffer, or minimize the console.

---

## 2. Secret Activation Codes & Persistence

### Trigger Codes
- **`18366767`**: Toggles **Standard Developer Mode** (`DevModeLevel.standard`).
  - Intercepts red error popups, API/Supabase exceptions, and Flutter unhandled errors with full stack traces.
- **`67676767`**: Toggles **Verbose Developer Mode** (`DevModeLevel.verbose`).
  - Intercepts all items from Standard Mode PLUS all system `debugPrint` output.
- **Re-entering the active code**: Toggles Developer Mode **OFF** (`DevModeLevel.none`).

### Silent Behavior
- When either secret code is submitted in any room code field:
  - The input field is automatically cleared.
  - No popup/dialog is displayed (silent toggle).
  - The floating Developer badge in the bottom-right corner immediately updates its state.

### Persistence
- Developer Mode level is persisted in `SharedPreferences` under key `developer_mode_level` (`'none'`, `'standard'`, `'verbose'`).
- Refreshing the browser or reopening the app preserves the activated Developer Mode.

### Input Locations
1. **[home_screen.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/home/home_screen.dart)**: In `_handleJoinRoom()`.
2. **[exam_detail_screen.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/exam/exam_detail_screen.dart)**: In room code input of `_ExamStartCard`.

---

## 3. Architecture & Core Components

```
+-------------------------------------------------------------+
|                      MaterialApp.builder                    |
|  +-------------------------------------------------------+  |
|  |                    GoRouter Navigator                 |  |
|  |       (Home / Search / Exam / Rooms / Results / etc)   |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  +-------------------------------------------------------+  |
|  |           Floating Developer Overlay (Bottom-Right)    |  |
|  |   - Collapsed Badge: [🐞 Dev: 3]                       |  |
|  |   - Expanded Console: Scrollable logs + Copy + Clear  |  |
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
                              ^
                              | listens & updates
+-------------------------------------------------------------+
|                    DeveloperModeService                     |
|  - devModeLevel: none | standard | verbose                  |
|  - logs: List<DevLogEntry>                                  |
|  - toggleSecretCode(code)                                   |
|  - logError(message, [error, stackTrace])                   |
|  - logDebug(message)                                        |
|  - clearLogs()                                              |
+-------------------------------------------------------------+
        ^                       ^                      ^
        |                       |                      |
FlutterError.onError    AppErrorReporter      debugPrint override
PlatformDispatcher      (Red SnackBars/etc)   (Verbose mode)
```

### 3.1 Data Models & Service: `DeveloperModeService`
- Location: `lib/core/services/developer_mode_service.dart`
- **`DevModeLevel`**: Enum with values `none`, `standard`, `verbose`.
- **`DevLogEntry`**:
  - `id`: String (UUID or monotonic ID).
  - `timestamp`: DateTime.
  - `level`: `DevLogLevel.error` or `DevLogLevel.debug`.
  - `title`: String.
  - `details`: String? (e.g. error object or exception description).
  - `stackTrace`: String? (formatted stack trace).
  - `formattedText`: Helper getter producing clean copyable text:
    ```
    [HH:mm:ss] [ERROR] Lỗi tải dữ liệu đề thi
    Details: SupabaseException: Failed host lookup
    Stack:
    #0 ...
    ```
- **Service API**:
  - `Future<void> init()`: Loads saved level from `SharedPreferences`.
  - `Future<bool> handleRoomCode(String code)`: Returns `true` if `code` was a recognized secret code (`18366767` or `67676767`) and toggled the mode; returns `false` otherwise.
  - `void recordError(String title, {dynamic error, dynamic stackTrace})`
  - `void recordDebug(String message)`
  - `void clearLogs()`
  - `void setExpanded(bool expanded)`

### 3.2 Global Error Interception
- **`AppErrorReporter`**: Helper utility providing `AppErrorReporter.showErrorSnackBar(BuildContext context, String message, {dynamic error, dynamic stackTrace})` to standardize red SnackBar notifications while reliably forwarding technical logs to `DeveloperModeService`.
- **`FlutterError.onError`**: Captures unhandled widget framework exceptions.
- **`PlatformDispatcher.instance.onError`**: Captures asynchronous uncaught errors.
- **`debugPrint` redirection**: Overridden in `main.dart` to forward to `DeveloperModeService.recordDebug` when level is `verbose`.

### 3.3 UI Component: `DeveloperLogOverlay`
- Location: `lib/shared/widgets/developer_log_overlay.dart`
- Mounted inside `MaterialApp.builder`:
  ```dart
  MaterialApp.router(
    ...
    builder: (context, child) {
      return Stack(
        children: [
          if (child != null) child,
          const DeveloperLogOverlay(),
        ],
      );
    },
  )
  ```
- **Collapsed View (Badge)**:
  - Position: Pinned at bottom: 20, right: 20.
  - Visual: Compact dark pill (`#0F172A`), red accent icon `🐞`, text `Dev (${logs.length})`, subtle shadow.
  - Behavior: Clicking toggles expanded state. Auto-expands on new incoming error.
- **Expanded View (Console)**:
  - Dimensions: Width 380px, max-height 340px (responsive on small screens, fitting within screen bounds).
  - Header:
    - Title: `🐞 Dev Console` with level chip (`STANDARD` or `VERBOSE`).
    - Action buttons:
      - **Sao chép tất cả** (Copy icon with tooltip and confirmation SnackBar/toast).
      - **Xóa log** (Delete/trash icon).
      - **Thu nhỏ** (Minimize icon).
  - Body:
    - `ListView.builder` with smooth scrollbar.
    - Each item displays:
      - Header row: timestamp `[HH:mm:ss]`, tag badge (`ERROR` in `#EF4444`, `DEBUG` in `#06B6D4`), and a mini "Copy" button.
      - Message text: High contrast readable font.
      - Collapsible / scrollable stack trace box in monospace font (`Fira Code` / system monospace) with `#020617` background.
  - Empty state: "Chưa có log lỗi nào được ghi nhận."

---

## 4. User Interaction Flow

1. User opens app and navigates to either Home Screen or Exam Detail Screen.
2. In the room code input field, user types `18366767` and clicks "Vào phòng" / "Bắt đầu làm bài" (or presses Enter).
3. The input field immediately clears; no dialog or notification pops up.
4. The floating `[🐞 Dev: 0]` badge smoothly appears at the bottom-right corner.
5. If an operation fails (e.g. Supabase network failure, invalid room PIN, exception), the red SnackBar displays as usual, and simultaneously the Dev console auto-expands with the full stack trace and error payload.
6. User clicks "Sao chép" on the log or "Sao chép tất cả" to paste into debugging tools / chat.
7. To disable Developer Mode, user enters `18366767` again; the badge fades away.
8. If user enters `67676767`, Verbose Mode activates (capturing `debugPrint` logs in addition to errors).

---

## 5. Verification & Testing Plan

### Automated Tests
1. **Unit tests (`test/services/developer_mode_service_test.dart`)**:
   - Verify `handleRoomCode('18366767')` toggles `DevModeLevel.standard` on and off.
   - Verify `handleRoomCode('67676767')` toggles `DevModeLevel.verbose` on and off.
   - Verify persistence in `SharedPreferences`.
   - Verify log recording, log formatting, and `clearLogs()`.
2. **Widget tests (`test/widgets/developer_log_overlay_test.dart`)**:
   - Verify overlay is hidden when `DevModeLevel.none`.
   - Verify badge renders when active, expands on click, displays log entries, and allows copying / clearing.
3. **Integration / Screen tests**:
   - Verify entering `18366767` in `HomeScreen` clears the input and activates the service.
   - Run complete suite: `flutter test` to ensure 100% pass rate.
