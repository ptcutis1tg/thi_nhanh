# Implementation Plan: 3-Step OTP Reset Password Screen

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a dedicated 3-step OTP password reset screen (`/reset-password`) where users enter their email, receive a 6-digit OTP code, verify it in-app, and set a new password.

**Architecture:** Create `ResetPasswordScreen` with step wizard state, extend `AuthProvider` with `verifyPasswordResetOTP` and `updateNewPassword`, and wire routing in `main.dart` and `greeting_screen.dart`.

**Tech Stack:** Flutter, Dart, Supabase Auth (`verifyOTP`, `updateUser`), Provider, GoRouter.

## Global Constraints

- Password minimum length: 6 characters
- 6-digit numeric OTP validation
- 60-second countdown timer for OTP resend
- Clear Vietnamese error messages for invalid/expired OTP

---

### Task 1: Extend AuthProvider with OTP Verification and Password Update

**Files:**
- Modify: `d:\thi_nhanh\lib\core\providers\auth_provider.dart`
- Modify: `d:\thi_nhanh\test\providers\auth_provider_test.dart`

**Interfaces:**
- Consumes: Supabase Auth (`verifyOTP`, `updateUser`)
- Produces: `verifyPasswordResetOTP(String email, String otpCode)`, `updateNewPassword(String email, String newPassword)`

- [ ] **Step 1: Write unit tests for AuthProvider OTP verification & password update**

Update `d:\thi_nhanh\test\providers\auth_provider_test.dart`:

```dart
    test('verifyPasswordResetOTP throws exception for invalid OTP format', () async {
      expect(
        () => authProvider.verifyPasswordResetOTP('test@gmail.com', '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateNewPassword throws exception for short password', () async {
      expect(
        () => authProvider.updateNewPassword('test@gmail.com', '123'),
        throwsA(isA<Exception>()),
      );
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: FAIL because `verifyPasswordResetOTP` and `updateNewPassword` are not yet implemented.

- [ ] **Step 3: Implement AuthProvider methods**

In `d:\thi_nhanh\lib\core\providers\auth_provider.dart`:

```dart
  Future<void> verifyPasswordResetOTP(String email, String otpCode) async {
    final cleanEmail = email.trim();
    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      throw Exception('Mã OTP phải bao gồm đúng 6 chữ số.');
    }

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.verifyOTP(
          email: cleanEmail,
          token: cleanOtp,
          type: OtpType.recovery,
        );
        if (response.user != null) {
          _user = response.user;
        }
      } catch (e) {
        debugPrint('Lỗi xác nhận mã OTP Supabase: $e');
        throw Exception('Mã OTP không chính xác hoặc đã hết hạn. Vui lòng thử lại.');
      }
    }
  }

  Future<void> updateNewPassword(String email, String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    final key = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(key)) {
      _registeredUsers[key]!['password'] = newPassword;
    } else {
      _registeredUsers[key] = {
        'name': userName,
        'password': newPassword,
      };
    }

    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (e) {
        debugPrint('Lỗi cập nhật mật khẩu Supabase: $e');
        rethrow;
      }
    }

    await _saveState();
    notifyListeners();
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```powershell
git add lib/core/providers/auth_provider.dart test/providers/auth_provider_test.dart; git commit -m "feat(auth): add verifyPasswordResetOTP and updateNewPassword methods in AuthProvider"
```

---

### Task 2: Create ResetPasswordScreen & Wire Routing

**Files:**
- Create: `d:\thi_nhanh\lib\screens\auth\reset_password_screen.dart`
- Modify: `d:\thi_nhanh\lib\screens\auth\greeting_screen.dart`
- Modify: `d:\thi_nhanh\lib\main.dart`

**Interfaces:**
- Consumes: `AuthProvider.sendPasswordResetEmail()`, `AuthProvider.verifyPasswordResetOTP()`, `AuthProvider.updateNewPassword()`
- Produces: Route `/reset-password` and 3-step OTP password reset UI flow.

- [ ] **Step 1: Create ResetPasswordScreen widget**

Create `d:\thi_nhanh\lib\screens\auth\reset_password_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  int _currentStep = 1;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  int _resendCountdown = 60;
  Timer? _timer;

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Vui lòng nhập địa chỉ Email.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(email);
      if (mounted) {
        _showSuccess('Mã OTP đã được gửi về email $email');
        setState(() => _currentStep = 2);
        _startCountdown();
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showError('Vui lòng nhập đủ 6 chữ số mã OTP.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().verifyPasswordResetOTP(email, otp);
      if (mounted) {
        _showSuccess('Xác thực mã OTP thành công!');
        setState(() => _currentStep = 3);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpdatePassword() async {
    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError('Vui lòng nhập mật khẩu mới.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('Mật khẩu xác nhận không khớp.');
      return;
    }
    if (newPassword.length < 6) {
      _showError('Mật khẩu mới phải có ít nhất 6 ký tự.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().updateNewPassword(email, newPassword);
      if (mounted) {
        _showSuccess('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.');
        context.go('/greeting');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/clean_login_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF1EDFE), Color(0xFFE5DEFF), Color(0xFFF6F3FF)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentStep == 1
                                  ? 'Quên mật khẩu'
                                  : _currentStep == 2
                                      ? 'Nhập mã OTP'
                                      : 'Mật khẩu mới',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_currentStep == 1) _buildStep1Email(),
                        if (_currentStep == 2) _buildStep2OTP(),
                        if (_currentStep == 3) _buildStep3NewPassword(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Email() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nhập địa chỉ Email của bạn để nhận mã xác minh 6 chữ số khôi phục tài khoản.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Nhập email...',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSendOTP,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Gửi mã OTP xác nhận'),
        ),
      ],
    );
  }

  Widget _buildStep2OTP() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mã xác minh 6 số đã được gửi tới email:\n${_emailController.text.trim()}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _resendCountdown > 0 || _isLoading ? null : _handleSendOTP,
              child: Text(
                _resendCountdown > 0 ? 'Gửi lại mã ($_resendCountdown s)' : 'Gửi lại mã OTP',
                style: TextStyle(
                  color: _resendCountdown > 0 ? AppTheme.textSecondary : AppTheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Đổi Email'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerifyOTP,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Xác thực mã OTP'),
        ),
      ],
    );
  }

  Widget _buildStep3NewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tạo mật khẩu mới cho tài khoản của bạn.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _newPasswordController,
          obscureText: _isNewPasswordObscured,
          decoration: InputDecoration(
            hintText: 'Mật khẩu mới (tối thiểu 6 ký tự)...',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isNewPasswordObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isNewPasswordObscured = !_isNewPasswordObscured),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _isConfirmPasswordObscured,
          decoration: InputDecoration(
            hintText: 'Xác nhận mật khẩu mới...',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdatePassword,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Cập nhật mật khẩu'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Update GreetingScreen forgot password handler**

In `d:\thi_nhanh\lib\screens\auth\greeting_screen.dart`:

```dart
  void _handleForgotPassword() {
    context.push('/reset-password');
  }
```

- [ ] **Step 3: Register `/reset-password` route in main.dart**

In `d:\thi_nhanh\lib\main.dart`:

Import: `import 'screens/auth/reset_password_screen.dart';`
Add route to `GoRouter`:

```dart
  GoRoute(
    path: '/reset-password',
    builder: (context, state) => const ResetPasswordScreen(),
  ),
```

- [ ] **Step 4: Verify Flutter build and run tests**

Run: `flutter analyze`
Expected: 0 errors.

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```powershell
git add lib/screens/auth/reset_password_screen.dart lib/screens/auth/greeting_screen.dart lib/main.dart; git commit -m "feat(auth): add dedicated 3-step OTP reset password screen and route"
```
