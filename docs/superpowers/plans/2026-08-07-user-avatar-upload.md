# User Avatar Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable users to pick an image from their device, store it as a base64 Data URL in `AuthProvider` (persisted in `SharedPreferences`), and render the custom avatar across ProfileScreen, TopNavBar, and ProfileDialog.

**Architecture:** Add `image_picker` dependency, add `_userAvatarUrl` & `updateAvatar` to `AuthProvider`, and update UI components to render memory images.

**Tech Stack:** Flutter, `image_picker`, `SharedPreferences`, Provider.

## Global Constraints
- Target Files: `pubspec.yaml`, `lib/core/providers/auth_provider.dart`, `lib/screens/profile/profile_screen.dart`, `lib/shared/widgets/top_nav_bar.dart`, `lib/shared/widgets/profile_dialog.dart`

---

### Task 1: Add Image Picker Dependency & AuthProvider Avatar State

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/providers/auth_provider.dart`

- [ ] **Step 1: Add image_picker to pubspec.yaml**
- [ ] **Step 2: Add avatar state and updateAvatar method to AuthProvider**
- [ ] **Step 3: Verify build syntax**

Run: `flutter analyze lib/core/providers/auth_provider.dart`

---

### Task 2: Implement Image Picker & Display on ProfileScreen, TopNavBar, and ProfileDialog

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/shared/widgets/top_nav_bar.dart`
- Modify: `lib/shared/widgets/profile_dialog.dart`

- [ ] **Step 1: Connect Camera Button to ImagePicker on ProfileScreen**
- [ ] **Step 2: Update TopNavBar to render userAvatarUrl**
- [ ] **Step 3: Update ProfileDialog to render userAvatarUrl**
- [ ] **Step 4: Verify build syntax across all modified files**

Run: `flutter analyze`

- [ ] **Step 5: Commit changes**

```bash
git add pubspec.yaml lib/core/providers/auth_provider.dart lib/screens/profile/profile_screen.dart lib/shared/widgets/top_nav_bar.dart lib/shared/widgets/profile_dialog.dart docs/superpowers/plans/2026-08-07-user-avatar-upload.md
git commit -m "feat: allow user avatar upload from device and display across profile and nav bar"
```
