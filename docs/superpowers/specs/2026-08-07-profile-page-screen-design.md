# Separate Profile Screen Design Spec

## Objective
Create a dedicated `/profile` screen in `lib/screens/profile/profile_screen.dart` to manage personal user details (Name, Registered Gmail, Password Change) with clean, modern UI styling matching the app theme.

## Specifications & Components

### 1. Routing & Access
- Add route `/profile` under `ShellRoute` in `lib/main.dart` so `TopNavBar` remains accessible.
- Update `top_nav_bar.dart` avatar click handler to navigate directly to `/profile` using `context.go('/profile')`.

### 2. Layout & Content Structure (`ProfileScreen`)
- **Header Section**:
  - Title: "Thông tin cá nhân & Tài khoản"
  - Breadcrumb / Subtitle: "Quản lý họ tên, Gmail đăng ký và mật khẩu của bạn"
- **Card 1: Thông tin tài khoản (Personal Information)**:
  - Avatar representation with edit badge.
  - **Họ và tên**: Input field initialized with current user name ("Minh Anh"), editable.
  - **Gmail đăng ký**: Input field initialized with registered email ("minhanh@gmail.com"), disabled/read-only with verified checkmark badge.
  - **Vai trò**: "Học sinh" / "Người dùng".
  - Action: "Lưu thay đổi thông tin".
- **Card 2: Thay đổi mật khẩu (Change Password)**:
  - **Mật khẩu hiện tại**: Password input with visibility toggle.
  - **Mật khẩu mới**: Password input with visibility toggle.
  - **Xác nhận mật khẩu mới**: Password input with visibility toggle.
  - Action: "Cập nhật mật khẩu mới".
- **Card 3: Quản lý tài khoản**:
  - Action button: "Đăng xuất tài khoản" (Clears session & redirects to `/greeting`).

## File Changes
- `lib/screens/profile/profile_screen.dart`: [NEW] Profile Screen widget.
- `lib/main.dart`: [MODIFY] Register `/profile` route in `ShellRoute`.
- `lib/shared/widgets/top_nav_bar.dart`: [MODIFY] Change avatar `onTap` to `context.go('/profile')`.
