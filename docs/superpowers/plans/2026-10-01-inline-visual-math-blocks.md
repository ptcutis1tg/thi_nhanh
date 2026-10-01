# Inline Visual Math Block Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an inline visual math block editor with interactive clickable empty slots `[ ]` for math components (fractions, roots, exponents, integrals, limits, etc.) within the question editor of `CreateExamScreen`, with 2-in-1 Visual/LaTeX mode and bi-directional LaTeX sync.

**Architecture:** Decompose question text into structured segments (`TextContentSegment` and `MathBlockSegment`). Render math blocks as 2D visual layouts with interactive `VisualSlotInput` widgets that teachers can click and type into. Synchronize slot edits to standard LaTeX in real-time for live preview and Supabase storage.

**Tech Stack:** Flutter, Dart, KaTeX/LatexMathView, Provider, GoRouter.

## Global Constraints
- Target platform: Flutter Web / Mobile (responsive layout)
- Store all questions in Supabase as standard LaTeX in `question.body`
- Maintain existing Live Preview (`LatexMathView`) functionality
- Auto-push rule: commit and push to `origin/main` after completion to trigger GitHub Actions

---

### Task 1: Visual Math Block Data Model & LaTeX Compiler/Parser

**Files:**
- Create: `lib/core/models/visual_math_block.dart`
- Create: `lib/core/utils/visual_math_compiler.dart`
- Test: `test/utils/visual_math_compiler_test.dart`

**Interfaces:**
- Produces:
  - `enum MathBlockType` with values: `fraction`, `sqrt`, `nroot`, `power`, `subscript`, `integral`, `limit`, `logarithm`, `summation`, `vector`, `angle`.
  - `class SlotDefinition`: `key`, `label`, `placeholder`, `defaultWidth`.
  - `sealed class QuestionContentSegment`: `String toLatex()`.
  - `class TextContentSegment extends QuestionContentSegment`: `String text`.
  - `class MathBlockSegment extends QuestionContentSegment`: `String id`, `MathBlockType type`, `Map<String, String> slots`.
  - `class VisualMathCompiler`: `static String compile(List<QuestionContentSegment> segments)`, `static List<QuestionContentSegment> parse(String rawText)`.

- [ ] **Step 1: Write the failing test**

Create `test/utils/visual_math_compiler_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/core/utils/visual_math_compiler.dart';

void main() {
  group('VisualMathCompiler Tests', () {
    test('compiles fraction segment to LaTeX', () {
      final block = MathBlockSegment(
        id: '1',
        type: MathBlockType.fraction,
        slots: {'num': '2x + 1', 'den': 'x - 3'},
      );
      final latex = VisualMathCompiler.compile([
        TextContentSegment('Cho hàm số '),
        block,
        TextContentSegment('. Tìm tập xác định.'),
      ]);
      expect(latex, r'Cho hàm số \frac{2x + 1}{x - 3} . Tìm tập xác định.');
    });

    test('compiles square root and power segments', () {
      final sqrtBlock = MathBlockSegment(
        id: '2',
        type: MathBlockType.sqrt,
        slots: {'radicand': 'x^2 + 1'},
      );
      final powerBlock = MathBlockSegment(
        id: '3',
        type: MathBlockType.power,
        slots: {'base': 'x', 'exp': '3'},
      );
      final latex = VisualMathCompiler.compile([sqrtBlock, TextContentSegment(' + '), powerBlock]);
      expect(latex, r'\sqrt{x^2 + 1} + {x}^{3}');
    });

    test('compiles integral and limit segments', () {
      final integralBlock = MathBlockSegment(
        id: '4',
        type: MathBlockType.integral,
        slots: {'lower': '0', 'upper': '1', 'expr': '2x'},
      );
      expect(integralBlock.toLatex(), r'\int_{0}^{1} {2x} \, dx');

      final limitBlock = MathBlockSegment(
        id: '5',
        type: MathBlockType.limit,
        slots: {'to': '0', 'expr': r'\frac{\sin x}{x}'},
      );
      expect(limitBlock.toLatex(), r'\lim_{x \to 0} {\frac{\sin x}{x}}');
    });

    test('compiles empty slots with placeholders without crashing', () {
      final emptyFraction = MathBlockSegment(id: '6', type: MathBlockType.fraction);
      expect(emptyFraction.toLatex(), r'\frac{\square}{\square}');
    });

    test('parses LaTeX containing fraction and root back into segments', () {
      const input = r'Tính \frac{1}{2} + \sqrt{4}';
      final segments = VisualMathCompiler.parse(input);
      expect(segments.length, 4);
      expect(segments[0], isA<TextContentSegment>());
      expect((segments[0] as TextContentSegment).text, 'Tính ');
      expect(segments[1], isA<MathBlockSegment>());
      final fraction = segments[1] as MathBlockSegment;
      expect(fraction.type, MathBlockType.fraction);
      expect(fraction.slots['num'], '1');
      expect(fraction.slots['den'], '2');
      expect((segments[2] as TextContentSegment).text, ' + ');
      expect(segments[3], isA<MathBlockSegment>());
      final sqrt = segments[3] as MathBlockSegment;
      expect(sqrt.type, MathBlockType.sqrt);
      expect(sqrt.slots['radicand'], '4');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/utils/visual_math_compiler_test.dart`
Expected: FAIL with compilation error (files not created yet).

- [ ] **Step 3: Implement data models in `lib/core/models/visual_math_block.dart`**

```dart
enum MathBlockType {
  fraction,
  sqrt,
  nroot,
  power,
  subscript,
  integral,
  limit,
  logarithm,
  summation,
  vector,
  angle;

  String get label {
    switch (this) {
      case MathBlockType.fraction:
        return 'Phân số';
      case MathBlockType.sqrt:
        return 'Căn bậc 2';
      case MathBlockType.nroot:
        return 'Căn bậc n';
      case MathBlockType.power:
        return 'Số mũ';
      case MathBlockType.subscript:
        return 'Chỉ số';
      case MathBlockType.integral:
        return 'Tích phân';
      case MathBlockType.limit:
        return 'Giới hạn';
      case MathBlockType.logarithm:
        return 'Logarit';
      case MathBlockType.summation:
        return 'Tổng Sigma';
      case MathBlockType.vector:
        return 'Vectơ';
      case MathBlockType.angle:
        return 'Góc';
    }
  }

  List<SlotDefinition> get slotDefinitions {
    switch (this) {
      case MathBlockType.fraction:
        return const [
          SlotDefinition(key: 'num', label: 'Tử số', placeholder: 'tử'),
          SlotDefinition(key: 'den', label: 'Mẫu số', placeholder: 'mẫu'),
        ];
      case MathBlockType.sqrt:
        return const [
          SlotDefinition(key: 'radicand', label: 'Biểu thức', placeholder: 'biểu thức'),
        ];
      case MathBlockType.nroot:
        return const [
          SlotDefinition(key: 'index', label: 'Bậc', placeholder: 'n', defaultWidth: 32),
          SlotDefinition(key: 'radicand', label: 'Biểu thức', placeholder: 'biểu thức'),
        ];
      case MathBlockType.power:
        return const [
          SlotDefinition(key: 'base', label: 'Cơ số', placeholder: 'x'),
          SlotDefinition(key: 'exp', label: 'Số mũ', placeholder: 'mũ', defaultWidth: 36),
        ];
      case MathBlockType.subscript:
        return const [
          SlotDefinition(key: 'base', label: 'Ký hiệu', placeholder: 'x'),
          SlotDefinition(key: 'sub', label: 'Chỉ số', placeholder: 'i', defaultWidth: 36),
        ];
      case MathBlockType.integral:
        return const [
          SlotDefinition(key: 'lower', label: 'Cận dưới', placeholder: 'a', defaultWidth: 32),
          SlotDefinition(key: 'upper', label: 'Cận trên', placeholder: 'b', defaultWidth: 32),
          SlotDefinition(key: 'expr', label: 'Hàm số', placeholder: 'f(x)'),
        ];
      case MathBlockType.limit:
        return const [
          SlotDefinition(key: 'to', label: 'Tiến tới', placeholder: 'x₀', defaultWidth: 36),
          SlotDefinition(key: 'expr', label: 'Biểu thức', placeholder: 'f(x)'),
        ];
      case MathBlockType.logarithm:
        return const [
          SlotDefinition(key: 'base', label: 'Cơ số', placeholder: 'a', defaultWidth: 36),
          SlotDefinition(key: 'arg', label: 'Biểu thức', placeholder: 'b'),
        ];
      case MathBlockType.summation:
        return const [
          SlotDefinition(key: 'from', label: 'Từ', placeholder: 'i=1', defaultWidth: 40),
          SlotDefinition(key: 'to', label: 'Đến', placeholder: 'n', defaultWidth: 36),
          SlotDefinition(key: 'expr', label: 'Biểu thức', placeholder: 'f(i)'),
        ];
      case MathBlockType.vector:
        return const [
          SlotDefinition(key: 'name', label: 'Tên', placeholder: 'v'),
        ];
      case MathBlockType.angle:
        return const [
          SlotDefinition(key: 'name', label: 'Tên góc', placeholder: 'ABC'),
        ];
    }
  }

  String compileToLatex(Map<String, String> slots) {
    String slot(String k) {
      final v = slots[k]?.trim();
      return (v == null || v.isEmpty) ? r'\square' : v;
    }

    switch (this) {
      case MathBlockType.fraction:
        return '\\frac{${slot('num')}}{${slot('den')}}';
      case MathBlockType.sqrt:
        return '\\sqrt{${slot('radicand')}}';
      case MathBlockType.nroot:
        return '\\sqrt[${slot('index')}]{${slot('radicand')}}';
      case MathBlockType.power:
        return '{${slot('base')}}^{${slot('exp')}}';
      case MathBlockType.subscript:
        return '{${slot('base')}}_{${slot('sub')}}';
      case MathBlockType.integral:
        return '\\int_{${slot('lower')}}^{${slot('upper')}} {${slot('expr')}} \\, dx';
      case MathBlockType.limit:
        return '\\lim_{x \\to ${slot('to')}} {${slot('expr')}}';
      case MathBlockType.logarithm:
        return '\\log_{${slot('base')}}({${slot('arg')}})';
      case MathBlockType.summation:
        return '\\sum_{${slot('from')}}^{${slot('to')}} {${slot('expr')}}';
      case MathBlockType.vector:
        return '\\vec{${slot('name')}}';
      case MathBlockType.angle:
        return '\\widehat{${slot('name')}}';
    }
  }
}

class SlotDefinition {
  final String key;
  final String label;
  final String placeholder;
  final double defaultWidth;

  const SlotDefinition({
    required this.key,
    required this.label,
    required this.placeholder,
    this.defaultWidth = 48,
  });
}

sealed class QuestionContentSegment {
  String toLatex();
}

class TextContentSegment extends QuestionContentSegment {
  String text;
  TextContentSegment(this.text);

  @override
  String toLatex() => text;
}

class MathBlockSegment extends QuestionContentSegment {
  final String id;
  final MathBlockType type;
  final Map<String, String> slots;

  MathBlockSegment({
    required this.id,
    required this.type,
    Map<String, String>? slots,
  }) : slots = slots != null ? Map<String, String>.from(slots) : <String, String>{};

  @override
  String toLatex() => type.compileToLatex(slots);

  MathBlockSegment copy() {
    return MathBlockSegment(
      id: id,
      type: type,
      slots: Map<String, String>.from(slots),
    );
  }
}
```

- [ ] **Step 4: Implement compiler and parser in `lib/core/utils/visual_math_compiler.dart`**

```dart
import '../models/visual_math_block.dart';

class VisualMathCompiler {
  static String compile(List<QuestionContentSegment> segments) {
    final buffer = StringBuffer();
    for (final seg in segments) {
      buffer.write(seg.toLatex());
    }
    return buffer.toString();
  }

  static List<QuestionContentSegment> parse(String rawText) {
    if (rawText.isEmpty) return [TextContentSegment('')];

    final segments = <QuestionContentSegment>[];
    int idCounter = 0;

    // Regular expressions matching LaTeX patterns
    final fractionRegex = RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}');
    final sqrtRegex = RegExp(r'\\sqrt\{([^}]+)\}');
    final nrootRegex = RegExp(r'\\sqrt\[([^\]]+)\]\{([^}]+)\}');
    final powerRegex = RegExp(r'\{?([a-zA-Z0-9]+)\}?\^\{([^}]+)\}');
    final integralRegex = RegExp(r'\\int_\{([^}]+)\}\^\{([^}]+)\}\s*\{([^}]+)\}\s*\\,\s*dx');
    final limitRegex = RegExp(r'\\lim_\{x\s*\\to\s*([^}]+)\}\s*\{([^}]+)\}');

    int index = 0;
    while (index < rawText.length) {
      final substring = rawText.substring(index);

      // Check fraction
      final fracMatch = fractionRegex.matchAsPrefix(substring);
      if (fracMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.fraction,
          slots: {
            'num': fracMatch.group(1) == r'\square' ? '' : (fracMatch.group(1) ?? ''),
            'den': fracMatch.group(2) == r'\square' ? '' : (fracMatch.group(2) ?? ''),
          },
        ));
        index += fracMatch.end;
        continue;
      }

      // Check nroot
      final nrootMatch = nrootRegex.matchAsPrefix(substring);
      if (nrootMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.nroot,
          slots: {
            'index': nrootMatch.group(1) == r'\square' ? '' : (nrootMatch.group(1) ?? ''),
            'radicand': nrootMatch.group(2) == r'\square' ? '' : (nrootMatch.group(2) ?? ''),
          },
        ));
        index += nrootMatch.end;
        continue;
      }

      // Check sqrt
      final sqrtMatch = sqrtRegex.matchAsPrefix(substring);
      if (sqrtMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.sqrt,
          slots: {
            'radicand': sqrtMatch.group(1) == r'\square' ? '' : (sqrtMatch.group(1) ?? ''),
          },
        ));
        index += sqrtMatch.end;
        continue;
      }

      // Check integral
      final intMatch = integralRegex.matchAsPrefix(substring);
      if (intMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.integral,
          slots: {
            'lower': intMatch.group(1) ?? '',
            'upper': intMatch.group(2) ?? '',
            'expr': intMatch.group(3) ?? '',
          },
        ));
        index += intMatch.end;
        continue;
      }

      // Check limit
      final limMatch = limitRegex.matchAsPrefix(substring);
      if (limMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.limit,
          slots: {
            'to': limMatch.group(1) ?? '',
            'expr': limMatch.group(2) ?? '',
          },
        ));
        index += limMatch.end;
        continue;
      }

      // Read plain character into trailing TextContentSegment
      if (segments.isNotEmpty && segments.last is TextContentSegment) {
        (segments.last as TextContentSegment).text += rawText[index];
      } else {
        segments.add(TextContentSegment(rawText[index]));
      }
      index++;
    }

    if (segments.isEmpty) {
      segments.add(TextContentSegment(''));
    }
    return segments;
  }
}
```

- [ ] **Step 5: Run tests and verify pass**

Run: `flutter test test/utils/visual_math_compiler_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit Task 1**

```bash
git add lib/core/models/visual_math_block.dart lib/core/utils/visual_math_compiler.dart test/utils/visual_math_compiler_test.dart
git commit -m "feat(math): add visual math block models and bidirectional latex compiler"
```

---

### Task 2: Interactive Visual Slot Input & 2D Math Block Widget

**Files:**
- Create: `lib/screens/exam/widgets/visual_math_slot_input.dart`
- Create: `lib/screens/exam/widgets/visual_math_block_widget.dart`
- Test: `test/widgets/visual_math_block_widget_test.dart`

**Interfaces:**
- Consumes: `MathBlockType`, `MathBlockSegment`, `SlotDefinition` from Task 1.
- Produces:
  - `class VisualSlotInput extends StatefulWidget`: interactive slot text box.
  - `class VisualMathBlockWidget extends StatelessWidget`: renders visual 2D layout for each `MathBlockType`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/visual_math_block_widget_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/screens/exam/widgets/visual_math_block_widget.dart';

void main() {
  testWidgets('VisualMathBlockWidget renders fraction with clickable num and den slots', (tester) async {
    final block = MathBlockSegment(
      id: 'f1',
      type: MathBlockType.fraction,
      slots: {'num': '3', 'den': '5'},
    );

    String? updatedSlot;
    String? updatedVal;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VisualMathBlockWidget(
              block: block,
              onSlotChanged: (key, val) {
                updatedSlot = key;
                updatedVal = val;
              },
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    // Verify slots rendered
    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // Type into numerator slot
    await tester.enterText(find.text('3'), '7');
    expect(updatedSlot, 'num');
    expect(updatedVal, '7');
  });

  testWidgets('VisualMathBlockWidget renders sqrt with radicand slot', (tester) async {
    final block = MathBlockSegment(
      id: 's1',
      type: MathBlockType.sqrt,
      slots: {'radicand': 'x + 1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VisualMathBlockWidget(
              block: block,
              onSlotChanged: (_, __) {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('x + 1'), findsOneWidget);
    expect(find.text('√'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/visual_math_block_widget_test.dart`
Expected: FAIL with compilation error (widgets not created yet).

- [ ] **Step 3: Implement `VisualSlotInput` in `lib/screens/exam/widgets/visual_math_slot_input.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class VisualSlotInput extends StatefulWidget {
  const VisualSlotInput({
    super.key,
    required this.initialValue,
    required this.placeholder,
    required this.onChanged,
    this.minWidth = 38,
    this.fontSize = 14,
    this.autofocus = false,
  });

  final String initialValue;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final double minWidth;
  final double fontSize;
  final bool autofocus;

  @override
  State<VisualSlotInput> createState() => _VisualSlotInputState();
}

class _VisualSlotInputState extends State<VisualSlotInput> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(VisualSlotInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusNode,
      builder: (context, _) {
        final isFocused = _focusNode.hasFocus;
        final textLength = _controller.text.length;
        final dynamicWidth = (textLength * (widget.fontSize * 0.65) + 20).clamp(widget.minWidth, 200.0);

        return Container(
          width: dynamicWidth,
          height: widget.fontSize + 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isFocused ? Colors.white : AppTheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isFocused ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.4),
              width: isFocused ? 1.8 : 1.2,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                fontSize: widget.fontSize * 0.85,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
            onChanged: (val) {
              setState(() {});
              widget.onChanged(val);
            },
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Implement `VisualMathBlockWidget` in `lib/screens/exam/widgets/visual_math_block_widget.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/models/visual_math_block.dart';
import '../../../core/theme/app_theme.dart';
import 'visual_math_slot_input.dart';

class VisualMathBlockWidget extends StatelessWidget {
  const VisualMathBlockWidget({
    super.key,
    required this.block,
    required this.onSlotChanged,
    required this.onDelete,
    this.autofocusFirstSlot = false,
  });

  final MathBlockSegment block;
  final void Function(String slotKey, String value) onSlotChanged;
  final VoidCallback onDelete;
  final bool autofocusFirstSlot;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _buildLayout(context),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    switch (block.type) {
      case MathBlockType.fraction:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VisualSlotInput(
              initialValue: block.slots['num'] ?? '',
              placeholder: 'tử số',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('num', val),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 3),
              constraints: const BoxConstraints(minWidth: 42, maxWidth: 160),
              color: Colors.black87,
            ),
            VisualSlotInput(
              initialValue: block.slots['den'] ?? '',
              placeholder: 'mẫu số',
              onChanged: (val) => onSlotChanged('den', val),
            ),
          ],
        );

      case MathBlockType.sqrt:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('√', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: AppTheme.primary)),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.primary, width: 2)),
              ),
              padding: const EdgeInsets.only(top: 2),
              child: VisualSlotInput(
                initialValue: block.slots['radicand'] ?? '',
                placeholder: 'biểu thức',
                autofocus: autofocusFirstSlot,
                onChanged: (val) => onSlotChanged('radicand', val),
              ),
            ),
          ],
        );

      case MathBlockType.nroot:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(4, -8),
              child: VisualSlotInput(
                initialValue: block.slots['index'] ?? '',
                placeholder: 'n',
                minWidth: 26,
                fontSize: 11,
                autofocus: autofocusFirstSlot,
                onChanged: (val) => onSlotChanged('index', val),
              ),
            ),
            const Text('√', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: AppTheme.primary)),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.primary, width: 2)),
              ),
              padding: const EdgeInsets.only(top: 2),
              child: VisualSlotInput(
                initialValue: block.slots['radicand'] ?? '',
                placeholder: 'biểu thức',
                onChanged: (val) => onSlotChanged('radicand', val),
              ),
            ),
          ],
        );

      case MathBlockType.power:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VisualSlotInput(
              initialValue: block.slots['base'] ?? '',
              placeholder: 'cơ số',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('base', val),
            ),
            Transform.translate(
              offset: const Offset(0, -8),
              child: VisualSlotInput(
                initialValue: block.slots['exp'] ?? '',
                placeholder: 'mũ',
                fontSize: 11,
                minWidth: 28,
                onChanged: (val) => onSlotChanged('exp', val),
              ),
            ),
          ],
        );

      case MathBlockType.subscript:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VisualSlotInput(
              initialValue: block.slots['base'] ?? '',
              placeholder: 'biến',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('base', val),
            ),
            Transform.translate(
              offset: const Offset(0, 8),
              child: VisualSlotInput(
                initialValue: block.slots['sub'] ?? '',
                placeholder: 'chỉ số',
                fontSize: 11,
                minWidth: 28,
                onChanged: (val) => onSlotChanged('sub', val),
              ),
            ),
          ],
        );

      case MathBlockType.integral:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VisualSlotInput(
                  initialValue: block.slots['upper'] ?? '',
                  placeholder: 'b',
                  fontSize: 11,
                  minWidth: 26,
                  onChanged: (val) => onSlotChanged('upper', val),
                ),
                const Text('∫', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: AppTheme.primary)),
                VisualSlotInput(
                  initialValue: block.slots['lower'] ?? '',
                  placeholder: 'a',
                  fontSize: 11,
                  minWidth: 26,
                  autofocus: autofocusFirstSlot,
                  onChanged: (val) => onSlotChanged('lower', val),
                ),
              ],
            ),
            const SizedBox(width: 4),
            VisualSlotInput(
              initialValue: block.slots['expr'] ?? '',
              placeholder: 'f(x)',
              onChanged: (val) => onSlotChanged('expr', val),
            ),
            const SizedBox(width: 4),
            const Text('dx', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
          ],
        );

      case MathBlockType.limit:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('lim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('x→', style: TextStyle(fontSize: 11)),
                    VisualSlotInput(
                      initialValue: block.slots['to'] ?? '',
                      placeholder: 'x₀',
                      fontSize: 10,
                      minWidth: 26,
                      autofocus: autofocusFirstSlot,
                      onChanged: (val) => onSlotChanged('to', val),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            VisualSlotInput(
              initialValue: block.slots['expr'] ?? '',
              placeholder: 'f(x)',
              onChanged: (val) => onSlotChanged('expr', val),
            ),
          ],
        );

      case MathBlockType.logarithm:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('log', style: TextStyle(fontWeight: FontWeight.bold)),
            Transform.translate(
              offset: const Offset(0, 6),
              child: VisualSlotInput(
                initialValue: block.slots['base'] ?? '',
                placeholder: 'a',
                fontSize: 10,
                minWidth: 24,
                autofocus: autofocusFirstSlot,
                onChanged: (val) => onSlotChanged('base', val),
              ),
            ),
            const Text('('),
            VisualSlotInput(
              initialValue: block.slots['arg'] ?? '',
              placeholder: 'b',
              onChanged: (val) => onSlotChanged('arg', val),
            ),
            const Text(')'),
          ],
        );

      case MathBlockType.summation:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VisualSlotInput(
                  initialValue: block.slots['to'] ?? '',
                  placeholder: 'n',
                  fontSize: 10,
                  minWidth: 26,
                  onChanged: (val) => onSlotChanged('to', val),
                ),
                const Text('∑', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                VisualSlotInput(
                  initialValue: block.slots['from'] ?? '',
                  placeholder: 'i=1',
                  fontSize: 10,
                  minWidth: 32,
                  autofocus: autofocusFirstSlot,
                  onChanged: (val) => onSlotChanged('from', val),
                ),
              ],
            ),
            const SizedBox(width: 4),
            VisualSlotInput(
              initialValue: block.slots['expr'] ?? '',
              placeholder: 'f(i)',
              onChanged: (val) => onSlotChanged('expr', val),
            ),
          ],
        );

      case MathBlockType.vector:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('→', style: TextStyle(fontSize: 14, height: 0.8, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            VisualSlotInput(
              initialValue: block.slots['name'] ?? '',
              placeholder: 'v',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('name', val),
            ),
          ],
        );

      case MathBlockType.angle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('^', style: TextStyle(fontSize: 14, height: 0.8, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            VisualSlotInput(
              initialValue: block.slots['name'] ?? '',
              placeholder: 'ABC',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('name', val),
            ),
          ],
        );
    }
  }
}
```

- [ ] **Step 5: Run tests and verify pass**

Run: `flutter test test/widgets/visual_math_block_widget_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit Task 2**

```bash
git add lib/screens/exam/widgets/visual_math_slot_input.dart lib/screens/exam/widgets/visual_math_block_widget.dart test/widgets/visual_math_block_widget_test.dart
git commit -m "feat(math): add VisualSlotInput and 2D VisualMathBlockWidget with interactive slots"
```

---

### Task 3: Inline Visual Math Editor & Dual-Mode Controller

**Files:**
- Create: `lib/screens/exam/widgets/inline_visual_math_editor.dart`
- Test: `test/widgets/inline_visual_math_editor_test.dart`

**Interfaces:**
- Consumes: `VisualMathCompiler`, `MathBlockSegment`, `VisualMathBlockWidget`.
- Produces:
  - `class InlineVisualMathEditor extends StatefulWidget`:
    - Parameters: `String initialLatex`, `ValueChanged<String> onChanged`.
    - Public method / Controller: `void insertMathBlock(MathBlockType type)`.
    - Renders dual-mode header (Visual Blocks / Raw LaTeX).
    - Renders mixed list of text input fields and visual math blocks with empty slots.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/inline_visual_math_editor_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/screens/exam/widgets/inline_visual_math_editor.dart';

void main() {
  testWidgets('InlineVisualMathEditor toggles between visual blocks and raw latex', (tester) async {
    String currentLatex = r'Cho hàm số \frac{1}{2}';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InlineVisualMathEditor(
            initialLatex: currentLatex,
            onChanged: (val) => currentLatex = val,
          ),
        ),
      ),
    );

    // Initial mode is Visual Blocks: shows fraction slots '1' and '2'
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Tap raw latex mode button
    await tester.tap(find.text('Mã nguồn LaTeX'));
    await tester.pumpAndSettle();

    // Now raw LaTeX field is visible
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/inline_visual_math_editor_test.dart`
Expected: FAIL with compilation error (editor not created yet).

- [ ] **Step 3: Implement `InlineVisualMathEditor` in `lib/screens/exam/widgets/inline_visual_math_editor.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/models/visual_math_block.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/visual_math_compiler.dart';
import 'visual_math_block_widget.dart';

class InlineVisualMathEditor extends StatefulWidget {
  const InlineVisualMathEditor({
    super.key,
    required this.initialLatex,
    required this.onChanged,
    this.controller,
  });

  final String initialLatex;
  final ValueChanged<String> onChanged;
  final InlineVisualMathEditorController? controller;

  @override
  State<InlineVisualMathEditor> createState() => _InlineVisualMathEditorState();
}

class InlineVisualMathEditorController {
  _InlineVisualMathEditorState? _state;

  void insertMathBlock(MathBlockType type) {
    _state?.insertMathBlock(type);
  }
}

class _InlineVisualMathEditorState extends State<InlineVisualMathEditor> {
  bool _isVisualMode = true;
  late List<QuestionContentSegment> _segments;
  late TextEditingController _rawLatexController;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _segments = VisualMathCompiler.parse(widget.initialLatex);
    _rawLatexController = TextEditingController(text: widget.initialLatex);
  }

  @override
  void didUpdateWidget(InlineVisualMathEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      widget.controller!._state = this;
    }
  }

  @override
  void dispose() {
    _rawLatexController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final latex = _isVisualMode
        ? VisualMathCompiler.compile(_segments)
        : _rawLatexController.text;
    widget.onChanged(latex);
  }

  void insertMathBlock(MathBlockType type) {
    setState(() {
      final newBlock = MathBlockSegment(
        id: 'mb_${DateTime.now().microsecondsSinceEpoch}',
        type: type,
      );
      _segments.add(newBlock);
      _segments.add(TextContentSegment(' '));
      _rawLatexController.text = VisualMathCompiler.compile(_segments);
    });
    _notifyChange();
  }

  void _switchMode(bool toVisual) {
    if (_isVisualMode == toVisual) return;
    setState(() {
      if (toVisual) {
        // Sync raw LaTeX back into segments
        _segments = VisualMathCompiler.parse(_rawLatexController.text);
      } else {
        // Sync segments to raw LaTeX
        _rawLatexController.text = VisualMathCompiler.compile(_segments);
      }
      _isVisualMode = toVisual;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Switcher Header
        Row(
          children: [
            InkWell(
              onTap: () => _switchMode(true),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isVisualMode ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isVisualMode ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dashboard_customize_outlined, size: 14, color: _isVisualMode ? AppTheme.primary : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Khối trực quan [ ]',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isVisualMode ? FontWeight.bold : FontWeight.w500,
                        color: _isVisualMode ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _switchMode(false),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: !_isVisualMode ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: !_isVisualMode ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code_rounded, size: 14, color: !_isVisualMode ? AppTheme.primary : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Mã nguồn LaTeX',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isVisualMode ? FontWeight.bold : FontWeight.w500,
                        color: !_isVisualMode ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Editor Body
        if (!_isVisualMode)
          TextFormField(
            controller: _rawLatexController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: r'Nhập công thức dạng \frac{a}{b} hoặc văn bản...',
            ),
            onChanged: (val) => _notifyChange(),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < _segments.length; i++)
                  if (_segments[i] is TextContentSegment)
                    _buildTextSegmentWidget(i, _segments[i] as TextContentSegment)
                  else if (_segments[i] is MathBlockSegment)
                    VisualMathBlockWidget(
                      key: ValueKey((_segments[i] as MathBlockSegment).id),
                      block: _segments[i] as MathBlockSegment,
                      onSlotChanged: (k, v) {
                        (_segments[i] as MathBlockSegment).slots[k] = v;
                        _notifyChange();
                      },
                      onDelete: () {
                        setState(() {
                          _segments.removeAt(i);
                        });
                        _notifyChange();
                      },
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextSegmentWidget(int index, TextContentSegment seg) {
    return IntrinsicWidth(
      child: TextField(
        controller: TextEditingController(text: seg.text)..selection = TextSelection.collapsed(offset: seg.text.length),
        style: const TextStyle(fontSize: 15, height: 1.5),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
          hintText: _segments.length <= 1 ? 'Nhập nội dung đề bài...' : '',
        ),
        onChanged: (val) {
          seg.text = val;
          _notifyChange();
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests and verify pass**

Run: `flutter test test/widgets/inline_visual_math_editor_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit Task 3**

```bash
git add lib/screens/exam/widgets/inline_visual_math_editor.dart test/widgets/inline_visual_math_editor_test.dart
git commit -m "feat(math): add InlineVisualMathEditor with dual-mode toggle and visual block composition"
```

---

### Task 4: Connect Bottom Toolbar with Visual Editor in `CreateExamScreen`

**Files:**
- Modify: `lib/screens/exam/widgets/scientific_bottom_toolbar.dart`
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Test: `test/screens/create_exam_screen_test.dart`

**Interfaces:**
- Consumes: `InlineVisualMathEditor`, `InlineVisualMathEditorController`, `MathBlockType`.
- Changes:
  - Add optional `void Function(MathBlockType type)? onInsertMathBlock` to `ScientificBottomToolbar`.
  - When teacher clicks math snippets (Fraction, Root, Power, Integral, etc.), dispatch `onInsertMathBlock` to the active `InlineVisualMathEditorController`.
  - In `CreateExamScreen`: replace plain question `TextFormField` with `InlineVisualMathEditor`.
  - Live Preview updates dynamically.

- [ ] **Step 1: Write the failing test**

In `test/screens/create_exam_screen_test.dart`, add test case for inserting math block:
```dart
    testWidgets('tapping fraction on bottom toolbar inserts visual fraction block into editor', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const CreateExamScreen()));
      await tester.pumpAndSettle();

      // Configure setup screen
      await tester.enterText(find.byKey(const Key('setup-name')), 'Đề kiểm tra Toán');
      await tester.tap(find.byKey(const Key('setup-continue')));
      await tester.pumpAndSettle();

      // Tap Fraction on ScientificBottomToolbar
      final fracBtn = find.text('□/□');
      expect(fracBtn, findsOneWidget);
      await tester.tap(fracBtn);
      await tester.pumpAndSettle();

      // Verify fraction block slots are present in question editor
      expect(find.byType(VisualMathBlockWidget), findsOneWidget);
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/create_exam_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Update `ScientificBottomToolbar` to accept `onInsertMathBlock`**

In `lib/screens/exam/widgets/scientific_bottom_toolbar.dart`:
Add parameter:
```dart
  final void Function(MathBlockType type)? onInsertMathBlock;
```
And inside snippet onTap handler:
```dart
  if (item.label == '□/□' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.fraction);
  } else if (item.label == '√□' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.sqrt);
  } else if (item.label == 'ⁿ√□' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.nroot);
  } else if (item.label == 'xⁿ' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.power);
  } else if (item.label == 'xₙ' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.subscript);
  } else if (item.label == '∫' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.integral);
  } else if (item.label == 'lim' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.limit);
  } else if (item.label == 'log' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.logarithm);
  } else if (item.label == '∑' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.summation);
  } else if (item.label == '→' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.vector);
  } else if (item.label == '∠' && widget.onInsertMathBlock != null) {
    widget.onInsertMathBlock!(MathBlockType.angle);
  } else {
    widget.onInsertSnippet(str, item.selectionOffset, item.selectionLength);
  }
```

- [ ] **Step 4: Update `CreateExamScreen` to embed `InlineVisualMathEditor`**

In `lib/screens/exam/create_exam_screen.dart`:
- Instantiate `final _editorController = InlineVisualMathEditorController();`
- Replace plain `TextFormField` of `question.body` with:
```dart
InlineVisualMathEditor(
  key: ValueKey('editor-${question.id}'),
  initialLatex: question.body,
  controller: _editorController,
  onChanged: (latex) {
    question.body = latex;
    setState(() {});
  },
)
```
- In `ScientificBottomToolbar`:
```dart
ScientificBottomToolbar(
  onInsertSnippet: _insertSnippetAtCursor,
  onInsertMathBlock: (type) => _editorController.insertMathBlock(type),
)
```

- [ ] **Step 5: Run tests to verify pass**

Run: `flutter test test/screens/create_exam_screen_test.dart`
Run: `flutter test`
Expected: ALL tests pass.

- [ ] **Step 6: Commit and Push**

```bash
git add lib/screens/exam/widgets/scientific_bottom_toolbar.dart lib/screens/exam/create_exam_screen.dart test/screens/create_exam_screen_test.dart
git commit -m "feat(exam): integrate inline visual math blocks editor with clickable slots into CreateExamScreen"
git push origin main
```
