# Dynamic User Profile & Registration State Design Spec

## Objective
Make user registration, login, profile screen, and home screen greeting completely dynamic based on user-entered Name and Email, eliminating static defaults ("Minh Anh", "minhanh@gmail.com").

## Detailed Requirements & State Flow

### 1. AuthProvider Improvements ([auth_provider.dart](file:///d:/thi_nhanh/lib/core/providers/auth_provider.dart))
- Store local properties `String? _userName` and `String? _userEmail`.
- Add getters:
  - `String get userName => _user?.userMetadata?['full_name'] as String? ?? _userName ?? 'Người dùng';`
  - `String get userEmail => _user?.email ?? _userEmail ?? 'chua_dang_ky@gmail.com';`
- In `signUpWithEmail(email, password, fullName)`:
  - Set `_userName = fullName`, `_userEmail = email`.
  - Trigger `notifyListeners()`.
- In `signInWithEmail(email, password)`:
  - Set `_userEmail = email`.
  - If `_userName` is null or empty, derive default name from email prefix (e.g. `email.split('@').first`).
  - Trigger `notifyListeners()`.
- Add `Future<void> updateProfile(String newName)` method to update `_userName = newName` and notify listeners.

### 2. Registration & Login Flow ([greeting_screen.dart](file:///d:/thi_nhanh/lib/screens/auth/greeting_screen.dart))
- In `_handleEmailRegister()`:
  - Validate name, email, password.
  - Call `authProvider.signUpWithEmail(email, password, name)`.
  - Show success message and immediately navigate to `/home` (or switch to login mode with prefilled credentials).

### 3. Screen Integration
- **[home_screen.dart](file:///d:/thi_nhanh/lib/screens/home/home_screen.dart)**:
  - Watch `AuthProvider`.
  - Display `'Chào mừng quay lại, ${authProvider.userName}'`.
- **[profile_screen.dart](file:///d:/thi_nhanh/lib/screens/profile/profile_screen.dart)**:
  - Watch `AuthProvider`.
  - Initialize Name and Gmail controllers from `authProvider.userName` and `authProvider.userEmail`.
  - Call `authProvider.updateProfile(newName)` on save.
- **[profile_dialog.dart](file:///d:/thi_nhanh/lib/shared/widgets/profile_dialog.dart)**:
  - Display `authProvider.userName` and `authProvider.userEmail`.

## Target Files
- `lib/core/providers/auth_provider.dart`: [MODIFY] Add `_userName`, `_userEmail`, `updateProfile`.
- `lib/screens/auth/greeting_screen.dart`: [MODIFY] Connect registration & auto-login flow.
- `lib/screens/home/home_screen.dart`: [MODIFY] Dynamic greeting name.
- `lib/screens/profile/profile_screen.dart`: [MODIFY] Dynamic name/email state and profile updates.
- `lib/shared/widgets/profile_dialog.dart`: [MODIFY] Dynamic name/email display.
