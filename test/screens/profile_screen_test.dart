import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/profile/profile_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('student profile renders the role controls instead of a blank body', (tester) async {
    final auth = AuthProvider(isSupabaseInitialized: false);
    await auth.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    expect(find.text('Vai trò sử dụng'), findsOneWidget);
    expect(find.text('Học sinh'), findsOneWidget);
    expect(find.text('Giáo viên'), findsOneWidget);
  });
}
