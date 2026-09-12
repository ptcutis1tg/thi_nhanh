import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/home/search_screen.dart';
import 'package:onthi_community/shared/widgets/google_pagination_bar.dart';

void main() {
  testWidgets('SearchScreen renders search input, 8 subject filters, and exam items', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SearchScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify search box
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Tìm kiếm'), findsOneWidget);

    // Verify 8 subjects in filter panel
    expect(find.widgetWithText(CheckboxListTile, 'Toán học'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Vật lý'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Hóa học'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Sinh học'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Tiếng Anh'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Lịch sử'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Địa lý'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Tin học'), findsOneWidget);

    // Verify exam list items and buttons
    expect(find.text('Xem Đề'), findsWidgets);
  });

  testWidgets('SearchScreen limits to 15 items per page and integrates GooglePaginationBar', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
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
    await tester.ensureVisible(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    // Page 2: 15 items rendered (16 to 30)
    expect(find.text('Xem Đề'), findsNWidgets(15));
    expect(find.textContaining('Đang hiện 16 - 30 (Trang 2 / 3)'), findsOneWidget);

    // Switch to Page 3
    await tester.ensureVisible(find.text('3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    // Page 3: 5 remaining items rendered (31 to 35)
    expect(find.text('Xem Đề'), findsNWidgets(5));
    expect(find.textContaining('Đang hiện 31 - 35 (Trang 3 / 3)'), findsOneWidget);

    // Typing in search resets page to 1
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Đề thi kiểm tra số 1');
    await tester.pumpAndSettle();
    expect(find.textContaining('(Trang 1 /'), findsOneWidget);
  });
}
