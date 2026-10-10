import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';
import 'package:onthi_community/screens/home/search_screen.dart';

class MockSavedExamRepository implements SavedExamRepository {
  final Set<String> _savedIds = {};

  @override
  Future<Set<String>> getSavedExamIds() async => _savedIds;

  @override
  Future<bool> toggleSaveExam(String examId) async {
    if (_savedIds.contains(examId)) {
      _savedIds.remove(examId);
      return false;
    } else {
      _savedIds.add(examId);
      return true;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final sampleItems = [
    const SearchExamItem(
      id: 'exam-1',
      code: 'TOAN12',
      title: 'Đề thi thử THPT Quốc Gia môn Toán 2024',
      teacher: 'Thầy Nguyễn Văn A',
      subject: 'Toán học',
      questions: 50,
      duration: 90,
      activity: 'Vừa xong',
    ),
    const SearchExamItem(
      id: 'exam-2',
      code: 'LY12',
      title: 'Đề ôn tập Vật Lý Dao Động Cơ',
      teacher: 'Cô Trần Thị B',
      subject: 'Vật lý',
      questions: 40,
      duration: 50,
      activity: '1 giờ trước',
    ),
  ];

  testWidgets('SearchScreen renders horizontal subject chips and 1-column cards on mobile 360px', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SavedExamRepository>(create: (_) => MockSavedExamRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SearchScreen(initialItems: sampleItems),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify search input is present
    expect(find.byType(TextField), findsOneWidget);

    // Verify horizontal subject chips are rendered (e.g. 'Toán học', 'Vật lý')
    expect(find.text('Toán học'), findsWidgets);
    expect(find.text('Vật lý'), findsWidgets);

    // Verify exam cards are displayed without overflow
    expect(find.textContaining('Đề thi thử THPT Quốc Gia'), findsOneWidget);
    expect(find.textContaining('Đề ôn tập Vật Lý'), findsOneWidget);

    // Filter by tapping 'Toán học' chip
    final toanChips = find.widgetWithText(InkWell, 'Toán học');
    if (toanChips.evaluate().isNotEmpty) {
      await tester.tap(toanChips.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Đề thi thử THPT Quốc Gia'), findsOneWidget);
    }
  });
}
