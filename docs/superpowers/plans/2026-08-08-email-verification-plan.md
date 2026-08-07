# Implementation Plan: Email Verification & Password Reset via Supabase Auth

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure user accounts are registered with real verified emails and password reset links/OTPs are sent directly to the user's email via Supabase Auth.

**Architecture:** Update `AuthProvider` to use Supabase Auth API (`signUp`, `resetPasswordForEmail`) with client-side email format regex validation, and update `GreetingScreen` to provide user guidance for email confirmation and password reset.

**Tech Stack:** Flutter, Dart, Supabase Auth (`supabase_flutter`), Provider.

## Global Constraints

- Email validation regex: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- Password minimum length: 6 characters
- Handle Supabase `AuthException` gracefully with clear Vietnamese user error messages.

---

### Task 1: Update AuthProvider with Email Verification & Password Reset

**Files:**
- Modify: `d:\thi_nhanh\lib\core\providers\auth_provider.dart:152-182`
- Test: `d:\thi_nhanh\test\providers\auth_provider_test.dart`

**Interfaces:**
- Consumes: Supabase Auth client (`_supabaseClient`)
- Produces: `signUpWithEmail(String email, String password, String fullName)`, `sendPasswordResetEmail(String email)`

- [ ] **Step 1: Write failing unit test for email validation in AuthProvider**

Create `d:\thi_nhanh\test\providers\auth_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';

void main() {
  group('AuthProvider Email Validation Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider(isSupabaseInitialized: false);
    });

    test('signUpWithEmail throws exception for invalid email format', () async {
      expect(
        () => authProvider.signUpWithEmail('invalid-email', '123456', 'Test User'),
        throwsA(isA<Exception>()),
      );
    });

    test('sendPasswordResetEmail throws exception for invalid email format', () async {
      expect(
        () => authProvider.sendPasswordResetEmail('invalid-email'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: FAIL because `sendPasswordResetEmail` is not defined and invalid email format exception is not thrown.

- [ ] **Step 3: Update AuthProvider implementation**

In `d:\thi_nhanh\lib\core\providers\auth_provider.dart`:

```dart
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  Future<void> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    final cleanEmail = email.trim();
    if (!isValidEmail(cleanEmail)) {
      throw Exception('Địa chỉ Email không hợp lệ.');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    final key = cleanEmail.toLowerCase();
    _registeredUsers[key] = {
      'name': fullName,
      'password': password,
    };

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {'full_name': fullName},
        );
        if (response.user != null) {
          _user = response.user;
        }
      } catch (e) {
        debugPrint('Lỗi đăng ký Supabase Email: $e');
        rethrow;
      }
    } else {
      _userEmail = cleanEmail;
      _userName = fullName;
      _userAvatarUrl = null;
    }

    await _saveState();
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (!isValidEmail(cleanEmail)) {
      throw Exception('Địa chỉ Email không hợp lệ.');
    }

    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.resetPasswordForEmail(cleanEmail);
      } catch (e) {
        debugPrint('Lỗi gửi email reset mật khẩu Supabase: $e');
        rethrow;
      }
    } else {
      final key = cleanEmail.toLowerCase();
      if (!_registeredUsers.containsKey(key)) {
        throw Exception('Email này chưa được đăng ký trong hệ thống.');
      }
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```powershell
git add lib/core/providers/auth_provider.dart test/providers/auth_provider_test.dart; git commit -m "feat(auth): add email regex validation and sendPasswordResetEmail in AuthProvider"
```

---

### Task 2: Update GreetingScreen UI with Real Email Verification & Forgot Password Handlers

**Files:**
- Modify: `d:\thi_nhanh\lib\screens\auth\greeting_screen.dart:70-153`

**Interfaces:**
- Consumes: `AuthProvider.signUpWithEmail()`, `AuthProvider.sendPasswordResetEmail()`, `AuthProvider.isValidEmail()`
- Produces: Updated Registration SnackBar/Dialog & Forgot Password handler with real API execution.

- [ ] **Step 1: Update GreetingScreen handlers**

In `d:\thi_nhanh\lib\screens\auth\greeting_screen.dart`:

```dart
  Future<void> _handleEmailRegister() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (password != confirmPassword) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signUpWithEmail(
            email,
            password,
            name,
          );
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read_outlined, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Xác thực Email'),
              ],
            ),
            content: Text(
              'Email xác thực đã được gửi tới $email.\nVui lòng kiểm tra hộp thư và mở liên kết xác nhận để kích hoạt tài khoản.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() => _isRegisterMode = false);
                },
                child: const Text('Đã hiểu, quay lại Đăng nhập'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _showError('Đăng ký thất bại: $msg');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Quên mật khẩu?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập địa chỉ email của bạn để nhận liên kết đặt lại mật khẩu.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Nhập email...',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final targetEmail = resetEmailController.text.trim();
                          if (targetEmail.isEmpty) {
                            _showError('Vui lòng nhập email');
                            return;
                          }
                          setDialogState(() => isSending = true);
                          try {
                            await context.read<AuthProvider>().sendPasswordResetEmail(targetEmail);
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              _showSuccess('Yêu cầu đã gửi! Vui lòng kiểm tra hộp thư email $targetEmail.');
                            }
                          } catch (e) {
                            final msg = e.toString().replaceAll('Exception: ', '');
                            _showError('Không thể gửi yêu cầu: $msg');
                          } finally {
                            if (mounted) setDialogState(() => isSending = false);
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Gửi yêu cầu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
```

- [ ] **Step 2: Verify Flutter build and run tests**

Run: `flutter analyze`
Expected: No issue found / 0 errors.

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```powershell
git add lib/screens/auth/greeting_screen.dart; git commit -m "feat(auth): update registration and forgot password dialogs with real email verification handling"
```
