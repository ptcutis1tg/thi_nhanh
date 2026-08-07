# Separate Profile Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a dedicated `/profile` screen in `lib/screens/profile/profile_screen.dart` displaying name, registered Gmail, edit profile fields, and change password section.

**Architecture:** Create `ProfileScreen` widget, register route `/profile` in `lib/main.dart`, and update `lib/shared/widgets/top_nav_bar.dart` avatar click handler to navigate to `/profile`.

**Tech Stack:** Flutter, GoRouter, Provider (`AuthProvider`), Material Design 3.

## Global Constraints
- Target Files: `lib/screens/profile/profile_screen.dart`, `lib/main.dart`, `lib/shared/widgets/top_nav_bar.dart`

---

### Task 1: Create ProfileScreen Widget

**Files:**
- Create: `lib/screens/profile/profile_screen.dart`

**Interfaces:**
- Consumes: `AuthProvider`, `AppTheme`
- Produces: `ProfileScreen` widget

- [ ] **Step 1: Write profile_screen.dart**

Create `ProfileScreen` with header, personal info form (name, registered email), change password form, and logout action.

- [ ] **Step 2: Verify syntax**

Run: `flutter analyze lib/screens/profile/profile_screen.dart`

---

### Task 2: Register /profile route & Connect Navigation

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/shared/widgets/top_nav_bar.dart`

**Interfaces:**
- Consumes: `ProfileScreen`
- Produces: `/profile` route & top navbar click handler

- [ ] **Step 1: Register /profile in lib/main.dart**

Add `/profile` GoRoute under `ShellRoute`. Update `_routeIndices` map.

- [ ] **Step 2: Update top_nav_bar.dart**

Change avatar `onTap` to `context.go('/profile')`.

- [ ] **Step 3: Verify build & analyze**

Run: `flutter analyze lib/main.dart lib/shared/widgets/top_nav_bar.dart`

- [ ] **Step 4: Commit changes**

```bash
git add lib/screens/profile/profile_screen.dart lib/main.dart lib/shared/widgets/top_nav_bar.dart docs/superpowers/plans/2026-08-07-profile-screen.md
git commit -m "feat: add dedicated profile screen with user info and password change form"
```
