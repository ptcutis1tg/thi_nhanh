import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/shared/widgets/top_nav_bar.dart';

void main() {
  testWidgets('TopNavBar displays all 5 core hot bar items for all users', (tester) async {
    final authProvider = AuthProvider(isSupabaseInitialized: false);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(
          home: Scaffold(
            appBar: TopNavBar(),
          ),
        ),
      ),
    );

    // Verify all 5 core items are present regardless of role
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);
    expect(find.text('Tạo đề thi'), findsOneWidget);
    expect(find.text('Đề của tôi'), findsOneWidget);
    expect(find.text('Tạo phòng thi'), findsOneWidget);
  });
}
