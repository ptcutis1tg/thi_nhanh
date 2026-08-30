import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onthi_community/screens/exam/create_exam_screen.dart';

void main() {
  testWidgets('switching questions keeps each question draft independent', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: CreateExamScreen()));

    await tester.enterText(find.byKey(const Key('setup-name')), 'Practice exam');
    await tester.tap(find.byKey(const Key('setup-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toán').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('setup-continue')));
    await tester.tap(find.byKey(const Key('setup-continue')));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'Question one content');
    await tester.tap(find.byKey(const Key('add-question')));
    await tester.pump();
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).initialValue, isEmpty);

    await tester.tap(find.byKey(const Key('question-list-0')));
    await tester.pump();
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).initialValue, 'Question one content');
  });
}
