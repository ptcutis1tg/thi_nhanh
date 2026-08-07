# Login Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the Flutter `GreetingScreen` UI layout and aesthetics to match the design mockup precisely.

**Architecture:** Update `lib/screens/auth/greeting_screen.dart` with refined layout properties, background gradient, wing slice overlays, card shadows, form inputs, SSO Google button, primary button, and action links.

**Tech Stack:** Flutter, Dart, Material Design 3.

## Global Constraints
- Target File: `lib/screens/auth/greeting_screen.dart`
- Preserve all existing state handling (`_isRegisterMode`, `_isLoading`, `_isPasswordObscured`, email/password login and register logic, Google login logic).
- No broken imports or syntax errors.

---

### Task 1: Refine GreetingScreen UI Layout & Aesthetics

**Files:**
- Modify: [greeting_screen.dart](file:///d:/thi_nhanh/lib/screens/auth/greeting_screen.dart)

**Interfaces:**
- Consumes: `AuthProvider`, `AppTheme`
- Produces: Updated `GreetingScreen` widget

- [ ] **Step 1: Inspect current GreetingScreen code structure**

Verify imports and line numbers in [greeting_screen.dart](file:///d:/thi_nhanh/lib/screens/auth/greeting_screen.dart).

- [ ] **Step 2: Update background gradient & side wing overlays**

Enhance the background container gradient (`#F4F0FF`, `#EBE5FF`, `#F7F4FF`) and side wings positioning (`login_bg.png`) with proper opacity and width factors.

- [ ] **Step 3: Update Main Container Card & Form Input aesthetics**

Update card shadow, border radius (`24px`), container padding, text styles, Google button pill border, divider lines, and text input decoration (`#F8FAFC` fill, `12px` border radius).

- [ ] **Step 4: Update Primary Action Button & Links**

Update `ElevatedButton` style to purple pill (`#8B72F6` / `#7C65F6`), guest link row, and toggle registration mode link.

- [ ] **Step 5: Verify build/analyze syntax**

Run: `flutter analyze` or check for Dart compilation errors.

- [ ] **Step 6: Commit changes**

```bash
git add lib/screens/auth/greeting_screen.dart docs/superpowers/plans/2026-08-07-login-screen-redesign.md
git commit -m "style: refine login screen layout and visual aesthetics"
```
