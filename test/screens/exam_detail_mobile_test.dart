import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';
import 'package:onthi_community/screens/exam/exam_detail_screen.dart';

void main() {
  testWidgets('ExamDetailScreen renders cleanly on mobile 360px without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = AuthProvider(isSupabaseInitialized: false);
    final savedRepo = SavedExamRepository(null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          Provider<SavedExamRepository>.value(value: savedRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ExamDetailScreen(examId: '10000000-0000-4000-8000-000000000001'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify breadcrumbs and main elements
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Bắt đầu tự luyện'), findsWidgets);
    expect(find.text('Hiện đáp án & giải thích'), findsOneWidget);

    // Verify questions rendered
    expect(find.textContaining('Câu 1'), findsOneWidget);
  });
}
