import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/main.dart';

void main() {
  testWidgets('renders the OnThi home page', (tester) async {
    await tester.pumpWidget(const OnThiApp());

    expect(find.text('ÔnThi'), findsOneWidget);
    expect(find.text('Đang được yêu thích'), findsOneWidget);
    expect(find.text('Vào làm bài →'), findsOneWidget);
  });
}
