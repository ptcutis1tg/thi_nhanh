# User Profile Popup Card Design Spec

## Objective
Add an interactive Profile Popup Menu / Modal Dialog triggered when clicking the user avatar icon in [top_nav_bar.dart](file:///d:/thi_nhanh/lib/shared/widgets/top_nav_bar.dart).

## Design & Component Specifications

### 1. Avatar Click Trigger
- In `TopNavBar` ([top_nav_bar.dart](file:///d:/thi_nhanh/lib/shared/widgets/top_nav_bar.dart)), wrap the `CircleAvatar` in an `InkWell` or `GestureDetector`.
- On click, open a sleek Popover Card / Dialog displaying the current user profile.

### 2. Profile Card Content (`ProfileDialog` / `ProfileMenuWidget`)
- **Header Section**:
  - Large Avatar with initials or user photo icon.
  - Display Name (fetched from `AuthProvider` or fallback "Minh Anh").
  - Email address (fetched from `AuthProvider` or fallback "minhanh@gmail.com").
  - User Role Badge ("Học sinh" / "Người dùng").
- **Quick Statistics**:
  - 2 Stat Counters: "12 Bài đã làm" | "5 Phòng thi".
- **Action List**:
  - 👤 **Chỉnh sửa thông tin**: Opens edit name/avatar modal.
  - 🔑 **Đổi mật khẩu**: Opens change password modal dialog.
  - 🚪 **Đăng xuất**: Signs out user using `AuthProvider.signOut()` and navigates to `/greeting`.

### 3. File Structure
- `lib/shared/widgets/profile_dialog.dart`: New widget for the profile popup dialog/card.
- [top_nav_bar.dart](file:///d:/thi_nhanh/lib/shared/widgets/top_nav_bar.dart): Update avatar to open `ProfileDialog`.
