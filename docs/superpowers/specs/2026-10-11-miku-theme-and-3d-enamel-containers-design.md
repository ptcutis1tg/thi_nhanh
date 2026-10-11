# Design Specification: Hatsune Miku Color Theme & 3D Enamel Container System

**Date:** 2026-10-11  
**Status:** Validated & Ready for Planning  
**Target Applications:** `thi_nhanh` (Web & Mobile Flutter Application)

---

## 1. Mục tiêu & Tổng Quan Thiết Kế

Đổi mới giao diện ứng dụng **Thi Nhanh** theo chuẩn thiết kế hiện đại từ bản mockup 7 màn hình kết hợp với hệ màu thương hiệu **Hatsune Miku (Cyber-Aqua & Mint)**:
1. **Màu sắc (Miku Cyber-Teal & Pale Mint):** Thay thế tông tím cũ bằng dải màu Miku (`#39C5BB`, `#00A896`, `#00E5FF`, điểm xuyết Magenta `#E84188`).
2. **Container & Background System (Enamel 3D & Milky Mint Canvas):** Nền trắng sữa ánh bạc hà `#F4FAF9`, thẻ card trắng sứ `#FFFFFF` bo tròn đa tầng (32px, 24px, 16px, 100px), viền siêu mảnh 1px hairline và hiệu ứng đổ bóng phát quang ngọc bích (*Aqua Luminescence*).
3. **Tương tác PC Hover Micro-Interactions (Zero Mobile Overhead):** Trên PC/Desktop, các nút và thẻ chức năng khi di chuột (`MouseRegion`) sẽ nhấc nhẹ lên 2-3px, sáng hơn và tăng độ đổ bóng/phát quang; trên mobile cảm ứng không kích hoạt hiệu ứng này, đảm bảo 0% giật lag.
4. **Hiệu Năng Cao Cấp (Zero-Lag / 60–120 FPS):** Không sử dụng `BackdropFilter` thời gian thực nặng tải GPU; giả lập kính mờ (Simulated Glassmorphism) bằng màu trắng sứ độ mờ cao kết hợp viền mờ và đổ bóng khuếch tán.

---

## 2. Hệ Thống Design Tokens (`AppTheme`)

### 2.1 Bảng Màu Miku Theme
```dart
class AppTheme {
  // Miku Cyber-Aqua Palette
  static const Color primary = Color(0xFF39C5BB);          // Miku Vivid Aqua (Chủ đạo)
  static const Color primaryDark = Color(0xFF00A896);      // Deep Cyber Teal (Hover / Gradient End)
  static const Color primaryDarker = Color(0xFF008080);    // Solid Teal
  static const Color primaryLight = Color(0xFF7FE3DB);     // Soft Cyan Glow
  static const Color primaryContainer = Color(0xFFE6FAF8); // Pale Miku Mint (Pill/Tag background)
  static const Color primarySubtle = Color(0xFFF0FDFB);    // Tinted Surface
  
  // Accents & Contrast
  static const Color accentMagenta = Color(0xFFE84188);    // Miku Pink Accent (Badges, Highlight ribbons)
  static const Color accentCyan = Color(0xFF00F0FF);       // Neon Electric Cyan
  
  // Canvas & Surfaces
  static const Color background = Color(0xFFF4FAF9);       // Milky Mint Canvas (Nền đa tầng)
  static const Color surface = Color(0xFFFFFFFF);          // Enamel Pure White (Card trắng sứ)
  static const Color surfaceMuted = Color(0xFFF8FCFC);     // Secondary Surface
  
  // Typography Colors
  static const Color textMain = Color(0xFF1E293B);         // Deep Slate Ink (Độ tương phản cao)
  static const Color textSecondary = Color(0xFF64748B);    // Muted Slate
  static const Color textPlaceholder = Color(0xFF94A3B8);  // Hint
  
  // Borders
  static const Color border = Color(0xFFE2EFEF);           // 1px Hairline Border
  static const Color borderFocused = Color(0xFF39C5BB);    // Focus Border
  static const Color borderSubtle = Color(0x1A39C5BB);     // Translucent Border
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
```

### 2.2 Phân Cấp Bo Góc (`BorderRadius`)
* **Shell / Window Outer Radius:** `32.0` (Khung bao cửa sổ lớn hoặc Modal lớn).
* **Hero / Feature Banner Radius:** `24.0` (Khối chào mừng, Banner trang chủ, Thẻ thống kê giáo viên).
* **Standard Card Radius:** `16.0` (Đề thi, danh mục môn học, danh sách phòng thi).
* **Input / Form Radius:** `12.0` (Ô nhập liệu, dropdown chọn đề).
* **Capsule Pill Radius:** `100.0` (Tất cả các nút hành động, filter pills, badge trạng thái).

### 2.3 Hệ Thống Đổ Bóng (`BoxShadow`)
* **Card Shadow (Thẻ tĩnh):**
  ```dart
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F2B28),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  ```
* **Luminescence Shadow (Phát quang ngọc bích - Trạng thái Active/Chủ đạo):**
  ```dart
  static const List<BoxShadow> luminescenceShadow = [
    BoxShadow(
      color: Color(0x2839C5BB),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];
  ```
* **PC Hover Glow Shadow (Đổ bóng khi trỏ chuột trên PC):**
  ```dart
  static const List<BoxShadow> hoverGlowShadow = [
    BoxShadow(
      color: Color(0x3D39C5BB),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 1,
    ),
  ];
  ```

---

## 3. Cơ Chế Tương Tác PC Micro-Hover (Zero Mobile Overhead)

### 3.1 Widget Tương Tác `AppInteractiveHoverCard`
* Sử dụng `MouseRegion` và `AnimatedContainer(duration: Duration(milliseconds: 160), curve: Curves.easeOutCubic)`.
* **Khi chuột di vào (`onEnter` trên PC):**
  - Translate lên trên: `transform: Matrix4.translationValues(0, -2.5, 0)`.
  - Nâng cấp đổ bóng: chuyển sang `hoverGlowShadow`.
  - Tăng độ sáng viền: `Border.all(color: AppTheme.primary, width: 1.2)`.
* **Khi chuột rời đi (`onExit`):** Trở về vị trí và đổ bóng mặc định.
* **Trên Mobile (Touch Devices):** Do thiết bị cảm ứng không có con trỏ hover liên tục, `MouseRegion` không sinh sự kiện giả, giữ widget ở trạng thái tĩnh tuyệt đối, tránh hiện tượng dính trạng thái (sticky hover) và không tốn chu kỳ tính toán.

### 3.2 Tối Ưu Nút Bấm `ElevatedButtonTheme` & `OutlinedButtonTheme`
* Nút bấm sử dụng `WidgetStateProperty.resolveWith`:
  - `hovered`: Tự động tăng `elevation: 4`, đổi màu nền sáng hơn một bậc (`Color(0xFF45D0C6)`).
  - Mặc định: `elevation: 0`, màu nền chính `AppTheme.primary`.

---

## 4. Cấu Trúc Nền Đa Tầng Không Lag (`MilkyMintScaffold`)

* Cung cấp một widget nền chuẩn `AppScaffold` / `AppMeshBackground`:
  1. Lớp đáy: `Color(0xFFF4FAF9)` phủ toàn màn hình.
  2. Lớp đốm sáng Ambient Glow: Một khối `DecoratedBox` với `RadialGradient(colors: [Color(0x1839C5BB), Colors.transparent])` ở góc trên bên phải, được bọc trong `RepaintBoundary` cố định để không vẽ lại khi nội dung cuộn bên dưới.
  3. Không sử dụng bất kỳ `BackdropFilter` nào gây nghẽn raster GPU.

---

## 5. Phạm Vi Màn Hình Được Refactor

1. **`GreetingScreen`:** Form đăng nhập/chào mừng phong cách thẻ sứ nổi trên nền Milky Mint, nút Google & Đăng nhập bo tròn capsule viên thuốc Miku.
2. **`HomeScreen`:** Banner Hero gradient Miku (`#39C5BB` -> `#00A896`), các thẻ thống kê chuỗi/điểm trung bình, danh mục 8 môn học dạng capsule icon 3D.
3. **`TeacherExamsScreen` / Teacher Dashboard:** 4 khối quản lý nghiệp vụ lớn với màu chủ đạo Cyber-Aqua/Blue/Purple/Amber viền 1px, bảng đề thi phân trang tinh gọn.
4. **`CreateRoomScreen` & `JoinRoomScreen`:** Form tạo phòng thi trực tuyến với các pill chọn số lượng thí sinh (30, 40, 50, 100), công tắc switch mật khẩu màu Miku, thẻ QR code hiển thị rõ nét.
5. **`TopNavBar` & `MobileBottomNavBar`:** Thanh điều hướng trên nền kính trắng sứ viền mỏng, item active phát quang Miku Teal.

---

## 6. Chiến Lược Kiểm Thử & Đảm Bảo Chất Lượng

1. **Kiểm thử Theme & Tokens (`app_theme_test.dart`):** Kiểm tra đầy đủ mã màu Miku, bán kính bo góc, đổ bóng và typography.
2. **Kiểm thử Tương tác Hover (`hover_card_test.dart`):** Mô phỏng sự kiện `PointerEnterEvent` / `PointerExitEvent` để xác minh translation và shadow thay đổi chính xác.
3. **Kiểm thử Giao diện Không Lỗi Overflow:** Chạy bộ test toàn diện 219+ bài kiểm tra trên cả viewport di động (360x640) và máy tính (1440x900).
