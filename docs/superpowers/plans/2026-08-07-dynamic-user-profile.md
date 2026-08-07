# Dynamic User Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Store user name and email dynamically during registration/login in `AuthProvider` and reflect changes across HomeScreen, ProfileScreen, and ProfileDialog.

**Architecture:** Update `AuthProvider` state handling, update `GreetingScreen` signup flow, update `HomeScreen` greeting, and connect `ProfileScreen` edit actions.

**Tech Stack:** Flutter, Provider (`AuthProvider`), Material Design 3.

## Global Constraints
- Target Files: `lib/core/providers/auth_provider.dart`, `lib/screens/auth/greeting_screen.dart`, `lib/screens/home/home_screen.dart`, `lib/screens/profile/profile_screen.dart`, `lib/shared/widgets/profile_dialog.dart`

---

### Task 1: Update AuthProvider Profile State

**Files:**
- Modify: `lib/core/providers/auth_provider.dart`

- [ ] **Step 1: Add _userName, _userEmail, getters, and updateProfile method**

Add `_userName`, `_userEmail`, update `signUpWithEmail` and `signInWithEmail`, and add `updateProfile`.

- [ ] **Step 2: Verify syntax**

Run: `flutter analyze lib/core/providers/auth_provider.dart`

---

### Task 2: Connect GreetingScreen Registration & Auto Navigation

**Files:**
- Modify: `lib/screens/auth/greeting_screen.dart`

- [ ] **Step 1: Update _handleEmailRegister()**

Store name and email in `AuthProvider` upon successful signup and navigate to `/home`.

- [ ] **Step 2: Verify syntax**

Run: `flutter analyze lib/screens/auth/greeting_screen.dart`

---

### Task 3: Update HomeScreen, ProfileScreen, and ProfileDialog

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/shared/widgets/profile_dialog.dart`

- [ ] **Step 1: Update HomeScreen greeting**

Use `authProvider.userName` in `HomeScreen` title.

- [ ] **Step 2: Update ProfileScreen & ProfileDialog**

Use `authProvider.userName` and `authProvider.userEmail` dynamically and connect `_handleSaveProfile` to `authProvider.updateProfile`.

- [ ] **Step 3: Verify build across all modified files**

Run: `flutter analyze`

- [ ] **Step 4: Commit changes**

```bash
git add lib/core/providers/auth_provider.dart lib/screens/auth/greeting_screen.dart lib/screens/home/home_screen.dart lib/screens/profile/profile_screen.dart lib/shared/widgets/profile_dialog.dart docs/superpowers/plans/2026-08-07-dynamic-user-profile.md
git commit -m "feat: make registration name, gmail, home greeting, and profile screen dynamic"
```
