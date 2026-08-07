# User Profile Popup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an interactive Profile Dialog widget and hook it up to the user avatar in `TopNavBar`.

**Architecture:** Create `lib/shared/widgets/profile_dialog.dart` containing user info, statistics, edit options, and sign-out logic. Update `lib/shared/widgets/top_nav_bar.dart` to trigger `ProfileDialog`.

**Tech Stack:** Flutter, Provider (`AuthProvider`), Material Design 3.

## Global Constraints
- Target Files: `lib/shared/widgets/profile_dialog.dart`, `lib/shared/widgets/top_nav_bar.dart`
- Support user auth state fallback ("Minh Anh" default user info if unauthenticated or guest).

---

### Task 1: Create ProfileDialog Widget

**Files:**
- Create: `lib/shared/widgets/profile_dialog.dart`

**Interfaces:**
- Consumes: `AuthProvider`, `AppTheme`
- Produces: `ProfileDialog` widget

- [ ] **Step 1: Write profile_dialog.dart**

Create `ProfileDialog` widget displaying avatar, name, email, role badge, statistics, edit profile dialog action, change password action, and sign-out button.

- [ ] **Step 2: Verify syntax**

Run: `flutter analyze lib/shared/widgets/profile_dialog.dart`

---

### Task 2: Connect TopNavBar Avatar to ProfileDialog

**Files:**
- Modify: `lib/shared/widgets/top_nav_bar.dart`

**Interfaces:**
- Consumes: `ProfileDialog`
- Produces: Updated `TopNavBar` with clickable avatar

- [ ] **Step 1: Wrap CircleAvatar with InkWell / GestureDetector**

In `top_nav_bar.dart`, add `onTap` handler calling `showDialog(context: context, builder: (_) => const ProfileDialog())`.

- [ ] **Step 2: Verify build & analyze**

Run: `flutter analyze lib/shared/widgets/top_nav_bar.dart`

- [ ] **Step 3: Commit changes**

```bash
git add lib/shared/widgets/profile_dialog.dart lib/shared/widgets/top_nav_bar.dart docs/superpowers/plans/2026-08-07-user-profile-popup.md
git commit -m "feat: add user profile popup dialog and connect avatar click handler"
```
