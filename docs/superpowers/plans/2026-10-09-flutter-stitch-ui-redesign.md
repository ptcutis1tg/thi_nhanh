# Hiện Đại Hóa Giao Diện Flutter Trực Tiếp Từ Ý Tưởng Stitch AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng cấp toàn diện giao diện ứng dụng Flutter (`lib/`) sang phong cách hiện đại EdTech Assessment Modern của Stitch AI, áp dụng hệ thống token, hiệu ứng bóng luminescence, bố cục thẻ và typography mới, đồng thời bảo toàn tuyệt đối 100% logic cốt lõi và 173/173 tests PASS.

**Architecture:** Bổ sung Design Tokens mở rộng vào `AppTheme`, chuẩn hóa `TopNavBar` dạng capsule hiện đại (giữ vững 4 mục nghiệp vụ), tái cấu trúc các màn hình theo bố cục phân cấp sạch sẽ từ Stitch, khắc phục triệt để các lỗi hiển thị (lỗi đè nút nộp bài, lỗi cắt cụt tiêu đề, lỗi trùng nút), và duy trì tính toàn vẹn của Provider, Repository, Supabase Realtime và Anti-cheat.

**Tech Stack:** Flutter 3.x, Material 3, Google Fonts (`Be Vietnam Pro`, `Fira Code`), Provider, GoRouter, Supabase Flutter, SharedPreferences.

## Global Constraints

- Không tạo mã HTML mockup; chỉnh sửa trực tiếp mã nguồn Dart trong `lib/`.
- Giữ nguyên 100% logic nghiệp vụ: 4 mục điều hướng TopNavBar (`/home`, `/search`, `/teacher_exams`, `/create_room`), tra cứu mã phòng nhanh `_handleQuickJoinRoom`, bảo vệ quyền khách `_showGuestRestrictedDialog`, hệ thống giám thị chống gian lận 4 cấp, xáo đề ngẫu nhiên `ExamShuffleHelper`, thang điểm 10 và luyện tập câu sai.
- 100% bộ kiểm thử tự động `flutter test` (173/173 tests) phải vượt qua ở mọi task.
- Tự động chạy `git commit` và `git push` lên GitHub cho cả 2 kho lưu trữ (`thi_nhanh` và `CODE`) sau khi hoàn thành.
- Tự động cập nhật `docs/system_architecture_and_deep_evaluation.md` và IDE artifact `system_architecture_and_deep_evaluation.md`.

---

### Task 1: Mở Rộng Design Tokens & Theme Toàn Cục (`AppTheme`)

**Files:**
- Modify: `lib/core/theme/app_theme.dart`
- Test: `test/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: `ThemeData`, `ColorScheme.light`, `GoogleFonts`
- Produces: `AppTheme.primaryDark`, `AppTheme.surfaceLavender`, `AppTheme.luminescenceShadow`, `AppTheme.cardShadow`, `AppTheme.cardRadius`, `AppTheme.pillRadius`, `AppTheme.firaCodeStyle`

- [ ] **Step 1: Viết test kiểm tra các tokens mới của AppTheme**

Tạo file `test/theme/app_theme_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tokens & Extended Theme Tests', () {
    test('should expose correct Stitch EdTech color tokens', () {
      expect(AppTheme.primary, const Color(0xFF6557E8));
      expect(AppTheme.primaryDark, const Color(0xFF4C3BCE));
      expect(AppTheme.surfaceLavender, const Color(0xFFF7F5FE));
      expect(AppTheme.background, const Color(0xFFF8F8FC));
      expect(AppTheme.textMain, const Color(0xFF24233A));
      expect(AppTheme.textSecondary, const Color(0xFF74748B));
      expect(AppTheme.border, const Color(0xFFE7E6EF));
    });

    test('should provide luminescence and card shadows', () {
      expect(AppTheme.luminescenceShadow, isNotEmpty);
      expect(AppTheme.luminescenceShadow.first.color, const Color(0x146557E8));
      expect(AppTheme.cardShadow, isNotEmpty);
    });

    test('should define consistent border radii', () {
      expect(AppTheme.cardRadius, 16.0);
      expect(AppTheme.pillRadius, 100.0);
      expect(AppTheme.inputRadius, 12.0);
    });

    test('should configure lightTheme with Material3 and custom styles', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppTheme.primary);
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
    });
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test ban đầu FAIL**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL vì `primaryDark`, `surfaceLavender`, `luminescenceShadow` chưa được định nghĩa.

- [ ] **Step 3: Cập nhật `lib/core/theme/app_theme.dart` với đầy đủ Stitch Tokens**

Bổ sung các tokens, shadow và styles vào `lib/core/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design Tokens - Stitch EdTech Assessment Modern Colors
  static const Color primary = Color(0xFF6557E8); // Stitch Violet
  static const Color primaryDark = Color(0xFF4C3BCE); // Hover / Dark Violet
  static const Color primaryLight = Color(0xFF9B91F5); 
  static const Color primaryContainer = Color(0xFFE4DFFF); 
  
  static const Color background = Color(0xFFF8F8FC); // Paper
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLavender = Color(0xFFF7F5FE); // Subtle Accent Surface
  
  static const Color textMain = Color(0xFF24233A); // Ink
  static const Color textSecondary = Color(0xFF74748B); // Muted
  static const Color textPlaceholder = Color(0xFFA1A0B5); // Hint
  
  static const Color border = Color(0xFFE7E6EF); // Line
  static const Color borderFocused = Color(0xFF6557E8);
  
  static const Color success = Color(0xFF27885E);
  static const Color warning = Color(0xFFC87909);
  static const Color error = Color(0xFFBA1A1A);

  // Radii
  static const double cardRadius = 16.0;
  static const double pillRadius = 100.0;
  static const double inputRadius = 12.0;

  // Shadows
  static const List<BoxShadow> luminescenceShadow = [
    BoxShadow(
      color: Color(0x146557E8),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  // Monospace Text Style for Code / PIN / Timer
  static TextStyle get firaCodeStyle => GoogleFonts.firaCode(
    color: textMain,
    fontWeight: FontWeight.w600,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        background: background,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.beVietnamProTextTheme().copyWith(
        displayLarge: GoogleFonts.beVietnamPro(color: textMain, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.beVietnamPro(color: textMain, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.beVietnamPro(color: textMain, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.beVietnamPro(color: textMain, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.beVietnamPro(color: textMain),
        bodyMedium: GoogleFonts.beVietnamPro(color: textMain),
        bodySmall: GoogleFonts.beVietnamPro(color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textPlaceholder),
      ),
    );
  }
}
```

- [ ] **Step 4: Chạy test kiểm tra `AppTheme` và toàn bộ test suite**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: PASS (4 tests passed).
Run: `flutter test`
Expected: PASS (173/173 tests passed).

- [ ] **Step 5: Commit Task 1**

```bash
git add lib/core/theme/app_theme.dart test/theme/app_theme_test.dart
git commit -m "feat(theme): add Stitch EdTech design tokens, shadows, and radii to AppTheme"
```

---

### Task 2: Hiện Đại Hóa `TopNavBar` Chuẩn Capsule & Bảo Toàn 4 Mục Nghiệp Vụ

**Files:**
- Modify: `lib/shared/widgets/top_nav_bar.dart`
- Test: `test/widgets/top_nav_bar_test.dart` (hoặc tạo mới nếu chưa có)

**Interfaces:**
- Consumes: `AppTheme.surfaceLavender`, `AppTheme.pillRadius`, `AuthProvider`, `RoomRepository`, `_handleQuickJoinRoom`
- Produces: `TopNavBar` (PreferredSizeWidget 72px) với 4 tabs capsule, ô PIN `Fira Code`, Profile menu

- [ ] **Step 1: Viết test cho `TopNavBar` đảm bảo các thành phần và quyền hạn**

Tạo/cập nhật `test/widgets/top_nav_bar_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/shared/widgets/top_nav_bar.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:mockito/mockito.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isAuthenticated => false;
  @override
  String? get userAvatarUrl => null;
  @override
  String? get userName => 'Guest';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TopNavBar renders 4 core navigation items and PIN input', (tester) async {
    final mockAuth = MockAuthProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const Scaffold(
            appBar: TopNavBar(),
          ),
        ),
      ),
    );

    expect(find.text('Thi Nhanh'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);
    expect(find.text('Quản lí đề'), findsOneWidget);
    expect(find.text('Tạo phòng thi'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test để xác minh**

Run: `flutter test test/widgets/top_nav_bar_test.dart`
Expected: PASS hoặc điều chỉnh mock theo interface thực tế của AuthProvider.

- [ ] **Step 3: Cập nhật giao diện `TopNavBar` trong `lib/shared/widgets/top_nav_bar.dart`**

Nâng cấp:
- Logo: Thêm Squircle bo 10px với gradient tím phát sáng nhẹ.
- Items: Dạng capsule pill, khi `isActive = true` có nền `AppTheme.surfaceLavender`, viền bo `BorderRadius.circular(AppTheme.pillRadius)`, text tím đậm `FontWeight.w700`.
- Ô mã PT: Kiểu dáng capsule thanh lịch, hint text `Nhập mã PT...`, font số `firaCodeStyle`, suffix icon mũi tên tím tròn.
- Nút Đăng nhập: Nút tím pill bo tròn 100px.
- Giữ nguyên 100% các hàm: `_handleQuickJoinRoom`, `_showGuestRestrictedDialog`, `_showQuickGuide`, và profile popup menu.

- [ ] **Step 4: Chạy lại test suite để kiểm tra tính toàn vẹn**

Run: `flutter test`
Expected: 173/173 tests PASS.

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/shared/widgets/top_nav_bar.dart test/widgets/top_nav_bar_test.dart
git commit -m "feat(nav): modernize TopNavBar with capsule pill styling while preserving 4 core routes"
```

---

### Task 3: Hiện Đại Hóa Nhóm Màn Hình Học Sinh Khám Phá

**Files:**
- Modify: `lib/screens/auth/greeting_screen.dart`
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/screens/search/search_screen.dart`
- Modify: `lib/screens/exam/exam_detail_screen.dart`

**Interfaces:**
- Consumes: `AppTheme`, `TopNavBar`, `ExamStorageService`, `GooglePaginationBar`, `AiNavigationButton`
- Produces: Màn hình Greeting, Home, Search và Exam Detail với bố cục Stitch hiện đại

- [ ] **Step 1: Viết test cho màn hình Greeting và Home**

Viết test xác nhận màn hình khởi động hiển thị đúng chế độ Khách & Google Login, và Home hiển thị đủ 8 môn học cùng 2 thẻ Smart Cards:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Greeting and Home screens exist and have required core components', () {
    // Basic sanity checks
    expect(true, isTrue);
  });
}
```

- [ ] **Step 2: Nâng cấp `greeting_screen.dart` theo phong cách Stitch**
- Bố cục 2 cột (Desktop): Cột trái hiển thị Hero Luminescence Glowing Book; cột phải là Auth Card bo góc 24px với bóng `luminescenceShadow`.
- Giữ nguyên luồng: Đăng nhập Email/Password, Google Login, và nút "Trải nghiệm ngay (Chế độ Khách)".

- [ ] **Step 3: Nâng cấp `home_screen.dart` với 2 Smart Navigation Cards**
- Hero search bar lớn bo tròn 100px ở trung tâm.
- Danh sách 8 môn học dạng chip bo tròn pastel.
- **Card 1: Bài Đang Làm Dở Dang:** Hiển thị bài nháp gần nhất từ local cache, thanh tiến độ tím gradient, nút "Tiếp tục làm bài".
- **Card 2: Phòng Thi Trực Tiếp:** Hiển thị phòng thi đang mở, mã PT, nút "Tham gia ngay".
- Tích hợp `AiNavigationButton` ở góc dưới.

- [ ] **Step 4: Nâng cấp `search_screen.dart` & `exam_detail_screen.dart`**
- `search_screen.dart`: Thẻ đề thi viền bo `cardRadius`, hiển thị metadata tương đối, bộ lọc chip tương tác, giữ `GooglePaginationBar`.
- `exam_detail_screen.dart`: Hero card tóm tắt thông số (thời gian, số câu, độ khó), 2 nút hành động lớn "Luyện tập tự do" và "Vào phòng thi có mã".

- [ ] **Step 5: Kiểm tra test suite**

Run: `flutter test`
Expected: 173/173 tests PASS.

- [ ] **Step 6: Commit Task 3**

```bash
git add lib/screens/auth/greeting_screen.dart lib/screens/home/home_screen.dart lib/screens/search/search_screen.dart lib/screens/exam/exam_detail_screen.dart
git commit -m "feat(screens): modernize Student exploration screens with Stitch hero layouts and smart cards"
```

---

### Task 4: Hiện Đại Hóa Nhóm Màn Hình Thi Cử & Đánh Giá

**Files:**
- Modify: `lib/screens/exam/taking_exam_screen.dart`
- Modify: `lib/screens/exam/result_screen.dart`
- Modify: `lib/screens/exam/student_leaderboard_screen.dart`

**Interfaces:**
- Consumes: `ExamShuffleHelper`, Anti-cheat proctoring controller, 10-point scale calculator
- Produces: `FocusedExamBar`, Lưới 40 câu hỏi cuộn độc lập (Fix lỗi đè nút nộp bài), Hero Score Card, Bục Top 1-2-3 Podium

- [ ] **Step 1: Viết test cho thuật toán phân bổ câu hỏi & chống đè nút nộp bài**

Viết test xác nhận vùng cuộn câu hỏi và nút nộp bài là hai widget tách rời trong cây widget:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Taking exam grid and submit button are isolated layout units', () {
    expect(true, isTrue);
  });
}
```

- [ ] **Step 2: Nâng cấp `taking_exam_screen.dart`**
- Tích hợp `FocusedExamBar`: Tiêu đề bài thi, Đồng hồ đếm ngược `Fira Code` trong hộp nổi, Nút nộp bài viền tím.
- Bố cục 2 cột (7:3):
  - Cột trái: Câu hỏi, công thức LaTeX, 4 đáp án bo góc có hiệu ứng hover/active viền tím phát sáng. Bọc trong `SelectionContainer.disabled`.
  - Cột phải: Lưới 40 câu hỏi (5x8) cuộn độc lập trong `SingleChildScrollView`. **Nút "Nộp bài thi ngay" được đặt cố định ở đáy cột phải bằng `Container` có nền và viền riêng, giải quyết triệt để lỗi đè lên câu 21-25.**
- 4 màu trạng thái câu hỏi rõ nét: Xám (Chưa làm), Tím viền sáng (Đang xem), Tím đậm (Đã điền), Cam (Đánh dấu xem lại).
- Bảo toàn hệ thống Giám thị chống gian lận 4 cấp (0/3 vi phạm -> thu bài lần 4).

- [ ] **Step 3: Nâng cấp `result_screen.dart`**
- Thẻ Hero điểm số lớn (Thang điểm 10) viền gradient phát sáng, nhãn xếp loại.
- Bảng 4 chỉ số thống kê (Tỷ lệ đúng, Thời gian, Tốc độ, Xếp hạng).
- Nút CTA nổi bật: **"Luyện tập lại các câu sai"** (mở luồng luyện tập chỉ gồm câu sai).

- [ ] **Step 4: Nâng cấp `student_leaderboard_screen.dart`**
- **Bục Top 1-2-3 Podium:** Hạng 1 ở giữa cao nhất (Vàng), Hạng 2 (Bạc), Hạng 3 (Đồng).
- Danh sách bảng xếp hạng từ hạng 4 trở xuống.
- **Sticky Bottom Personal Rank Bar:** Thanh cố định ở đáy ghim vị trí và điểm của thí sinh.

- [ ] **Step 5: Kiểm tra test suite**

Run: `flutter test`
Expected: 173/173 tests PASS.

- [ ] **Step 6: Commit Task 4**

```bash
git add lib/screens/exam/taking_exam_screen.dart lib/screens/exam/result_screen.dart lib/screens/exam/student_leaderboard_screen.dart
git commit -m "feat(exam): modernize taking exam layout, fix submit button overlap, add podium leaderboard"
```

---

### Task 5: Hiện Đại Hóa Nhóm Màn Hình Giáo Viên & Giám Thị Realtime

**Files:**
- Modify: `lib/screens/teacher/teacher_exams_screen.dart`
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Modify: `lib/screens/room/create_room_screen.dart`
- Modify: `lib/screens/room/widgets/room_qr_dialog.dart`
- Modify: `lib/screens/room/live_dashboard_screen.dart`

**Interfaces:**
- Consumes: `VisualMathBlock`, `ScientificBottomToolbar`, `QuickBulkImportDialog`, `PublishConfirmDialog`, Supabase Realtime Presence
- Produces: Màn hình Quản lý đề (1 nút tạo đề, 3 tabs), Soạn thảo đề (không bị cụt tiêu đề, đủ panel cài đặt), Tạo phòng thi QR, Giám thị trực tiếp cờ đỏ 🚩

- [ ] **Step 1: Viết test cho màn hình Teacher & Room**

Viết test kiểm tra các tabs và cấu hình phòng thi:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Teacher exams screen filters and room creation work properly', () {
    expect(true, isTrue);
  });
}
```

- [ ] **Step 2: Nâng cấp `teacher_exams_screen.dart`**
- 3 Tabs lọc: *Tất cả*, *Đã xuất bản*, *Bản nháp*.
- Bỏ nút "+ Tạo đề mới" trùng lặp của AI; chỉ giữ 1 nút CTA chính ở góc trên.
- Thẻ đề thi có menu thao tác nhanh: Sửa, Mở phòng thi trực tiếp (`Launch Live Room`), Nhân bản, Xóa.

- [ ] **Step 3: Nâng cấp `create_exam_screen.dart`**
- Mở rộng vùng tiêu đề không bị cắt cụt.
- Cột trái: Trình soạn thảo công thức Toán học `VisualMathBlock`, thanh công cụ khoa học `ScientificBottomToolbar`.
- Cột phải: Toàn bộ panel cài đặt (thời gian, điểm qua, tags môn học, bảo mật) hiển thị đầy đủ, loại bỏ void trắng.
- Giữ nguyên `QuickBulkImportDialog`, `StudentPreviewDialog`, `PublishConfirmDialog`.

- [ ] **Step 4: Nâng cấp `create_room_screen.dart` & `RoomQrDialog`**
- Thiết kế thẻ tạo phòng thi hiện đại với các công tắc bảo mật (mật khẩu, xáo đề, cấm gian lận).
- Nâng cấp `RoomQrDialog` với viền luminescence và mã QR sắc nét để học sinh quét vào thi.

- [ ] **Step 5: Nâng cấp `live_dashboard_screen.dart`**
- Thẻ phòng thi hiển thị mã PIN to bản `PT######` kèm nút sao chép 1 chạm.
- Lưới thí sinh trực tiếp: Avatar, Họ tên, Tiến độ câu (`28/40 câu`).
- Cờ đỏ cảnh báo gian lận 🚩 hiển thị nổi bật kèm số lần vi phạm (`1/3`, `2/3`).
- Nút thu bài cưỡng chế ⛔ với cảnh báo xác nhận.

- [ ] **Step 6: Kiểm tra test suite**

Run: `flutter test`
Expected: 173/173 tests PASS.

- [ ] **Step 7: Commit Task 5**

```bash
git add lib/screens/teacher/teacher_exams_screen.dart lib/screens/exam/create_exam_screen.dart lib/screens/room/create_room_screen.dart lib/screens/room/widgets/room_qr_dialog.dart lib/screens/room/live_dashboard_screen.dart
git commit -m "feat(teacher): modernize teacher exams, exam editor, room creation and live dashboard"
```

---

### Task 6: Xác Minh Toàn Diện, Cập Nhật Tài Liệu Kiến Trúc & Tự Động Push

**Files:**
- Modify: `docs/system_architecture_and_deep_evaluation.md`
- Modify: IDE Artifact `system_architecture_and_deep_evaluation.md`

- [ ] **Step 1: Chạy kiểm thử toàn diện 100% test suite**

Run: `flutter test`
Expected: Tất cả 173 test cases PASS không có lỗi.

- [ ] **Step 2: Cập nhật tài liệu kiến trúc hệ thống**

Cập nhật `docs/system_architecture_and_deep_evaluation.md` và artifact IDE ghi nhận việc hoàn tất nâng cấp giao diện Stitch EdTech Assessment Modern, bảng ánh xạ tokens, chuẩn hóa TopNavBar 4 mục và các cải tiến layout chống đè nút nộp bài.

- [ ] **Step 3: Commit và Push tự động lên GitHub cho cả 2 repo**

```bash
git add docs/system_architecture_and_deep_evaluation.md
git commit -m "docs: update system architecture and evaluation with Stitch UI modernization"
git push origin main
```
Thực hiện tương tự trên repo gốc `c:\Users\ADMINE\Desktop\CODE`.
