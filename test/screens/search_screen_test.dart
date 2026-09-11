import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/home/search_screen.dart';

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
}
