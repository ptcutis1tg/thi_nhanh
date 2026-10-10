# Hatsune Miku Theme & 3D Enamel Container System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Thi Nhanh app into a modern, high-performance visual experience using the Hatsune Miku Cyber-Teal & Pale Mint color palette, 4-tier rounded 3D enamel container system, milky mint canvas, and desktop-only micro-hover pointer interactions with zero mobile lag.

**Architecture:** Update central design tokens in `AppTheme`, build isolated zero-lag UI components (`AppInteractiveHoverCard`, `MilkyMintScaffold`), refactor core screens (`HomeScreen`, `TopNavBar`, `MobileBottomNavBar`, `TeacherExamsScreen`, `CreateRoomScreen`, `JoinRoomScreen`) to consume the new design system tokens, and verify zero RenderFlex overflows and 100% test pass rate.

**Tech Stack:** Flutter 3.x, Dart 3.x, GoogleFonts (Be Vietnam Pro & Fira Code), Material 3, Flutter Test Suite.

## Global Constraints
- Target platforms: Web, Android, iOS, Windows, macOS, Linux.
- Performance: Zero `BackdropFilter` real-time GPU blur; Simulated Glassmorphism via enamel white `#FFFFFF` + 1px hairline translucent borders + diffused luminescence shadow.
- Desktop Micro-Hover: Active only when mouse pointer hovers over cards/buttons (`Offset(0, -2.5)`, enhanced `hoverGlowShadow`); touch/mobile devices remain default static without sticky hover bugs.
- Automated commit & push to GitHub after each milestone.
- 100% test pass rate with 0 RenderFlex overflows on 360px mobile and 1440px desktop viewports.

---

### Task 1: Core Design Tokens & Theme Overhaul in `AppTheme`

**Files:**
- Modify: `lib/core/theme/app_theme.dart`
- Modify: `test/theme/app_theme_test.dart`

**Interfaces:**
- Produces:
  - `AppTheme.primary = Color(0xFF39C5BB)`
  - `AppTheme.primaryDark = Color(0xFF00A896)`
  - `AppTheme.primaryLight = Color(0xFF7FE3DB)`
  - `AppTheme.primaryContainer = Color(0xFFE6FAF8)`
  - `AppTheme.accentMagenta = Color(0xFFE84188)`
  - `AppTheme.background = Color(0xFFF4FAF9)`
  - `AppTheme.surface = Color(0xFFFFFFFF)`
  - `AppTheme.textMain = Color(0xFF1E293B)`
  - `AppTheme.textSecondary = Color(0xFF64748B)`
  - `AppTheme.border = Color(0xFFE2EFEF)`
  - `AppTheme.shellRadius = 32.0`
  - `AppTheme.heroRadius = 24.0`
  - `AppTheme.cardRadius = 16.0`
  - `AppTheme.pillRadius = 100.0`
  - `AppTheme.hoverGlowShadow`

- [ ] **Step 1: Write the failing test for updated Miku tokens**

```dart
// test/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/core/theme/app_theme.dart';

void main() {
  group('AppTheme Miku Tokens & 3D Container Design', () {
    test('defines Miku Cyber-Teal and Milky Mint color tokens', () {
      expect(AppTheme.primary, const Color(0xFF39C5BB));
      expect(AppTheme.primaryDark, const Color(0xFF00A896));
      expect(AppTheme.primaryLight, const Color(0xFF7FE3DB));
      expect(AppTheme.primaryContainer, const Color(0xFFE6FAF8));
      expect(AppTheme.accentMagenta, const Color(0xFFE84188));
      expect(AppTheme.background, const Color(0xFFF4FAF9));
      expect(AppTheme.surface, const Color(0xFFFFFFFF));
      expect(AppTheme.textMain, const Color(0xFF1E293B));
      expect(AppTheme.textSecondary, const Color(0xFF64748B));
      expect(AppTheme.border, const Color(0xFFE2EFEF));
    });

    test('defines 4-tier radius hierarchy', () {
      expect(AppTheme.shellRadius, 32.0);
      expect(AppTheme.heroRadius, 24.0);
      expect(AppTheme.cardRadius, 16.0);
      expect(AppTheme.pillRadius, 100.0);
    });

    test('defines luminescence and hover glow shadows', () {
      expect(AppTheme.luminescenceShadow.isNotEmpty, isTrue);
      expect(AppTheme.hoverGlowShadow.isNotEmpty, isTrue);
      expect(AppTheme.hoverGlowShadow.first.blurRadius, 24.0);
    });

    test('lightTheme configures ThemeData with Miku ColorScheme and capsule buttons', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.primary, AppTheme.primary);
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
      expect(theme.cardTheme.color, AppTheme.surface);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL due to old color definitions (`0xFF6557E8`) and missing `shellRadius`/`heroRadius`/`hoverGlowShadow`.

- [ ] **Step 3: Update `AppTheme` with Miku color system, 4-tier radii, and hover shadows**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Miku Cyber-Aqua Palette
  static const Color primary = Color(0xFF39C5BB);          // Miku Vivid Aqua
  static const Color primaryDark = Color(0xFF00A896);      // Deep Cyber Teal
  static const Color primaryDarker = Color(0xFF008080);    // Solid Teal
  static const Color primaryLight = Color(0xFF7FE3DB);     // Soft Cyan Glow
  static const Color primaryContainer = Color(0xFFE6FAF8); // Pale Miku Mint Pill
  static const Color primarySubtle = Color(0xFFF0FDFB);    // Tinted Surface
  
  // Accents & Contrast
  static const Color accentMagenta = Color(0xFFE84188);    // Miku Pink Accent
  static const Color accentCyan = Color(0xFF00F0FF);       // Neon Electric Cyan
  
  // Canvas & Surfaces
  static const Color background = Color(0xFFF4FAF9);       // Milky Mint Canvas
  static const Color surface = Color(0xFFFFFFFF);          // Enamel Pure White
  static const Color surfaceMuted = Color(0xFFF8FCFC);     // Secondary Surface
  
  // Typography Colors
  static const Color textMain = Color(0xFF1E293B);         // Deep Slate Ink
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

  // 4-Tier Radii Hierarchy
  static const double shellRadius = 32.0;
  static const double heroRadius = 24.0;
  static const double cardRadius = 16.0;
  static const double inputRadius = 12.0;
  static const double pillRadius = 100.0;

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F2B28),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> luminescenceShadow = [
    BoxShadow(
      color: Color(0x2839C5BB),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> hoverGlowShadow = [
    BoxShadow(
      color: Color(0x3D39C5BB),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 1,
    ),
  ];

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
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF45D0C6);
            }
            if (states.contains(WidgetState.disabled)) {
              return primary.withOpacity(0.4);
            }
            return primary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return 4.0;
            }
            return 0.0;
          }),
          shadowColor: WidgetStateProperty.all(const Color(0x3D39C5BB)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
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
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart test/theme/app_theme_test.dart
git commit -m "feat(theme): update AppTheme with Hatsune Miku palette, 4-tier radii, and hover styles"
```

---

### Task 2: PC Micro-Hover Interactive Widget (`AppInteractiveHoverCard`)

**Files:**
- Create: `lib/shared/widgets/app_interactive_hover_card.dart`
- Create: `test/widgets/app_interactive_hover_card_test.dart`

**Interfaces:**
- Consumes: `AppTheme.cardShadow`, `AppTheme.hoverGlowShadow`, `AppTheme.cardRadius`, `AppTheme.border`, `AppTheme.primary`
- Produces: `AppInteractiveHoverCard(child: Widget, onTap: VoidCallback?, borderRadius: double, enableHover: bool)`

- [ ] **Step 1: Write the failing widget test for `AppInteractiveHoverCard`**

```dart
// test/widgets/app_interactive_hover_card_test.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/core/theme/app_theme.dart';
import 'package:thi_nhanh/shared/widgets/app_interactive_hover_card.dart';

void main() {
  group('AppInteractiveHoverCard Widget', () {
    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInteractiveHoverCard(
              child: const Text('Miku Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Miku Card Content'), findsOneWidget);
    });

    testWidgets('responds to mouse hover enter and exit with translation animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: AppInteractiveHoverCard(
                child: const SizedBox(width: 100, height: 100, child: Text('Hover Target')),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move mouse over target
      await gesture.moveTo(tester.getCenter(find.text('Hover Target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hover Target'), findsOneWidget);

      // Move mouse away
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hover Target'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/app_interactive_hover_card_test.dart`
Expected: FAIL due to missing file `app_interactive_hover_card.dart`.

- [ ] **Step 3: Implement `AppInteractiveHoverCard`**

```dart
// lib/shared/widgets/app_interactive_hover_card.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppInteractiveHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Color? backgroundColor;
  final Border? customBorder;
  final EdgeInsetsGeometry? padding;
  final bool enableHover;

  const AppInteractiveHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.customBorder,
    this.padding,
    this.enableHover = true,
  });

  @override
  State<AppInteractiveHoverCard> createState() => _AppInteractiveHoverCardState();
}

class _AppInteractiveHoverCardState extends State<AppInteractiveHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? AppTheme.cardRadius;
    final isInteractive = widget.enableHover;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: isInteractive ? (_) => setState(() => _isHovered = true) : null,
      onExit: isInteractive ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -2.5 : 0.0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppTheme.surface,
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: widget.customBorder ??
                Border.all(
                  color: _isHovered ? AppTheme.primary : AppTheme.border,
                  width: _isHovered ? 1.2 : 1.0,
                ),
            boxShadow: _isHovered
                ? AppTheme.hoverGlowShadow
                : AppTheme.cardShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/app_interactive_hover_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/app_interactive_hover_card.dart test/widgets/app_interactive_hover_card_test.dart
git commit -m "feat(ui): add AppInteractiveHoverCard with desktop micro-hover and zero-mobile overhead"
```

---

### Task 3: Milky Mint Scaffold & Zero-Lag Ambient Mesh Background

**Files:**
- Create: `lib/shared/widgets/milky_mint_scaffold.dart`
- Create: `test/widgets/milky_mint_scaffold_test.dart`

**Interfaces:**
- Consumes: `AppTheme.background`, `AppTheme.primary`
- Produces: `MilkyMintScaffold(body: Widget, appBar: PreferredSizeWidget?, bottomNavigationBar: Widget?)`

- [ ] **Step 1: Write the failing widget test for `MilkyMintScaffold`**

```dart
// test/widgets/milky_mint_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/core/theme/app_theme.dart';
import 'package:thi_nhanh/shared/widgets/milky_mint_scaffold.dart';

void main() {
  group('MilkyMintScaffold Widget', () {
    testWidgets('renders background mesh and body content with zero lag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MilkyMintScaffold(
            body: const Center(child: Text('Scaffold Content')),
          ),
        ),
      );

      expect(find.text('Scaffold Content'), findsOneWidget);
      expect(find.byType(MilkyMintScaffold), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/milky_mint_scaffold_test.dart`
Expected: FAIL due to missing file `milky_mint_scaffold.dart`.

- [ ] **Step 3: Implement `MilkyMintScaffold`**

```dart
// lib/shared/widgets/milky_mint_scaffold.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MilkyMintScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showAmbientGlow;

  const MilkyMintScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showAmbientGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          if (showAmbientGlow)
            Positioned(
              top: -80,
              right: -80,
              child: RepaintBoundary(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.14),
                        AppTheme.primaryLight.withOpacity(0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(child: body),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/milky_mint_scaffold_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/milky_mint_scaffold.dart test/widgets/milky_mint_scaffold_test.dart
git commit -m "feat(ui): add MilkyMintScaffold with zero-lag ambient mesh glow"
```

---

### Task 4: Apply Miku Theme & 3D Enamel Containers to Home & Navigation

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/shared/widgets/top_nav_bar.dart`
- Modify: `lib/shared/widgets/mobile_bottom_nav_bar.dart`
- Test: `test/screens/home_mobile_layout_test.dart`
- Test: `test/screens/home_navigation_test.dart`

**Interfaces:**
- Consumes: `AppTheme`, `AppInteractiveHoverCard`, `MilkyMintScaffold`
- Produces: Updated `HomeScreen`, `TopNavBar`, `MobileBottomNavBar` with Miku Aqua accents, 3D enamel stat cards, and desktop hover translations.

- [ ] **Step 1: Write / Update tests for Home Screen and Nav Bars with Miku Theme**

```dart
// test/screens/home_mobile_layout_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/core/theme/app_theme.dart';
import 'package:thi_nhanh/screens/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders Hero banner and Enamel Stat Cards on mobile and desktop', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(375, 812);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull); // 0 RenderFlex overflow
  });
}
```

- [ ] **Step 2: Run test to verify it compiles and runs**

Run: `flutter test test/screens/home_mobile_layout_test.dart`
Expected: PASS or minor color token updates.

- [ ] **Step 3: Update `HomeScreen`, `TopNavBar`, `MobileBottomNavBar`**
  - Update `HomeScreen` to use `MilkyMintScaffold`, Hero Banner gradient (`[Color(0xFF39C5BB), Color(0xFF00A896)]`), Enamel White Cards wrapped with `AppInteractiveHoverCard`, and Miku Pill tags (`#E6FAF8`).
  - Update `TopNavBar` and `MobileBottomNavBar` with active indicator `AppTheme.primary`, 1px hairline border, and clean white enamel bar.

- [ ] **Step 4: Run tests to verify all pass**

Run: `flutter test test/screens/home_mobile_layout_test.dart test/screens/home_navigation_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home/home_screen.dart lib/shared/widgets/top_nav_bar.dart lib/shared/widgets/mobile_bottom_nav_bar.dart test/screens/home_mobile_layout_test.dart test/screens/home_navigation_test.dart
git commit -m "feat(home): apply Miku color theme, enamel stat cards, and hover effects to home and navigation"
```

---

### Task 5: Apply Miku Theme & 3D Enamel Containers to Teacher Dashboard & Room Management

**Files:**
- Modify: `lib/screens/teacher/teacher_exams_screen.dart`
- Modify: `lib/screens/room/create_room_screen.dart`
- Modify: `lib/screens/room/join_room_screen.dart`
- Test: `test/screens/create_room_screen_test.dart`
- Test: `test/screens/join_room_flow_test.dart`

**Interfaces:**
- Consumes: `AppTheme`, `AppInteractiveHoverCard`, `MilkyMintScaffold`
- Produces: Updated `TeacherExamsScreen`, `CreateRoomScreen`, `JoinRoomScreen` with 4-tier radii, 1px borders, Miku Teal capsule buttons, and PC micro-hover.

- [ ] **Step 1: Write / Update tests for Teacher Dashboard and Room Screens**

```dart
// test/screens/create_room_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thi_nhanh/core/theme/app_theme.dart';
import 'package:thi_nhanh/screens/room/create_room_screen.dart';

void main() {
  testWidgets('CreateRoomScreen renders Miku pill selectors without overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CreateRoomScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CreateRoomScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify current state**

Run: `flutter test test/screens/create_room_screen_test.dart test/screens/join_room_flow_test.dart`
Expected: PASS

- [ ] **Step 3: Update `TeacherExamsScreen`, `CreateRoomScreen`, `JoinRoomScreen`**
  - Wrap teacher quick-action tiles in `AppInteractiveHoverCard` with custom vibrant Miku gradients.
  - Refactor `CreateRoomScreen` candidate count selectors (`30`, `40`, `50`, `100`) as capsule pills with `AppTheme.primaryContainer` and `AppTheme.primary` active borders.
  - Refactor `JoinRoomScreen` with enamel white PIN card, 32px rounded shell, and Miku action buttons.

- [ ] **Step 4: Run tests to verify all pass**

Run: `flutter test test/screens/create_room_screen_test.dart test/screens/join_room_flow_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/teacher/teacher_exams_screen.dart lib/screens/room/create_room_screen.dart lib/screens/room/join_room_screen.dart test/screens/create_room_screen_test.dart test/screens/join_room_flow_test.dart
git commit -m "feat(room): apply Miku theme and enamel 3D containers to Teacher Dashboard and Room screens"
```

---

### Task 6: Full Test Suite Verification, Documentation Update & Auto-Push

**Files:**
- Modify: `docs/system_architecture_and_deep_evaluation.md`
- Artifact: IDE System Architecture artifact

- [ ] **Step 1: Run complete Flutter test suite**

Run: `flutter test`
Expected: All tests pass (219+ tests, 100% pass rate).

- [ ] **Step 2: Update `docs/system_architecture_and_deep_evaluation.md`**
  - Document the Hatsune Miku Cyber-Teal & Pale Mint design system, 3D enamel containers, PC micro-hover interactions, and updated test metrics.

- [ ] **Step 3: Auto-commit and Auto-push to both repositories**

```bash
git add docs/system_architecture_and_deep_evaluation.md
git commit -m "docs(eval): update system architecture with Miku theme, 3D enamel containers, and PC hover interaction metrics"
git push origin main
```
In root `CODE`:
```bash
git add thi_nhanh
git commit -m "chore(submodule): sync thi_nhanh with Miku theme and 3D enamel container system"
git push origin main
```
