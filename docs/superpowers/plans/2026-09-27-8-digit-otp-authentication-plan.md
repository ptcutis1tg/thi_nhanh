# 8-Digit OTP Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi toàn bộ hệ thống mã OTP đăng nhập và xác thực của ứng dụng Thi Nhanh từ mã 6 chữ số sang mã 8 chữ số, đồng bộ validation, giao diện UI, formatters và bộ kiểm thử tự động.

**Architecture:** Cập nhật tầng logic xác thực trong `AuthProvider` và `OTPMailer`, cập nhật giao diện người dùng kèm `FilteringTextInputFormatter.digitsOnly` và khoảng cách ký tự `letterSpacing: 6` trong `GreetingScreen` và `ResetPasswordScreen`, kiểm thử theo phương pháp TDD với `flutter test`.

**Tech Stack:** Flutter / Dart, Provider State Management, Supabase Flutter Auth, flutter_test.

## Global Constraints
- Chuẩn hóa mã OTP gồm đúng 8 chữ số (`length == 8` và `int.tryParse(otp) != null`).
- Ô nhập liệu giới hạn `maxLength: 8`, `hintText: '00000000'`, `letterSpacing: 6`, lọc chỉ cho phép chữ số với `FilteringTextInputFormatter.digitsOnly`.
- Thông báo lỗi tiếng Việt thân thiện: `"Vui lòng nhập đủ 8 chữ số mã OTP."`.
- Giữ nguyên toàn bộ logic đồng bộ hồ sơ `profiles` và các chức năng khác không liên quan.

---

### Task 1: Core Logic & Validation (AuthProvider & Unit Tests)

**Files:**
- Modify: `lib/core/providers/auth_provider.dart:220-235`, `lib/core/providers/auth_provider.dart:277-295`
- Test: `test/providers/auth_provider_test.dart:31-60`

**Interfaces:**
- Consumes: `AuthProvider.verifySignUpOTP(String email, String otpCode)`, `AuthProvider.verifyPasswordResetOTP(String email, String otpCode)`
- Produces: Xác thực chuỗi OTP chính xác 8 chữ số; ném ngoại lệ nếu độ dài khác 8 hoặc chứa ký tự không phải số.

- [ ] **Step 1: Write the failing tests**

Cập nhật file `test/providers/auth_provider_test.dart` để thêm các test case kiểm tra mã 6 số cũ (`'123456'`) phải bị từ chối, và mã 8 số (`'12345678'`) được chấp nhận:

```dart
    test('verifySignUpOTP throws exception for invalid OTP format', () async {
      expect(
        () => authProvider.verifySignUpOTP('valid@gmail.com', '123'),
        throwsA(isA<Exception>()),
      );
      // Mã 6 số cũ hiện tại phải bị từ chối vì hệ thống yêu cầu 8 số
      expect(
        () => authProvider.verifySignUpOTP('valid@gmail.com', '123456'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => authProvider.verifySignUpOTP('valid@gmail.com', 'abcdefgh'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => authProvider.verifySignUpOTP('valid@gmail.com', '123456789'),
        throwsA(isA<Exception>()),
      );
    });

    test('verifyPasswordResetOTP throws exception for invalid OTP format', () async {
      expect(
        () => authProvider.verifyPasswordResetOTP('test@gmail.com', '123'),
        throwsA(isA<Exception>()),
      );
      // Mã 6 số cũ hiện tại phải bị từ chối vì hệ thống yêu cầu 8 số
      expect(
        () => authProvider.verifyPasswordResetOTP('test@gmail.com', '123456'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => authProvider.verifyPasswordResetOTP('test@gmail.com', 'abcdefgh'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => authProvider.verifyPasswordResetOTP('test@gmail.com', '123456789'),
        throwsA(isA<Exception>()),
      );
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: FAIL vì mã `'123456'` hiện tại vẫn được coi là hợp lệ (độ dài 6).

- [ ] **Step 3: Implement minimal code to make tests pass**

Cập nhật `lib/core/providers/auth_provider.dart`:
Trong `verifySignUpOTP`:
```dart
  Future<AuthResponse?> verifySignUpOTP(String email, String otpCode) async {
    final cleanEmail = email.trim();
    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 8 || int.tryParse(cleanOtp) == null) {
      throw Exception('Mã OTP phải bao gồm đúng 8 chữ số.');
    }
```
Trong `verifyPasswordResetOTP`:
```dart
  Future<AuthResponse?> verifyPasswordResetOTP(String email, String otpCode) async {
    final cleanEmail = email.trim();
    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 8 || int.tryParse(cleanOtp) == null) {
      throw Exception('Mã OTP phải bao gồm đúng 8 chữ số.');
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/providers/auth_provider.dart test/providers/auth_provider_test.dart
git commit -m "feat(auth): enforce 8-digit OTP validation in AuthProvider"
```

---

### Task 2: Fallback Mailer Template Update (OTPMailer)

**Files:**
- Modify: `lib/core/utils/otp_mailer.dart:6-14`

**Interfaces:**
- Consumes: `OTPMailer.sendOTPEmail({required String recipientEmail, required String otpCode})`
- Produces: Gửi nội dung email dự phòng với thông điệp mã OTP 8 chữ số.

- [ ] **Step 1: Update comments and template text**

Cập nhật `lib/core/utils/otp_mailer.dart`:
```dart
  /// Gửi email chứa mã OTP 8 chữ số ngẫu nhiên trực tiếp tới hòm thư Gmail của người dùng (Không yêu cầu kích hoạt, không đường link)
  static Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final cleanEmail = recipientEmail.trim();
    final subjectText = 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode';
    final bodyText = 'Mã xác thực OTP 8 chữ số để khôi phục mật khẩu của bạn là: $otpCode\n\nMã này có hiệu lực trong 15 phút. Vui lòng nhập mã vào ứng dụng Thi Nhanh để hoàn tất.';
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/utils/otp_mailer.dart
git commit -m "chore(auth): update OTPMailer fallback template to 8 digits"
```

---

### Task 3: Sign-Up OTP Activation Dialog UI (GreetingScreen)

**Files:**
- Modify: `lib/screens/auth/greeting_screen.dart:650-785`

**Interfaces:**
- Consumes: `_SignUpOtpDialog` widget trong `GreetingScreen`
- Produces: Hộp thoại nhập mã OTP 8 chữ số kích hoạt đăng ký với `maxLength: 8`, `letterSpacing: 6`, `FilteringTextInputFormatter.digitsOnly`.

- [ ] **Step 1: Update validation logic in `_handleVerify`**

Trong `_SignUpOtpDialogState._handleVerify`:
```dart
  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 8 || int.tryParse(otp) == null) {
      setState(() => _errorMessage = 'Vui lòng nhập đủ 8 chữ số mã OTP.');
      return;
    }
```

- [ ] **Step 2: Update resend message in `_handleResend`**

Trong `_SignUpOtpDialogState._handleResend`:
```dart
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã OTP 8 số về hộp thư của bạn!'),
            backgroundColor: AppTheme.success,
          ),
        );
```

- [ ] **Step 3: Update Dialog description text**

```dart
              Text(
                'Mã xác thực gồm 8 chữ số đã được gửi tới email:\n${widget.email}\n(Vui lòng kiểm tra hộp thư đến và thư mục Spam/Rác)',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
```

- [ ] **Step 4: Update TextField attributes**

```dart
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                textAlign: TextAlign.center,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: '00000000',
                  hintStyle: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    letterSpacing: 6,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
```

- [ ] **Step 5: Verify analyze and test**

Run: `flutter analyze lib/screens/auth/greeting_screen.dart`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/auth/greeting_screen.dart
git commit -m "feat(ui): update sign-up OTP dialog to 8 digits with numeric formatter"
```

---

### Task 4: Reset Password Screen UI (ResetPasswordScreen)

**Files:**
- Modify: `lib/screens/auth/reset_password_screen.dart:100-345`

**Interfaces:**
- Consumes: `ResetPasswordScreen`
- Produces: Màn hình đặt lại mật khẩu với ô nhập OTP 8 chữ số, formatters và nhãn văn bản đồng bộ.

- [ ] **Step 1: Update `_handleSendOTP` success message**

```dart
        _showSuccess('Mã xác minh OTP 8 số đã được gửi về email $email. Vui lòng kiểm tra hộp thư!');
```

- [ ] **Step 2: Update `_handleVerifyOTP` validation**

```dart
  Future<void> _handleVerifyOTP() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 8) {
      _showError('Vui lòng nhập đủ 8 chữ số mã OTP.');
      return;
    }
```

- [ ] **Step 3: Update Step 1 description**

```dart
        const Text(
          'Nhập địa chỉ Email của bạn để nhận mã xác minh 8 chữ số khôi phục tài khoản.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
```

- [ ] **Step 4: Update Step 2 description & TextField**

```dart
        Text(
          'Mã xác minh 8 số đã được gửi tới email:\n${_emailController.text.trim()}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 8,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '00000000',
            counterText: '',
          ),
        ),
```

- [ ] **Step 5: Run flutter analyze and tests**

Run: `flutter analyze lib/screens/auth/reset_password_screen.dart`
Run: `flutter test`
Expected: 0 errors, all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/auth/reset_password_screen.dart
git commit -m "feat(ui): update reset password screen OTP input to 8 digits"
```

---

### Task 5: Walkthrough & Supabase Setup Guide Documentation

**Files:**
- Create: `docs/superpowers/walkthroughs/2026-09-27-8-digit-otp-walkthrough.md`

- [ ] **Step 1: Write detailed walkthrough document**

Ghi lại tóm tắt thay đổi, kết quả chạy kiểm thử, hình ảnh minh họa cách hiển thị 8 chữ số và hướng dẫn thiết lập bảng điều khiển Supabase Dashboard.

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/walkthroughs/2026-09-27-8-digit-otp-walkthrough.md
git commit -m "docs: add walkthrough for 8-digit OTP authentication system"
```
