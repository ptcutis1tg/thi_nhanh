# Native 6-Digit OTP Authentication System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Thi Nhanh authentication into a 100% Native Supabase Auth architecture using 6-digit OTP verification for both Sign-Up and Forgot Password (no confirmation links, no 404s), eliminate plain-text passwords and local user storage, purge legacy role code, and polish the guest experience.

**Architecture:** Flutter client communicates directly with Supabase Auth (Gotrue SDK). All verification operations (sign-up confirmation and password recovery) use 6-digit numeric OTP tokens (`OtpType.signup` and `OtpType.recovery`). User state and profiles synchronize cleanly with `public.profiles` without vestigial role distinctions.

**Tech Stack:** Flutter 3.x, Dart 3.x, `supabase_flutter: ^2.16.0`, `provider`, `go_router`, PostgreSQL / Supabase RLS.

## Global Constraints
- No confirmation links (`{{ .ConfirmationURL }}`) — all verification flows must use 6-digit OTP codes.
- No plain-text passwords or simulated user accounts in `SharedPreferences`.
- Single unified user role — purge `UserRole` and `activeRole` from `AuthProvider`.
- Every feature completion must run tests, git commit, and git push per user rule.

---

### Task 1: Database Migration — Secure and Revoke Open Access on `user_otps`

**Files:**
- Create: `supabase/migrations/202609270001_secure_user_otps.sql`

**Interfaces:**
- Produces: Revocation of public read/write policy on `public.user_otps`.

- [ ] **Step 1: Write the migration SQL file**

```sql
-- Migration: Revoke public access to user_otps table
-- Native Supabase Auth manages OTPs directly; public access must be removed.

drop policy if exists "Allow read write for user_otps" on public.user_otps;

-- Restrict all access so anonymous users cannot read or overwrite OTPs
create policy "No public access for user_otps" on public.user_otps
  for all using (false) with check (false);
```

- [ ] **Step 2: Commit and push migration**

```powershell
git add supabase/migrations/202609270001_secure_user_otps.sql
git commit -m "security: revoke public read-write policy on user_otps table"
git push
```

---

### Task 2: Fast & Local Email Verification in `EmailVerifier`

**Files:**
- Modify: `lib/core/utils/email_verifier.dart`
- Create: `test/core/utils/email_verifier_test.dart`

**Interfaces:**
- Produces: `EmailVerifier.verifyEmail(String email)` (instant synchronous validation, 0 external network requests).

- [ ] **Step 1: Write failing unit test**

Create `test/core/utils/email_verifier_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/email_verifier.dart';

void main() {
  group('EmailVerifier Tests', () {
    test('accepts valid standard email addresses', () async {
      expect(() => EmailVerifier.verifyEmail('student@gmail.com'), returnsNormally);
      expect(() => EmailVerifier.verifyEmail('teacher.math@edu.vn'), returnsNormally);
    });

    test('rejects invalid email formats', () async {
      expect(() => EmailVerifier.verifyEmail('invalid-email'), throwsException);
      expect(() => EmailVerifier.verifyEmail('test@'), throwsException);
      expect(() => EmailVerifier.verifyEmail('@domain.com'), throwsException);
    });

    test('rejects disposable/trash email domains', () async {
      expect(() => EmailVerifier.verifyEmail('fake@yopmail.com'), throwsException);
      expect(() => EmailVerifier.verifyEmail('trash@tempmail.com'), throwsException);
      expect(() => EmailVerifier.verifyEmail('user@10minutemail.com'), throwsException);
    });
  });
}
```

- [ ] **Step 2: Run test to verify failure or need for update**

Run: `flutter test test/core/utils/email_verifier_test.dart`

- [ ] **Step 3: Implement clean local `EmailVerifier`**

Replace `lib/core/utils/email_verifier.dart` with:
```dart
class EmailVerifier {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static const Set<String> _disposableDomains = {
    'yopmail.com',
    'mailinator.com',
    'tempmail.com',
    'tempmail.net',
    'tempmail.org',
    'guerrillamail.com',
    'dispostable.com',
    '10minutemail.com',
    'trashmail.com',
    'sharklasers.com',
    'getnada.com',
    'maildrop.cc',
    'fakeinbox.com',
    'throwawaymail.com',
    'byom.de',
    'crazymailing.com',
    'boun.cr',
    'mohmal.com',
    'burnermail.io',
  };

  /// Kiểm tra định dạng email và loại trừ tên miền email rác/tạm thời
  static void verifyEmail(String email) {
    final cleanEmail = email.trim();

    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Địa chỉ Email không đúng định dạng (Ví dụ: name@gmail.com).');
    }

    final parts = cleanEmail.split('@');
    if (parts.length != 2) {
      throw Exception('Địa chỉ Email không hợp lệ.');
    }

    final domain = parts[1].toLowerCase();
    if (_disposableDomains.contains(domain)) {
      throw Exception('Vui lòng không sử dụng Email rác hoặc Email tạm thời.');
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/email_verifier_test.dart`
Expected: ALL PASS.

- [ ] **Step 5: Commit and push**

```powershell
git add lib/core/utils/email_verifier.dart test/core/utils/email_verifier_test.dart
git commit -m "feat(auth): streamline EmailVerifier with fast local regex and disposable blacklist"
git push
```

---

### Task 3: Refactor `AuthProvider` to Native Supabase Auth & Session Management

**Files:**
- Modify: `lib/core/providers/auth_provider.dart`
- Modify: `test/providers/auth_provider_test.dart`

**Interfaces:**
- Consumes: `Supabase.instance.client.auth`, `EmailVerifier.verifyEmail`
- Produces:
  - `signUpWithEmail(email, password, fullName)` -> calls `signUp`
  - `verifySignUpOTP(email, otpCode)` -> calls `verifyOTP(type: OtpType.signup)`
  - `sendPasswordResetOTP(email)` -> calls `resetPasswordForEmail`
  - `verifyPasswordResetOTP(email, otpCode)` -> calls `verifyOTP(type: OtpType.recovery)`
  - `updateNewPassword(newPassword)` -> calls `updateUser(UserAttributes(password: newPassword))`
  - `changePassword(currentPassword, newPassword)` -> reauth + update
  - `isGoogleUser` getter
  - Purged: `UserRole`, `_activeRole`, `_registeredUsers`, `_localOTPs`

- [ ] **Step 1: Update unit tests in `test/providers/auth_provider_test.dart`**

Set up `SharedPreferences.setMockInitialValues({})` in `setUp()` so tests run cleanly without plugin exceptions. Write tests for OTP input format validation, email format checking, and password length checks.

- [ ] **Step 2: Run test to verify failures**

Run: `flutter test test/providers/auth_provider_test.dart`

- [ ] **Step 3: Implement updated `AuthProvider`**

In `lib/core/providers/auth_provider.dart`:
- Clean up constructor and state.
- Implement `signUpWithEmail`, `verifySignUpOTP`, `sendPasswordResetOTP`, `verifyPasswordResetOTP`, `updateNewPassword`, `changePassword`.
- Remove legacy role fields and plain-text passwords in SharedPreferences.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/auth_provider_test.dart`
Expected: ALL PASS.

- [ ] **Step 5: Commit and push**

```powershell
git add lib/core/providers/auth_provider.dart test/providers/auth_provider_test.dart
git commit -m "feat(auth): refactor AuthProvider to native Supabase 6-digit OTP and secure session management"
git push
```

---

### Task 4: Update `ResetPasswordScreen` to Native OTP Recovery Flow

**Files:**
- Modify: `lib/screens/auth/reset_password_screen.dart`

**Interfaces:**
- Consumes: `AuthProvider.sendPasswordResetOTP`, `AuthProvider.verifyPasswordResetOTP`, `AuthProvider.updateNewPassword`
- Produces: 3-step password recovery UI without links or local user dependencies.

- [ ] **Step 1: Refactor `_handleSendOTP()` in `ResetPasswordScreen`**
Call `context.read<AuthProvider>().sendPasswordResetOTP(email)`.

- [ ] **Step 2: Refactor `_handleVerifyOTP()` in `ResetPasswordScreen`**
Call `context.read<AuthProvider>().verifyPasswordResetOTP(email, otp)`.

- [ ] **Step 3: Refactor `_handleUpdatePassword()` in `ResetPasswordScreen`**
Call `context.read<AuthProvider>().updateNewPassword(newPassword)`.

- [ ] **Step 4: Run analyze/test to verify correctness**

Run: `flutter test test/providers/auth_provider_test.dart`

- [ ] **Step 5: Commit and push**

```powershell
git add lib/screens/auth/reset_password_screen.dart
git commit -m "feat(auth): wire ResetPasswordScreen to native Supabase 6-digit OTP recovery"
git push
```

---

### Task 5: Upgrade `GreetingScreen` with 6-Digit OTP Sign-Up Dialog & Vietnamese Errors

**Files:**
- Modify: `lib/screens/auth/greeting_screen.dart`

**Interfaces:**
- Consumes: `AuthProvider.signUpWithEmail`, `AuthProvider.verifySignUpOTP`
- Produces: Sign-up with 6-digit OTP input step (no confirmation links).

- [ ] **Step 1: Add OTP Verification State & Modal to `GreetingScreen`**
Add state variables:
```dart
bool _isAwaitingSignUpOtp = false;
final TextEditingController _signUpOtpController = TextEditingController();
int _signUpCountdown = 60;
Timer? _signUpTimer;
```
If `signUpWithEmail` indicates confirmation is needed, show 6-digit OTP modal / view instead of error.

- [ ] **Step 2: Implement `_handleVerifySignUpOtp()`**
Call `await context.read<AuthProvider>().verifySignUpOTP(email, otp)`.
On success: show success snackbar and navigate to `/home`.

- [ ] **Step 3: Update `_friendlyAuthErrorMessage()`**
Translate `invalid_credentials`, `user_already_exists`, `over_email_send_rate_limit`, `otp_expired` to clear Vietnamese messages. Remove old prompt saying to click email link.

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`

- [ ] **Step 5: Commit and push**

```powershell
git add lib/screens/auth/greeting_screen.dart
git commit -m "feat(auth): add 6-digit OTP verification dialog for sign-up and friendly error translations"
git push
```

---

### Task 6: Secure Profile Password Change & Google OAuth Badge in `ProfileScreen`

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`

**Interfaces:**
- Consumes: `AuthProvider.isGoogleUser`, `AuthProvider.changePassword`

- [ ] **Step 1: Check Google provider in `ProfileScreen`**
If `authProvider.isGoogleUser`, hide old/new password text fields and display an informative badge:
`Tài khoản liên kết Google — Mật khẩu và bảo mật được quản lý trực tiếp qua tài khoản Google.`

- [ ] **Step 2: Connect `_handleChangePassword()` to updated `changePassword()`**
Display appropriate error/success messages.

- [ ] **Step 3: Run flutter analyze and tests**

Run: `flutter test`

- [ ] **Step 4: Commit and push**

```powershell
git add lib/screens/profile/profile_screen.dart
git commit -m "feat(profile): secure password change with reauth and add Google OAuth account indicator"
git push
```

---

### Task 7: Enhance `TopNavBar` for Guests with "Đăng nhập" Pill & Soft-Gated Modals

**Files:**
- Modify: `lib/shared/widgets/top_nav_bar.dart`

**Interfaces:**
- Consumes: `AuthProvider.isAuthenticated`
- Produces:
  - "Đăng nhập" button when unauthenticated.
  - Soft-gate dialog for authoring actions when unauthenticated.

- [ ] **Step 1: Render "Đăng nhập" button when unauthenticated**
In `TopNavBar`, if `!authProvider.isAuthenticated`, render:
```dart
OutlinedButton.icon(
  onPressed: () => context.go('/greeting'),
  icon: const Icon(Icons.login_rounded, size: 16),
  label: const Text('Đăng nhập'),
  ...
)
```

- [ ] **Step 2: Add soft-gate dialog on restricted menu items**
If guest clicks 'Tạo đề thi', 'Đề của tôi', 'Tạo phòng thi', or profile, present:
`showDialog(...)` inviting them to log in, with buttons `[Để sau]` and `[Đăng nhập ngay]`.

- [ ] **Step 3: Run flutter analyze and tests**

Run: `flutter test`

- [ ] **Step 4: Commit and push**

```powershell
git add lib/shared/widgets/top_nav_bar.dart
git commit -m "feat(ui): add guest login button and soft-gate modal dialog to TopNavBar"
git push
```

---

### Task 8: End-to-End Verification & Documentation Walkthrough

**Files:**
- Test all components: `flutter test`
- Create walkthrough: `docs/superpowers/walkthroughs/2026-09-27-native-otp-authentication-walkthrough.md`

- [ ] **Step 1: Run full test suite**
Run: `flutter test`
Verify: All unit & integration tests pass with 0 errors.

- [ ] **Step 2: Create walkthrough documentation**
Document how OTP signup and recovery work, and document Supabase Email Template settings.

- [ ] **Step 3: Commit and push**

```powershell
git add docs/
git commit -m "docs: add walkthrough for native 6-digit OTP authentication system"
git push
```
