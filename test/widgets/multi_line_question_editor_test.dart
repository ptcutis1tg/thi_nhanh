import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/widgets/multi_line_question_editor.dart';

void main() {
  testWidgets('adds, edits, and removes question content lines', (
    tester,
  ) async {
    var value = 'Đề bài';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiLineQuestionEditor(
            initialValue: value,
            onChanged: (updated) => value = updated,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('add-question-content-line')));
    await tester.pump();
    expect(find.text('Thêm dòng'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Khối trực quan [ ]'), findsNothing);
    expect(find.text('Mã nguồn LaTeX'), findsNothing);

    await tester.enterText(find.byType(TextField).last, 'Biểu thức thứ nhất');
    await tester.pump();
    expect(value, 'Đề bài\nBiểu thức thứ nhất');

    await tester.tap(find.byTooltip('Xóa dòng').last);
    await tester.pump();
    expect(value, 'Đề bài');
  });
}
