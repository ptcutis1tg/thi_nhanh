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
