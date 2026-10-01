import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/room/widgets/room_qr_dialog.dart';

void main() {
  testWidgets('RoomQrDialog displays room code, presentation instructions and copy button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoomQrDialog(
            roomCode: 'PT123456',
            roomName: 'Kiểm tra 15 phút Toán',
          ),
        ),
      ),
    );

    expect(find.text('PT123456'), findsOneWidget);
    expect(find.text('Kiểm tra 15 phút Toán'), findsOneWidget);
    expect(find.text('Sao chép link vào phòng'), findsOneWidget);
    expect(find.text('Quét mã QR để vào phòng thi'), findsOneWidget);
  });
}
