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
          home: ResultScreen(roomId: 'room-123'),
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

    // Verify room leaderboard button is present because roomId was passed
    expect(find.text('Bảng xếp hạng trực tiếp'), findsOneWidget);

    // Verify Question review can be toggled
    expect(find.text('Chi tiết bài làm & Lời giải'), findsNothing);
    await tester.tap(find.text('Xem lại bài làm & Lời giải'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết bài làm & Lời giải'), findsOneWidget);
    expect(find.textContaining('Tập hợp A ='), findsOneWidget);
    expect(find.textContaining('Lời giải chi tiết:'), findsWidgets);
  });
}
