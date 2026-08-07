# User Avatar Upload Design Spec

## Objective
Allow users to pick an image file from their local device (PC/Mobile/Web), set it as their account avatar, persist it per account in `SharedPreferences`, and display it across `ProfileScreen`, `TopNavBar`, and `ProfileDialog`.

## Detailed Requirements & Architecture

### 1. Dependency Updates
- Add `image_picker: ^1.1.2` to `pubspec.yaml`.

### 2. AuthProvider Avatar Storage ([auth_provider.dart](file:///d:/thi_nhanh/lib/core/providers/auth_provider.dart))
- Add `String? _userAvatarUrl`.
- Add getter `String? get userAvatarUrl => _userAvatarUrl;`.
- Add method `Future<void> updateAvatar(String avatarDataUrl)`:
  - Updates `_userAvatarUrl = avatarDataUrl`.
  - Updates `_registeredUsers[key]['avatar'] = avatarDataUrl`.
  - Saves to `SharedPreferences` (`active_user_avatar` & `local_registered_users`).
  - Calls `notifyListeners()`.
- Update `signInWithEmail` and `signUpWithEmail` to restore/set `_userAvatarUrl`.
- Update `signOut` to clear active `_userAvatarUrl`.

### 3. Image Picker Helper Integration ([profile_screen.dart](file:///d:/thi_nhanh/lib/screens/profile/profile_screen.dart))
- When user clicks camera icon button or Avatar on `ProfileScreen`:
  - Call `ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85)`.
  - Read bytes from selected image file `await image.readAsBytes()`.
  - Convert to base64 Data URL string: `data:image/png;base64,${base64Encode(bytes)}`.
  - Pass string to `authProvider.updateAvatar(dataUrl)`.

### 4. Avatar UI Rendering
- **[profile_screen.dart](file:///d:/thi_nhanh/lib/screens/profile/profile_screen.dart)**:
  - If `authProvider.userAvatarUrl` is present, decode base64 bytes and render `MemoryImage(bytes)`.
  - Otherwise render fallback icon.
- **[top_nav_bar.dart](file:///d:/thi_nhanh/lib/shared/widgets/top_nav_bar.dart)**:
  - Watch `AuthProvider`.
  - If `authProvider.userAvatarUrl` is present, render `CircleAvatar(backgroundImage: MemoryImage(bytes))`.
- **[profile_dialog.dart](file:///d:/thi_nhanh/lib/shared/widgets/profile_dialog.dart)**:
  - Render avatar image if `authProvider.userAvatarUrl` is present.

## Target Files
- `pubspec.yaml`: [MODIFY] Add `image_picker: ^1.1.2`.
- `lib/core/providers/auth_provider.dart`: [MODIFY] Add avatar state, getter, and `updateAvatar`.
- `lib/screens/profile/profile_screen.dart`: [MODIFY] Connect camera button to `ImagePicker` and display avatar image.
- `lib/shared/widgets/top_nav_bar.dart`: [MODIFY] Display avatar image in top navigation bar.
- `lib/shared/widgets/profile_dialog.dart`: [MODIFY] Display avatar image in profile dialog.
