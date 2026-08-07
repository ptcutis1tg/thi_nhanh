# Login Screen Redesign Design Spec

## Objective
Refine and polish the login screen (`GreetingScreen`) in `lib/screens/auth/greeting_screen.dart` to match the target UI design mockup accurately across responsive screen sizes (Web, Tablet, Mobile).

## UI Specifications & Components

### 1. Background & Decorative Elements
- **Base Canvas**: Linear gradient background from `#F4F0FF` to `#EBE5FF` to `#F7F4FF`.
- **Side Wings (Flying Books Background)**:
  - Position left and right background wing slices using `assets/images/login_bg.png` with gentle opacity/clipping and responsive width.
  - Smooth fade masks on screen edges so that on wider screens, the decorative elements seamlessly blend into the background.

### 2. Main Login Card Container
- **Card Styling**:
  - Background: White (`#FFFFFF`)
  - Border Radius: `24px`
  - Max Width: `440px`
  - Internal Padding: `40px` horizontal, `36px` vertical (responsive padding on mobile: `24px` horizontal, `28px` vertical).
  - Shadow: Soft multi-layered shadow with subtle purple glow tint (`blurRadius: 32`, offset `(0, 12)`, opacity `0.06`).

### 3. Header & Google SSO Button
- **Header**:
  - Title: "Đăng nhập" / "Đăng ký" (`fontSize: 28`, `fontWeight: FontWeight.w800`, `#1E293B`).
  - Subtitle: "Chào mừng bạn quay lại với Thi Nhanh" (`fontSize: 14`, `#64748B`).
- **Google Sign-In Button**:
  - Outlined button with rounded pill shape (`borderRadius: 100`).
  - Border: 1px `#E2E8F0`.
  - Icon: Google multi-color SVG/Canvas painter logo (`18x18px`).
  - Text: "Continue with Google" (`fontSize: 14`, `fontWeight: FontWeight.w600`, `#1E293B`).

### 4. Divider & Form Inputs
- **Divider**:
  - Text: "HOẶC ĐĂNG NHẬP BẰNG EMAIL" (`fontSize: 11`, `fontWeight: FontWeight.w600`, `#94A3B8`, letter spacing `0.6`).
- **Input Fields (Email & Password)**:
  - Fill Color: `#F8FAFC` (soft gray container).
  - Border Radius: `12px`.
  - Labels: "Email", "Mật khẩu" (`fontSize: 14`, `fontWeight: FontWeight.w600`, `#1E293B`).
  - Forgot Password Link: "Quên mật khẩu?" (`fontSize: 13`, `#7C65F6`, `fontWeight: FontWeight.w500`).
  - Suffix Icon: Eye icon for password toggle (`#94A3B8`).

### 5. Primary Action Button & Auxiliary Links
- **Primary Button**:
  - Label: "Đăng nhập" / "Đăng ký"
  - Background: Primary accent purple (`#8B72F6` / `#7C65F6`).
  - Shape: Rounded pill (`borderRadius: 100`).
  - Text: `fontSize: 15`, `fontWeight: FontWeight.w700`, White color.
- **Guest Link**:
  - Row with exit/login icon + "Thi ngay với mã phòng (Guest)".
- **Toggle Mode Link**:
  - "Chưa có tài khoản? Đăng ký ngay" with highlight link.

## Target File
- [greeting_screen.dart](file:///d:/thi_nhanh/lib/screens/auth/greeting_screen.dart)
