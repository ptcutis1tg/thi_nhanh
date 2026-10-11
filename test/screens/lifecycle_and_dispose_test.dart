import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/home/home_screen.dart';
import 'package:onthi_community/screens/home/search_screen.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';
import 'package:onthi_community/screens/room/student_waiting_room_screen.dart';
import 'package:onthi_community/screens/auth/reset_password_screen.dart';
import 'package:onthi_community/screens/profile/profile_screen.dart';
import 'package:onthi_community/screens/exam/create_exam_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Screens instantiate and dispose cleanly without memory leaks', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthProvider(isSupabaseInitialized: false);

    // 1. HomeScreen
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);

    // 2. SearchScreen
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(SearchScreen), findsOneWidget);

    // 3. CreateRoomScreen
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: CreateRoomScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(CreateRoomScreen), findsOneWidget);

    // 4. StudentWaitingRoomScreen
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: StudentWaitingRoomScreen(roomId: 'TEST01')),
      ),
    );
    await tester.pump();
    expect(find.byType(StudentWaitingRoomScreen), findsOneWidget);

    // 5. ResetPasswordScreen
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: ResetPasswordScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(ResetPasswordScreen), findsOneWidget);

    // 6. ProfileScreen
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(ProfileScreen), findsOneWidget);

    // 7. CreateExamScreen
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: CreateExamScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(CreateExamScreen), findsOneWidget);

    // Dispose all
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    expect(find.byType(CreateExamScreen), findsNothing);
  });
}
