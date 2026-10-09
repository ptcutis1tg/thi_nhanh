import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';
import 'package:onthi_community/screens/home/search_screen.dart';

class FakeSavedExamRepository implements SavedExamRepository {
  final Set<String> _savedExamIds = {};

  FakeSavedExamRepository([Set<String>? initial]) {
    if (initial != null) _savedExamIds.addAll(initial);
  }

  @override
  Future<bool> isExamSaved(String examId) async {
    return _savedExamIds.contains(examId);
  }

  @override
  Future<Set<String>> getSavedExamIds() async {
    return Set.unmodifiable(_savedExamIds);
  }

  @override
  Future<bool> toggleSaveExam(String examId) async {
    if (_savedExamIds.contains(examId)) {
      _savedExamIds.remove(examId);
      return false;
    } else {
      _savedExamIds.add(examId);
      return true;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SearchScreen renders one-touch bookmark button on exam cards and toggles save state', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = FakeSavedExamRepository({'exam_1'});

    final testItems = [
      const SearchExamItem(
        id: 'exam_1',
        code: 'DT1001',
        title: 'Đề Toán 1',
        teacher: 'Thầy A',
        subject: 'Toán học',
        questions: 10,
        duration: 45,
      ),
      const SearchExamItem(
        id: 'exam_2',
        code: 'DT1002',
        title: 'Đề Lý 2',
        teacher: 'Cô B',
        subject: 'Vật lý',
        questions: 10,
        duration: 45,
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SavedExamRepository?>.value(value: fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SearchScreen(initialItems: testItems),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify bookmark buttons exist
    final bookmarkButtons = find.byTooltip('Lưu đề vào kho');
    final savedBookmarkButtons = find.byTooltip('Bỏ lưu đề');
    expect(bookmarkButtons.evaluate().length + savedBookmarkButtons.evaluate().length, equals(2));

    // Toggle save on exam_2
    final exam2Button = bookmarkButtons.first;
    await tester.tap(exam2Button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(await fakeRepo.isExamSaved('exam_2'), isTrue);
  });
}
