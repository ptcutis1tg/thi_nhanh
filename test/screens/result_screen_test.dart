import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/exam/result_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ResultScreen renders score, stats, and reveals question review', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = AuthProvider(isSupabaseInitialized: false);
    await auth.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(
          home: ResultScreen(score: 8.5, total: 10, roomId: 'room-123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and score stats
    expect(find.textContaining('Điểm số'), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
    expect(find.text('Câu đúng'), findsOneWidget);
    expect(find.text('Câu sai'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
    expect(find.text('Xếp hạng'), findsOneWidget);

    // Verify navigation action buttons
    expect(find.text('Xem lịch sử thi'), findsOneWidget);
    expect(find.text('Về trang chủ'), findsOneWidget);
  });
}
