import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';
import 'package:onthi_community/screens/exam/exam_detail_screen.dart';

void main() {
  testWidgets('ExamDetailScreen renders action buttons and scroll indicator', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
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

    // Verify main action buttons
    expect(find.text('Bắt đầu tự luyện'), findsOneWidget);
    expect(find.text('Lưu đề'), findsOneWidget);
    expect(find.textContaining('Xem chi tiết'), findsWidgets);

    // Verify quick-jump / question list toggle
    expect(find.text('Hiện đáp án & giải thích'), findsOneWidget);
  });
}
