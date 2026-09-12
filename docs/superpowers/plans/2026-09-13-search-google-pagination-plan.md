# Phân Trang 15 Đề/Trang & Điều Hướng Chuẩn Google Cho Màn Hình Tìm Kiếm Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Giới hạn hiển thị 15 đề thi trên mỗi trang trong `SearchScreen`, bổ sung thanh phân trang chuẩn phong cách Google (`< Trước 1 2 3 ... 10 Tiếp >`), dòng thông tin đếm kết quả, tự động cuộn lên đầu danh sách khi chuyển trang và tự động reset về trang 1 khi lọc tìm kiếm.

**Architecture:** Tạo widget độc lập `GooglePaginationBar` phụ trách tính toán window phân trang chuẩn Google và xử lý giao diện/sự kiện chuyển trang. Tích hợp `GooglePaginationBar` vào `SearchScreen` cùng logic cắt mảng 15 phần tử (`skip/take`), header thống kê kết quả, và `ScrollController` cuộn mượt.

**Tech Stack:** Flutter, Dart, Flutter Test (`WidgetTester`), Supabase Flutter.

## Global Constraints

- **File Path Pagination Bar:** `lib/shared/widgets/google_pagination_bar.dart`
- **File Path Search Screen:** `lib/screens/home/search_screen.dart`
- **Unit Test Pagination Bar:** `test/widgets/google_pagination_bar_test.dart`
- **Widget Test Search Screen:** `test/screens/search_screen_test.dart`
- **Kích thước trang:** Cố định 15 đề thi (`_pageSize = 15`).
- **Thuật toán co cụm trang (Windowing):**
  - Khi `totalPages <= 7`: hiển thị toàn bộ `[1, 2, ..., totalPages]`.
  - Khi `totalPages > 7`:
    - `currentPage <= 4`: `[1, 2, 3, 4, 5, '...', totalPages]`
    - `currentPage >= totalPages - 3`: `[1, '...', totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages]`
    - Ở giữa: `[1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages]`
- **Auto-push:** Sau khi hoàn thành và pass test, tự động commit và push cho cả `thi_nhanh` và `CODE`.
- **Evidence Before Claims:** Mọi khẳng định hoàn thành phải có output test thực tế.

---

### Task 1: Xây dựng Component `GooglePaginationBar` & Unit Test

**Files:**
- Create: `lib/shared/widgets/google_pagination_bar.dart`
- Test: `test/widgets/google_pagination_bar_test.dart`

**Interfaces:**
- Consumes: Flutter standard widgets & `AppTheme` (`lib/core/theme/app_theme.dart`).
- Produces: `GooglePaginationBar` widget với các tham số:
  - `final int currentPage` (1-indexed)
  - `final int totalPages`
  - `final ValueChanged<int> onPageChanged`
  - Static helper method: `static List<dynamic> computePageNumbers({required int currentPage, required int totalPages})`

- [ ] **Step 1: Viết test thất bại (Failing Test) cho `GooglePaginationBar`**

Tạo file `test/widgets/google_pagination_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/shared/widgets/google_pagination_bar.dart';

void main() {
  group('GooglePaginationBar.computePageNumbers algorithm', () {
    test('returns full range when totalPages <= 7', () {
      expect(
        GooglePaginationBar.computePageNumbers(currentPage: 1, totalPages: 5),
        equals([1, 2, 3, 4, 5]),
      );
      expect(
        GooglePaginationBar.computePageNumbers(currentPage: 4, totalPages: 7),
        equals([1, 2, 3, 4, 5, 6, 7]),
      );
    });

    test('returns [1, 2, 3, 4, 5, "...", totalPages] when currentPage <= 4 and totalPages > 7', () {
      expect(
        GooglePaginationBar.computePageNumbers(currentPage: 1, totalPages: 10),
        equals([1, 2, 3, 4, 5, '...', 10]),
      );
      expect(
        GooglePaginationBar.computePageNumbers(currentPage: 4, totalPages: 10),
        equals([1, 2, 3, 4, 5, '...', 10]),
      );
    });

    test('returns [1, "...", totalPages-4..totalPages] when currentPage >= totalPages - 3 and totalPages > 7', () {
      expect(
        GooglePaginationBar.computePageNumbers(currentPage: 8, totalPages: 10),
        equals([1, '...', 6, 7, 8, 9, 10]),
      );
      expect(
        GooglePaginationBar.computePageNumbers(currentPage: 10, totalPages: 10),
        equals([1, '...', 6, 7, 8, 9, 10]),
      );
    });

    test('returns [1, "...", c-1, c, c+1, "...", totalPages] when currentPage in middle', () {
      expect(
        GooglePaginationBar.computePageNumbers(currentPage: 6, totalPages: 12),
        equals([1, '...', 5, 6, 7, '...', 12]),
      );
    });
  });

  group('GooglePaginationBar UI interactions', () {
    testWidgets('renders numbers and triggers onPageChanged when clicked', (tester) async {
      int? selectedPage;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooglePaginationBar(
              currentPage: 1,
              totalPages: 5,
              onPageChanged: (page) => selectedPage = page,
            ),
          ),
        ),
      );

      expect(find.text('Trước'), findsOneWidget);
      expect(find.text('Tiếp'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Tap page 2
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(selectedPage, equals(2));

      // Tap Next ('Tiếp')
      await tester.tap(find.text('Tiếp'));
      await tester.pumpAndSettle();
      expect(selectedPage, equals(2)); // currentPage was 1, so Next -> 2
    });

    testWidgets('disables "Trước" on page 1 and "Tiếp" on last page', (tester) async {
      int tappedCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooglePaginationBar(
              currentPage: 1,
              totalPages: 5,
              onPageChanged: (_) => tappedCount++,
            ),
          ),
        ),
      );

      // Tapping "Trước" on page 1 should not trigger callback
      await tester.tap(find.text('Trước'));
      await tester.pumpAndSettle();
      expect(tappedCount, equals(0));

      // Pump last page
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooglePaginationBar(
              currentPage: 5,
              totalPages: 5,
              onPageChanged: (_) => tappedCount++,
            ),
          ),
        ),
      );

      // Tapping "Tiếp" on page 5 should not trigger callback
      await tester.tap(find.text('Tiếp'));
      await tester.pumpAndSettle();
      expect(tappedCount, equals(0));
    });
  });
}
```

- [ ] **Step 2: Chạy kiểm thử để xác nhận thất bại (Verify Failure)**

Run: `flutter test test/widgets/google_pagination_bar_test.dart`
Expected: FAIL với lỗi "Target of URI doesn't exist: 'package:onthi_community/shared/widgets/google_pagination_bar.dart'".

- [ ] **Step 3: Triển khai mã nguồn `lib/shared/widgets/google_pagination_bar.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GooglePaginationBar extends StatelessWidget {
  const GooglePaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  static List<dynamic> computePageNumbers({
    required int currentPage,
    required int totalPages,
  }) {
    if (totalPages <= 1) return [1];
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }

    if (currentPage <= 4) {
      return [1, 2, 3, 4, 5, '...', totalPages];
    }

    if (currentPage >= totalPages - 3) {
      return [
        1,
        '...',
        totalPages - 4,
        totalPages - 3,
        totalPages - 2,
        totalPages - 1,
        totalPages,
      ];
    }

    return [
      1,
      '...',
      currentPage - 1,
      currentPage,
      currentPage + 1,
      '...',
      totalPages,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = computePageNumbers(currentPage: currentPage, totalPages: totalPages);
    final hasPrev = currentPage > 1;
    final hasNext = currentPage < totalPages;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút "Trước"
              _NavButton(
                icon: Icons.chevron_left_rounded,
                label: 'Trước',
                isEnabled: hasPrev,
                onTap: hasPrev ? () => onPageChanged(currentPage - 1) : null,
              ),
              const SizedBox(width: 8),

              // Dải số trang
              ...pages.map((item) {
                if (item is int) {
                  final isCurrent = item == currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => onPageChanged(item),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isCurrent
                              ? null
                              : Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$item',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                }
              }),

              const SizedBox(width: 8),
              // Nút "Tiếp"
              _NavButton(
                icon: Icons.chevron_right_rounded,
                label: 'Tiếp',
                isEnabled: hasNext,
                isRightIcon: true,
                onTap: hasNext ? () => onPageChanged(currentPage + 1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onTap,
    this.isRightIcon = false,
  });

  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback? onTap;
  final bool isRightIcon;

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.4);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled ? AppTheme.primary.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          ),
          color: isEnabled ? AppTheme.primary.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRightIcon) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (isRightIcon) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Chạy kiểm thử để xác nhận thành công (Verify Pass)**

Run: `flutter test test/widgets/google_pagination_bar_test.dart`
Expected: PASS (All tests passed).

- [ ] **Step 5: Git commit cho Task 1**

```bash
git add lib/shared/widgets/google_pagination_bar.dart test/widgets/google_pagination_bar_test.dart
git commit -m "feat: add GooglePaginationBar component with unit tests"
```

---

### Task 2: Tích hợp Phân Trang & Điều Hướng Google Vào `SearchScreen`

**Files:**
- Modify: `lib/screens/home/search_screen.dart`
- Modify: `test/screens/search_screen_test.dart`

**Interfaces:**
- Consumes: `GooglePaginationBar` (`lib/shared/widgets/google_pagination_bar.dart`).
- Produces:
  - `SearchScreen` hỗ trợ phân trang 15 item/trang (`_pageSize = 15`), header thông số đếm, smooth scroll lên đầu khi đổi trang, reset về trang 1 khi lọc hoặc tìm kiếm.
  - Expose `SearchExamItem` (thay vì `_SearchItem` private) và tham số tùy chọn `List<SearchExamItem>? initialItems` trong constructor `SearchScreen({super.key, this.initialItems})` để widget test có thể kiểm thử trực tiếp mà không phụ thuộc Supabase.

- [ ] **Step 1: Viết test thất bại (Failing Test) cho `SearchScreen` với 35 đề thi**

Cập nhật `test/screens/search_screen_test.dart`:
- Bổ sung test case kiểm tra phân trang:
  - Khởi tạo 35 đề thi giả lập qua `SearchScreen(initialItems: testItems)`.
  - Kiểm tra chỉ có đúng 15 nút 'Xem Đề' trên trang 1.
  - Kiểm tra có hiển thị header đếm: "Tìm thấy khoảng 35 đề thi • Đang hiện 1 - 15 (Trang 1 / 3)".
  - Kiểm tra có thanh phân trang Google (`find.byType(GooglePaginationBar)`).
  - Bấm vào trang 2: kiểm tra header cập nhật "Đang hiện 16 - 30 (Trang 2 / 3)".
  - Gõ từ khóa tìm kiếm: kiểm tra số trang tự động reset về trang 1.

```dart
testWidgets('SearchScreen limits to 15 items per page and integrates GooglePaginationBar', (tester) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final testItems = List.generate(
    35,
    (index) => SearchExamItem(
      id: 'id_$index',
      code: 'DT${100000 + index}',
      title: 'Đề thi kiểm tra số ${index + 1}',
      teacher: 'Giáo viên $index',
      subject: 'Toán học',
      questions: 20,
      duration: 45,
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SearchScreen(initialItems: testItems)),
    ),
  );
  await tester.pumpAndSettle();

  // Page 1: 15 items rendered
  expect(find.text('Xem Đề'), findsNWidgets(15));
  expect(find.textContaining('Tìm thấy khoảng 35 đề thi • Đang hiện 1 - 15 (Trang 1 / 3)'), findsOneWidget);
  expect(find.byType(GooglePaginationBar), findsOneWidget);

  // Switch to Page 2
  await tester.tap(find.text('2'));
  await tester.pumpAndSettle();

  // Page 2: 15 items rendered (16 to 30)
  expect(find.text('Xem Đề'), findsNWidgets(15));
  expect(find.textContaining('Đang hiện 16 - 30 (Trang 2 / 3)'), findsOneWidget);

  // Switch to Page 3
  await tester.tap(find.text('3'));
  await tester.pumpAndSettle();

  // Page 3: 5 remaining items rendered (31 to 35)
  expect(find.text('Xem Đề'), findsNWidgets(5));
  expect(find.textContaining('Đang hiện 31 - 35 (Trang 3 / 3)'), findsOneWidget);

  // Typing in search resets page to 1
  await tester.enterText(find.byType(TextField), 'Đề thi kiểm tra số 1');
  await tester.pumpAndSettle();
  expect(find.textContaining('(Trang 1 /'), findsOneWidget);
});
```

- [ ] **Step 2: Chạy kiểm thử để xác nhận thất bại (Verify Failure)**

Run: `flutter test test/screens/search_screen_test.dart`
Expected: FAIL vì `SearchExamItem` chưa được định nghĩa và `initialItems` chưa tồn tại trong `SearchScreen`.

- [ ] **Step 3: Cập nhật `lib/screens/home/search_screen.dart`**

Thực hiện:
1. Đổi tên `_SearchItem` thành `SearchExamItem` (public).
2. Thêm `final List<SearchExamItem>? initialItems;` vào `SearchScreen`.
3. Trong `_SearchScreenState`:
   - `static const int _pageSize = 15;`
   - `int _currentPage = 1;`
   - `final ScrollController _scrollController = ScrollController();`
4. Nếu `widget.initialItems != null`: nạp `_realItems = widget.initialItems!; _isLoading = false;` và bỏ qua gọi Supabase.
5. Khi gõ từ khóa (`onChanged`), chọn môn (`onSubjectChanged`), đổi sắp xếp (`onSortChanged`): thêm `_currentPage = 1`.
6. Tính `totalPages = (results.length / _pageSize).ceil().clamp(1, 99999);`
   Nếu `_currentPage > totalPages`: `_currentPage = totalPages;`
   Cắt `final startIndex = (_currentPage - 1) * _pageSize;`
   `final pageItems = results.skip(startIndex).take(_pageSize).toList();`
7. Thêm `_ResultsHeader` hiển thị thống kê kết quả khi `results.isNotEmpty`.
8. Hiển thị `_ResultsGrid(items: pageItems)` thay vì toàn bộ `results`.
9. Thêm `GooglePaginationBar` ở chân `_ResultsGrid` khi `totalPages > 1`.
10. Xử lý `onPageChanged`:
    ```dart
    setState(() => _currentPage = page);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    ```

- [ ] **Step 4: Chạy kiểm thử để xác nhận thành công (Verify Pass)**

Run: `flutter test test/screens/search_screen_test.dart`
Expected: PASS (All tests passed).

- [ ] **Step 5: Git commit cho Task 2**

```bash
git add lib/screens/home/search_screen.dart test/screens/search_screen_test.dart
git commit -m "feat: integrate GooglePaginationBar and 15 items per page in SearchScreen"
```

---

### Task 3: Chạy Toàn Bộ Kiểm Thử Dự Án & Tự Động Push Cả Hai Kho Mã Nguồn

**Files:**
- Toàn bộ repo `thi_nhanh` và parent `CODE`.

- [ ] **Step 1: Chạy toàn bộ test suite của dự án**

Run: `flutter test`
Expected: 100% tests pass (bao gồm 65 tests hiện có + 2 test suite mới).

- [ ] **Step 2: Commit và push submodule `thi_nhanh`**

```bash
cd c:\Users\ADMINE\Desktop\CODE\thi_nhanh
git status
git push origin main
```

- [ ] **Step 3: Commit và push parent repository `CODE`**

```bash
cd c:\Users\ADMINE\Desktop\CODE
git add thi_nhanh
git commit -m "feat: search screen google pagination 15 items per page"
git push origin main
```

- [ ] **Step 4: Thu thập bằng chứng kiểm thử (Evidence Before Claims) và cập nhật walkthrough artifact**
