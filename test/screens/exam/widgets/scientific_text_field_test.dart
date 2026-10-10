import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/scientific_shortcut.dart';
import 'package:onthi_community/screens/exam/widgets/scientific_text_field.dart';

void main() {
  testWidgets('toolbar target inserts at caret instead of appending', (
    tester,
  ) async {
    String value = 'abcd';
    ScientificInputTarget? target;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScientificTextField(
            initialValue: value,
            onChanged: (next) => value = next,
            category: ScientificCategory.math,
            shortcuts: const [],
            fieldLabel: 'Đáp án A',
            onFocused: (next) => target = next,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    field.controller!.selection = const TextSelection.collapsed(offset: 2);
    target!.insertText('X', 0, 0);
    await tester.pump();

    expect(value, 'abXcd');
    expect(field.controller!.selection.baseOffset, 3);
  });

  testWidgets('category shortcut works inside a normal answer field', (
    tester,
  ) async {
    String value = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScientificTextField(
            initialValue: value,
            onChanged: (next) => value = next,
            category: ScientificCategory.chemistry,
            shortcuts:
                ScientificShortcutStore.defaults[ScientificCategory.chemistry]!,
            fieldLabel: 'Đáp án A',
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '/3');
    await tester.pump();
    expect(
      find.byKey(const Key('scientific-field-shortcut-suggestion')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(value, r'$\rightleftharpoons$');
    expect(value, isNot(contains('/3')));
  });
}
