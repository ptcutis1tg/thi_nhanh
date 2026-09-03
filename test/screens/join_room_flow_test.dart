import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/room/widgets/join_room_guest_dialog.dart';

void main() {
  testWidgets('renders JoinRoomGuestDialog and validates empty name', (tester) async {
    bool joined = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JoinRoomGuestDialog(
            roomCode: 'PT123456',
            onJoin: (name, password) async {
              joined = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Vào phòng thi'), findsOneWidget);
    expect(find.text('Mã phòng: PT123456'), findsOneWidget);
    expect(find.text('Tham gia'), findsOneWidget);

    // Tap submit without typing name
    await tester.tap(find.text('Tham gia'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(joined, isFalse);

    // Enter name
    await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn Minh');
    await tester.tap(find.text('Tham gia'));
    await tester.pumpAndSettle();

    expect(joined, isTrue);
  });
}
