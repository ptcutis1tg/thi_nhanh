import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/room/student_waiting_room_screen.dart';

void main() {
  testWidgets('renders fallback StudentWaitingRoomScreen elements', (tester) async {
    final authProvider = AuthProvider(isSupabaseInitialized: false);

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: StudentWaitingRoomScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('MÃ PHÒNG THI'), findsOneWidget);
    expect(find.text('Thông tin bài thi'), findsOneWidget);
    expect(find.text('Học sinh trong phòng'), findsOneWidget);
    expect(find.text('Sao chép mã'), findsOneWidget);

    // Không được chứa nút mô phỏng debug hoặc dữ liệu học sinh giả lập
    expect(find.text('Mô phỏng: Bắt đầu thi'), findsNothing);
    expect(find.text('Minh Anh'), findsNothing);
    expect(find.text('Hải Bình'), findsNothing);
    expect(find.text('Tiến Cường'), findsNothing);
    expect(find.text('PT892341'), findsNothing);
  });
}
