import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/services/profile_service.dart';
import 'package:onthi_community/screens/teacher/teacher_rooms_history_screen.dart';

void main() {
  final sampleRooms = [
    TeacherRoomData(
      id: 'room-1',
      title: 'Phòng thi Toán Học Kỳ 1',
      roomCode: 'PT111',
      date: '04/10/2026',
      studentsCount: 25,
      statusLabel: 'Đang diễn ra',
      statusType: 'live',
      examTitle: 'Toán lớp 10 Đại số',
      examSubject: 'Toán',
      durationMinutes: 45,
    ),
    TeacherRoomData(
      id: 'room-2',
      title: 'Phòng thi Vật Lý 11',
      roomCode: 'PT222',
      date: '03/10/2026',
      studentsCount: 15,
      statusLabel: 'Đang chờ',
      statusType: 'waiting',
      examTitle: 'Vật lý nhiệt học',
      examSubject: 'Vật lý',
      durationMinutes: 30,
    ),
    TeacherRoomData(
      id: 'room-3',
      title: 'Phòng thi Hóa Học 12',
      roomCode: 'PT333',
      date: '01/10/2026',
      studentsCount: 30,
      statusLabel: 'Đã kết thúc',
      statusType: 'closed',
      examTitle: 'Hóa học hữu cơ',
      examSubject: 'Hóa học',
      durationMinutes: 60,
    ),
  ];

  Widget buildTestWidget({Size size = const Size(1200, 800), List<TeacherRoomData>? rooms}) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: AuthProvider(isSupabaseInitialized: false),
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: TeacherRoomsHistoryScreen(testRooms: rooms ?? sampleRooms),
        ),
      ),
    );
  }

  testWidgets('TeacherRoomsHistoryScreen displays 4 status tabs and filters by status', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify 4 status tabs exist
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Đang diễn ra'), findsAtLeastNWidgets(1));
    expect(find.text('Đang chờ'), findsAtLeastNWidgets(1));
    expect(find.text('Đã kết thúc'), findsAtLeastNWidgets(1));

    // Initially in 'Tất cả' tab: all 3 rooms are shown
    expect(find.text('Phòng thi Toán Học Kỳ 1'), findsOneWidget);
    expect(find.text('Phòng thi Vật Lý 11'), findsOneWidget);
    expect(find.text('Phòng thi Hóa Học 12'), findsOneWidget);

    // Tap 'Đang diễn ra' tab
    await tester.tap(find.text('Đang diễn ra').first);
    await tester.pumpAndSettle();

    expect(find.text('Phòng thi Toán Học Kỳ 1'), findsOneWidget);
    expect(find.text('Phòng thi Vật Lý 11'), findsNothing);
    expect(find.text('Phòng thi Hóa Học 12'), findsNothing);

    // Tap 'Đang chờ' tab
    await tester.tap(find.text('Đang chờ').first);
    await tester.pumpAndSettle();

    expect(find.text('Phòng thi Toán Học Kỳ 1'), findsNothing);
    expect(find.text('Phòng thi Vật Lý 11'), findsOneWidget);
    expect(find.text('Phòng thi Hóa Học 12'), findsNothing);

    // Tap 'Đã kết thúc' tab
    await tester.tap(find.text('Đã kết thúc').first);
    await tester.pumpAndSettle();

    expect(find.text('Phòng thi Toán Học Kỳ 1'), findsNothing);
    expect(find.text('Phòng thi Vật Lý 11'), findsNothing);
    expect(find.text('Phòng thi Hóa Học 12'), findsOneWidget);
  });

  testWidgets('TeacherRoomsHistoryScreen filters by search query on room name and code', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter search query 'PT111'
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'PT111');
    await tester.pumpAndSettle();

    expect(find.text('Phòng thi Toán Học Kỳ 1'), findsOneWidget);
    expect(find.text('Phòng thi Vật Lý 11'), findsNothing);
    expect(find.text('Phòng thi Hóa Học 12'), findsNothing);

    // Enter search query 'Hóa'
    await tester.enterText(searchField, 'Hóa');
    await tester.pumpAndSettle();

    expect(find.text('Phòng thi Toán Học Kỳ 1'), findsNothing);
    expect(find.text('Phòng thi Hóa Học 12'), findsOneWidget);
  });

  testWidgets('TeacherRoomsHistoryScreen renders without RenderFlex overflow on small mobile (360x640)', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget(size: const Size(360, 640)));
    await tester.pumpAndSettle();

    // Verify search and tabs render properly
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TeacherRoomCard displays copyable code and contextual action buttons per status', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify contextual action buttons
    expect(find.text('Bảng theo dõi trực tiếp'), findsOneWidget);
    expect(find.text('Vào phòng chờ'), findsOneWidget);
    expect(find.text('Bảng xếp hạng & Kết quả'), findsOneWidget);

    // Tap copy code for room 1 (PT111)
    final codeChipFinder = find.text('PT111');
    expect(codeChipFinder, findsOneWidget);
    await tester.tap(codeChipFinder);
    await tester.pump();

    // Verify SnackBar appears
    expect(find.text('Đã sao chép mã phòng PT111'), findsOneWidget);
  });

  testWidgets('TeacherRoomsHistoryScreen displays empty state when search finds no matches and allows resetting', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'NonExistentRoomXYZ');
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy phòng thi nào'), findsOneWidget);
    expect(find.text('Đặt lại bộ lọc'), findsOneWidget);

    // Tap reset filters
    await tester.tap(find.text('Đặt lại bộ lọc'));
    await tester.pumpAndSettle();

    expect(find.text('Phòng thi Toán Học Kỳ 1'), findsOneWidget);
  });

  testWidgets('TeacherRoomsHistoryScreen handles pagination when room count exceeds pageSize', (tester) async {
    final manyRooms = List.generate(15, (i) {
      return TeacherRoomData(
        id: 'room-$i',
        title: 'Phòng thi thử số $i',
        roomCode: 'PT${1000 + i}',
        date: '04/10/2026',
        studentsCount: 10 + i,
        statusLabel: 'Đang chờ',
        statusType: 'waiting',
      );
    });

    await tester.pumpWidget(buildTestWidget(rooms: manyRooms));
    await tester.pumpAndSettle();

    // Page 1 should display 10 items (0 to 9)
    expect(find.text('Phòng thi thử số 0'), findsOneWidget);
    expect(find.text('Phòng thi thử số 9'), findsOneWidget);
    expect(find.text('Phòng thi thử số 10'), findsNothing);

    // Scroll down to pagination bar
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    // Navigate to page 2
    final page2Btn = find.text('2');
    expect(page2Btn, findsOneWidget);
    await tester.tap(page2Btn);
    await tester.pumpAndSettle();

    // Page 2 should display remaining 5 items (10 to 14)
    expect(find.text('Phòng thi thử số 0'), findsNothing);
    expect(find.text('Phòng thi thử số 10'), findsOneWidget);
    expect(find.text('Phòng thi thử số 14'), findsOneWidget);
  });
}
