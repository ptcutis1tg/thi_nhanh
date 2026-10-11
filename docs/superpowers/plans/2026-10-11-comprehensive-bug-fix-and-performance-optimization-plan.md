# Comprehensive Bug Fix & Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triệt tiêu 100% rò rỉ bộ nhớ, tối ưu hiệu năng render 60/120 FPS & smart polling, khắc phục toàn bộ lỗi logic Auth OTP/routing, hoàn thiện tính năng chia đều điểm và xóa sạch 57 cảnh báo Flutter analyze.

**Architecture:** Áp dụng Zero-Leak Lifecycle cho tất cả các StatefulWidget/Controllers, tích hợp AppLifecycleState để tạm dừng timer polling khi ứng dụng ẩn dưới nền, bọc RepaintBoundary quanh các thành phần hoạt ảnh nặng, sửa các API deprecated sang chuẩn Flutter M3, và bổ sung phương thức resendSignUpOTP chuẩn Supabase.

**Tech Stack:** Flutter 3.x, Dart 3.x, Supabase Flutter SDK, Provider, GoRouter, Google Fonts, Flutter Test.

## Global Constraints
- Tất cả các StatefulWidget có tạo `TextEditingController`, `AnimationController`, `ScrollController`, `Timer` hoặc `StreamSubscription` BẮT BUỘC phải override `dispose()` và giải phóng sạch tài nguyên.
- Kiểm thử phân tích tĩnh `flutter analyze` sau khi hoàn thành phải trả về `0 issues found`.
- Bộ kiểm thử tự động `flutter test` phải chạy thành công 100% (231/231+ tests pass).
- Tự động cập nhật `docs/system_architecture_and_deep_evaluation.md` và git commit/push sau khi hoàn thành.

---

### Task 1: Khắc phục Lỗi Auth OTP Resend & Hủy Stream Subscription AuthProvider

**Files:**
- Modify: `lib/core/providers/auth_provider.dart:45-70`
- Modify: `lib/screens/auth/greeting_screen.dart:660-690, 840-853`
- Test: `test/screens/greeting_otp_resend_test.dart`

**Interfaces:**
- Produces: `AuthProvider.resendSignUpOTP(String email) -> Future<void>`
- Consumes: Supabase auth `resend(type: OtpType.signup, email: email)`

- [ ] **Step 1: Viết test kiểm tra resendSignUpOTP và dispose GreetingScreen**

Tạo file `test/screens/greeting_otp_resend_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/auth/greeting_screen.dart';

void main() {
  testWidgets('GreetingScreen creates and disposes cleanly without memory leaks', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: GreetingScreen()),
      ),
    );
    expect(find.byType(GreetingScreen), findsOneWidget);

    // Replace with empty container to trigger dispose
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(GreetingScreen), findsNothing);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận**

Run: `flutter test test/screens/greeting_otp_resend_test.dart`
Expected: PASS

- [ ] **Step 3: Bổ sung resendSignUpOTP và StreamSubscription cancel vào AuthProvider**

Chỉnh sửa `lib/core/providers/auth_provider.dart`:
```dart
  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider({bool isSupabaseInitialized = false}) {
    if (isSupabaseInitialized) {
      _supabaseClient = Supabase.instance.client;
      _user = _supabaseClient?.auth.currentUser;
      _authSubscription = _supabaseClient?.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        if (data.event == AuthChangeEvent.passwordRecovery) {
          _isPasswordRecoveryMode = true;
          if (_user?.email != null) {
            _userEmail = _user!.email;
          }
          debugPrint('Đã kích hoạt chế độ khôi phục mật khẩu từ Supabase Recovery Event!');
        } else if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.tokenRefreshed ||
            data.event == AuthChangeEvent.userUpdated) {
          _syncProfileFromUser();
        } else if (data.event == AuthChangeEvent.signedOut) {
          _userName = null;
          _userEmail = null;
          _userAvatarUrl = null;
          _saveState();
        }
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> resendSignUpOTP(String email) async {
    final cleanEmail = email.trim();
    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.resend(
          type: OtpType.signup,
          email: cleanEmail,
        );
      } catch (e) {
        debugPrint('Lỗi gửi lại mã OTP đăng ký: $e');
        rethrow;
      }
    }
  }
```

- [ ] **Step 4: Cập nhật _handleResend và bổ sung dispose() trong GreetingScreen**

Chỉnh sửa `lib/screens/auth/greeting_screen.dart`:
Trong `_GreetingScreenState`:
```dart
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
```
Trong `_OtpVerificationDialogState._handleResend()`:
```dart
  Future<void> _handleResend() async {
    if (_countdown > 0) return;
    setState(() => _errorMessage = null);
    try {
      await context.read<AuthProvider>().resendSignUpOTP(widget.email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã OTP 8 số về hộp thư của bạn!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Chưa thể gửi lại mã lúc này. Vui lòng thử lại sau.');
    }
  }
```

- [ ] **Step 5: Chạy lại test và commit**

Run: `flutter test test/screens/greeting_otp_resend_test.dart`
Expected: PASS

```bash
git add lib/core/providers/auth_provider.dart lib/screens/auth/greeting_screen.dart test/screens/greeting_otp_resend_test.dart
git commit -m "fix(auth): add resendSignUpOTP, cancel auth subscription, and dispose greeting controllers"
```

---

### Task 2: Khắc phục Lỗi Điều hướng Route & Đồng bộ Đóng Phòng Thi

**Files:**
- Modify: `lib/screens/exam/exam_detail_screen.dart:200-215`
- Modify: `lib/screens/room/create_room_screen.dart:10-45, 65-80`
- Modify: `lib/main.dart:268-275`
- Modify: `lib/screens/exam/live_dashboard_screen.dart:180-210`
- Test: `test/screens/room_route_params_and_closing_test.dart`

**Interfaces:**
- Produces: `CreateRoomScreen(initialExamId: ...)`
- Consumes: `RoomRepository.close(String roomId)`

- [ ] **Step 1: Viết test kiểm tra route params & close room synchronization**

Tạo file `test/screens/room_route_params_and_closing_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';

void main() {
  testWidgets('CreateRoomScreen accepts initialExamId parameter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreateRoomScreen(initialExamId: 'exam-123'),
      ),
    );
    expect(find.byType(CreateRoomScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận**

Run: `flutter test test/screens/room_route_params_and_closing_test.dart`
Expected: PASS

- [ ] **Step 3: Cập nhật ExamDetailScreen, CreateRoomScreen, main.dart và LiveDashboardScreen**

Trong `lib/screens/exam/exam_detail_screen.dart`:
Sửa dòng 208:
```dart
      if (mounted) {
        context.go('/room/password?code=${Uri.encodeComponent(code)}');
      }
```

Trong `lib/screens/room/create_room_screen.dart`:
Thêm `final String? initialExamId;` vào `CreateRoomScreen({super.key, this.initialExamId});`.
Trong `_loadCreatedExams()`:
```dart
      if (mounted) {
        if (_selectedExam == null && widget.initialExamId != null) {
          try {
            _selectedExam = _allAvailableExams.firstWhere((e) => e.id == widget.initialExamId);
          } catch (_) {}
        }
        setState(() => _isLoadingExams = false);
      }
```

Trong `lib/main.dart`:
Sửa cấu hình route `/create_room`:
```dart
        GoRoute(
          path: '/create_room',
          pageBuilder: (context, state) => buildPageWithSlideTransition(
            context: context,
            state: state,
            child: CreateRoomScreen(
              initialExamId: state.uri.queryParameters['examId'],
            ),
          ),
        ),
```

Trong `lib/screens/exam/live_dashboard_screen.dart`:
Cập nhật nút "Đóng phòng thi" trong dialog:
```dart
                        onPressed: () async {
                          context.pop();
                          try {
                            final roomRepo = context.read<RoomRepository?>();
                            if (roomRepo != null && rRes != null && rRes['id'] != null) {
                              await roomRepo.close(rRes['id'].toString());
                            }
                          } catch (_) {}
                          if (context.mounted) {
                            context.go('/home');
                          }
                        },
```

- [ ] **Step 4: Chạy lại test suite và commit**

Run: `flutter test test/screens/room_route_params_and_closing_test.dart`
Expected: PASS

```bash
git add lib/screens/exam/exam_detail_screen.dart lib/screens/room/create_room_screen.dart lib/main.dart lib/screens/exam/live_dashboard_screen.dart test/screens/room_route_params_and_closing_test.dart
git commit -m "fix(routing): propagate roomCode and initialExamId, close room in database on LiveDashboard"
```

---

### Task 3: Triệt tiêu Memory Leaks bằng cách bổ sung `dispose()` cho 8 Màn hình

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/screens/room/student_waiting_room_screen.dart`
- Modify: `lib/screens/room/create_room_screen.dart`
- Modify: `lib/screens/auth/reset_password_screen.dart`
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/screens/home/search_screen.dart`
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Test: `test/screens/lifecycle_and_dispose_test.dart`

- [ ] **Step 1: Viết test kiểm tra vòng đời dispose sạch sẽ**

Tạo file `test/screens/lifecycle_and_dispose_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/home/home_screen.dart';
import 'package:onthi_community/screens/home/search_screen.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';

void main() {
  testWidgets('HomeScreen, SearchScreen, and CreateRoomScreen dispose without exceptions', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    expect(find.byType(SearchScreen), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: CreateRoomScreen()),
      ),
    );
    expect(find.byType(CreateRoomScreen), findsOneWidget);

    // Unmount all
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(CreateRoomScreen), findsNothing);
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận**

Run: `flutter test test/screens/lifecycle_and_dispose_test.dart`
Expected: PASS

- [ ] **Step 3: Bổ sung dispose() cho HomeScreen, StudentWaitingRoomScreen, CreateRoomScreen, ResetPasswordScreen, ProfileScreen, SearchScreen, CreateExamScreen**

1. **`lib/screens/home/home_screen.dart`:**
```dart
  @override
  void dispose() {
    _joinRoomController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
```

2. **`lib/screens/room/student_waiting_room_screen.dart`:**
```dart
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
```

3. **`lib/screens/room/create_room_screen.dart`:**
```dart
  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
```

4. **`lib/screens/auth/reset_password_screen.dart`:**
```dart
  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
```

5. **`lib/screens/profile/profile_screen.dart`:**
```dart
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
```

6. **`lib/screens/home/search_screen.dart`:**
```dart
  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
```

7. **`lib/screens/exam/create_exam_screen.dart`:**
```dart
  @override
  void dispose() {
    _examNameController.dispose();
    _durationController.dispose();
    super.dispose();
  }
```

- [ ] **Step 4: Chạy lại test và commit**

Run: `flutter test test/screens/lifecycle_and_dispose_test.dart`
Expected: PASS

```bash
git add lib/screens/home/home_screen.dart lib/screens/room/student_waiting_room_screen.dart lib/screens/room/create_room_screen.dart lib/screens/auth/reset_password_screen.dart lib/screens/profile/profile_screen.dart lib/screens/home/search_screen.dart lib/screens/exam/create_exam_screen.dart test/screens/lifecycle_and_dispose_test.dart
git commit -m "fix(lifecycle): implement strict dispose on all screens to eliminate memory leaks"
```

---

### Task 4: Tối ưu Polling Thông Minh & Bọc RepaintBoundary

**Files:**
- Modify: `lib/screens/room/student_waiting_room_screen.dart`
- Modify: `lib/screens/room/teacher_waiting_room_screen.dart`
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/shared/widgets/milky_mint_scaffold.dart`

- [ ] **Step 1: Thêm WidgetsBindingObserver vào StudentWaitingRoomScreen & TeacherWaitingRoomScreen**

Trong `student_waiting_room_screen.dart`:
```dart
class _StudentWaitingRoomScreenState extends State<StudentWaitingRoomScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pollingTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && !_isCountingDown) {
      _startPolling();
    }
  }
```

Trong `teacher_waiting_room_screen.dart`:
```dart
class _TeacherWaitingRoomScreenState extends State<TeacherWaitingRoomScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pollTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startPolling();
    }
  }
```

- [ ] **Step 2: Thêm RepaintBoundary quanh các thành phần hoạt ảnh trên HomeScreen & MilkyMintScaffold**

Trong `home_screen.dart`: Bọc thẻ card pulsing trong `RepaintBoundary`.
Trong `milky_mint_scaffold.dart`: Bọc `CustomPaint` / background mesh trong `RepaintBoundary`.

- [ ] **Step 3: Chạy test và commit**

Run: `flutter test`
Expected: ALL PASS

```bash
git add lib/screens/room/student_waiting_room_screen.dart lib/screens/room/teacher_waiting_room_screen.dart lib/screens/home/home_screen.dart lib/shared/widgets/milky_mint_scaffold.dart
git commit -m "perf(render): add lifecycle-aware smart polling and RepaintBoundary for 60/120 FPS"
```

---

### Task 5: Hoàn thiện Tính năng Chia Đều Điểm trong Tạo Đề Thi

**Files:**
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Modify: `lib/screens/exam/widgets/exam_right_sidebar.dart`
- Test: `test/screens/exam/widgets/exam_sidebars_test.dart`

- [ ] **Step 1: Cập nhật ExamRightSidebar hiển thị tổng điểm và nút chia đều điểm**

Chỉnh sửa `lib/screens/exam/widgets/exam_right_sidebar.dart`:
Thêm:
```dart
  final double totalPoints;
  final VoidCallback? onDistributePointsEvenly;
```
Và thêm Widget hiển thị điểm trong sidebar:
```dart
          // Points overview card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng điểm thang 10:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${totalPoints.toStringAsFixed(2)} đ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: (totalPoints - 10.0).abs() < 0.01 ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                if (onDistributePointsEvenly != null && questionCount > 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDistributePointsEvenly,
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Chia đều 10 điểm', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
```

- [ ] **Step 2: Truyền totalPoints và _distributePointsEvenly từ CreateExamScreen**

Trong `lib/screens/exam/create_exam_screen.dart`:
```dart
        ExamRightSidebar(
          examTitle: _examNameController.text,
          subject: _selectedSubject ?? '',
          durationMinutes: int.tryParse(_durationController.text) ?? 45,
          questionCount: _questions.length,
          totalPoints: _totalPoints,
          onDistributePointsEvenly: _distributePointsEvenly,
          perQuestionTimerEnabled: _perQuestionTimerEnabled,
          onTogglePerQuestionTimer: (val) => setState(() => _perQuestionTimerEnabled = val),
        ),
```

- [ ] **Step 3: Chạy test và commit**

Run: `flutter test test/screens/exam/widgets/exam_sidebars_test.dart`
Expected: PASS

```bash
git add lib/screens/exam/create_exam_screen.dart lib/screens/exam/widgets/exam_right_sidebar.dart test/screens/exam/widgets/exam_sidebars_test.dart
git commit -m "feat(create_exam): wire totalPoints and distributePointsEvenly into ExamRightSidebar"
```

---

### Task 6: Xóa Sạch 57 Cảnh Báo Linter, Nâng Cấp API Deprecated & Flow Control

**Files:**
- Modify: `lib/core/theme/app_theme.dart`
- Modify: `lib/shared/widgets/developer_log_overlay.dart`
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Modify: `lib/screens/exam/widgets/exam_left_sidebar.dart`
- Modify: `lib/screens/exam/widgets/exam_right_sidebar.dart`
- Modify: `lib/screens/exam/widgets/question_answers_editor.dart`
- Modify: `lib/core/repositories/assessment_repository.dart`
- Modify: `lib/core/repositories/room_repository.dart`
- Modify: `lib/shared/widgets/top_nav_bar.dart`
- Modify: `lib/screens/student/student_history_screen.dart`
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `test/` files

- [ ] **Step 1: Nâng cấp Deprecated APIs**
  - `app_theme.dart`: Sửa `ColorScheme.light` bỏ `background: background`, đổi `withOpacity` ➔ `withValues(alpha: 0.4)`.
  - `developer_log_overlay.dart`: Đổi 5 vị trí `withOpacity` ➔ `withValues(alpha: ...)`.
  - `create_exam_screen.dart`: Đổi `DropdownButtonFormField(value: ...)` ➔ `DropdownButtonFormField(initialValue: ...)`.
  - `exam_right_sidebar.dart`: `Switch(activeColor: ...)` ➔ `Switch(activeThumbColor: ...)`.
  - `question_answers_editor.dart`: Chuẩn hóa Radio không dùng deprecated members.

- [ ] **Step 2: Sửa Flow Control & Context Safety**
  - `assessment_repository.dart` & `room_repository.dart`: Thêm `{}` cho câu lệnh `if`.
  - `top_nav_bar.dart`: Thêm `if (!context.mounted) return;` sau `await devService.handleRoomCode(...)`.
  - `student_history_screen.dart:928, 936`: Đổi `if (item.durationFormatted != '--:--') Text(item.durationFormatted)` (loại bỏ `!` và `!= null`).
  - `home_screen.dart`: Xóa các biến trường không dùng `_activeExamId`, `_activeRoomId`, `_inProgressCount`.

- [ ] **Step 3: Dọn dẹp Wildcards và Test Unused Imports**
  - Đổi `(_, __)` ➔ `(_, _)` trong 18 vị trí.
  - Xóa unused imports và unused variables trong `test/`.

- [ ] **Step 4: Chạy flutter analyze để kiểm tra**

Run: `flutter analyze`
Expected: `No issues found! (0 issues)`

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "refactor(linter): resolve all 57 analyze warnings, modernize deprecated APIs and flow control"
```

---

### Task 7: Xác Minh Toàn Diện & Đồng Bộ Tài Liệu Hệ Thống

**Files:**
- Modify: `docs/system_architecture_and_deep_evaluation.md`

- [ ] **Step 1: Chạy toàn bộ test suite**

Run: `flutter test`
Expected: 100% tests pass (231+ tests)

- [ ] **Step 2: Chạy flutter analyze**

Run: `flutter analyze`
Expected: 0 issues found

- [ ] **Step 3: Cập nhật tài liệu system_architecture_and_deep_evaluation.md**

Cập nhật hiện trạng kiến trúc, cơ chế Zero-Leak lifecycle, Smart Polling và bảng phân tích lỗi đã được xử lý triệt để.

- [ ] **Step 4: Thực hiện Git Commit & Git Push**

```bash
git add docs/system_architecture_and_deep_evaluation.md
git commit -m "docs: sync system architecture with zero-leak performance and bugfix audit"
git push origin main
```
