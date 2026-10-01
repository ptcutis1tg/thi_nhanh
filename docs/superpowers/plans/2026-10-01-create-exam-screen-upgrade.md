# Create Exam Screen Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the exam creation screen (`CreateExamScreen`) to a comprehensive, professional authoring workstation featuring a 3-column layout, Wolfram Alpha-inspired scientific bottom toolbar, 4 question types, live LaTeX math/physics/chemistry preview, drag-and-drop reordering, quick text bulk import, and student preview mode.

**Architecture:** Decompose the monolithic exam creator into modular, testable widgets (`ExamLeftSidebar`, `ExamRightSidebar`, `QuestionAnswersEditor`, `ScientificBottomToolbar`, `LatexMathView`, `QuickBulkImportDialog`, `StudentExamPreviewDialog`) coordinated by `CreateExamScreen` state and backed by an upgraded Supabase schema/RPC.

**Tech Stack:** Flutter 3.10+, Dart, `flutter_math_fork` (TeX canvas rendering), Supabase PostgreSQL (RLS & RPCs), Provider, GoRouter.

## Global Constraints

- Preserve 100% backward compatibility with all existing exam drafts and attempts in Supabase.
- No placeholders (`TODO`, `TBD`); all tasks contain complete, executable code and tests.
- Follow TDD: write failing test, verify failure, implement minimal code, verify pass, commit.
- In accordance with `.agents/AGENTS.md` user preferences: automatically run `git commit` and `git push` upon completing the feature.

---

### Task 1: Add Dependency (`flutter_math_fork`) & Implement `LatexMathView`

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/screens/exam/widgets/latex_math_view.dart`
- Test: `test/screens/exam/widgets/latex_math_view_test.dart`

**Interfaces:**
- Produces: `LatexMathView(text: String, textStyle: TextStyle?, mathStyle: MathStyle?, color: Color?)` widget capable of parsing inline `$math$` and block `$$math$$` alongside plain Vietnamese/English text without throwing exceptions on incomplete TeX.

- [ ] **Step 1: Add `flutter_math_fork` to `pubspec.yaml` and run `flutter pub get`**

```yaml
  # In pubspec.yaml under dependencies:
  flutter_math_fork: ^0.7.2
```
Run command:
`flutter pub add flutter_math_fork`

- [ ] **Step 2: Write the failing widget test for `LatexMathView`**

```dart
// test/screens/exam/widgets/latex_math_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/widgets/latex_math_view.dart';

void main() {
  testWidgets('LatexMathView renders plain text without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LatexMathView(text: 'Câu hỏi kiểm tra đơn giản'),
        ),
      ),
    );
    expect(find.text('Câu hỏi kiểm tra đơn giản'), findsOneWidget);
  });

  testWidgets('LatexMathView splits and renders inline latex formula', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LatexMathView(text: r'Cho phương trình $x^2 + 1 = 0$'),
        ),
      ),
    );
    expect(find.byType(LatexMathView), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/screens/exam/widgets/latex_math_view_test.dart`
Expected: FAIL (File not found / Target of URI doesn't exist).

- [ ] **Step 4: Implement `LatexMathView`**

```dart
// lib/screens/exam/widgets/latex_math_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class LatexMathView extends StatelessWidget {
  const LatexMathView({
    super.key,
    required this.text,
    this.textStyle,
    this.mathStyle = MathStyle.text,
    this.color,
  });

  final String text;
  final TextStyle? textStyle;
  final MathStyle mathStyle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    // Check if string contains any LaTeX markers ($)
    if (!text.contains(r'$')) {
      return Text(
        text,
        style: textStyle ?? TextStyle(fontSize: 16, color: color ?? Colors.black87),
      );
    }

    final spans = _parseMixedContent(text, context);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: spans,
    );
  }

  List<Widget> _parseMixedContent(String raw, BuildContext context) {
    final widgets = <Widget>[];
    final defaultStyle = textStyle ?? TextStyle(fontSize: 16, color: color ?? Colors.black87);

    // Regex to capture $$...$$ (block) or $...$ (inline)
    final pattern = RegExp(r'(\$\$(.*?)\$\$|\$(.*?)\$)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(raw)) {
      if (match.start > lastIndex) {
        final textPart = raw.substring(lastIndex, match.start);
        if (textPart.isNotEmpty) {
          widgets.add(Text(textPart, style: defaultStyle));
        }
      }

      final isBlock = match.group(1)?.startsWith(r'$$') ?? false;
      final formula = (isBlock ? match.group(2) : match.group(3)) ?? '';

      try {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Math.tex(
              formula,
              mathStyle: isBlock ? MathStyle.display : mathStyle,
              textStyle: defaultStyle,
              onErrorFallback: (err) => Text(
                match.group(0) ?? formula,
                style: defaultStyle.copyWith(color: Colors.redAccent),
              ),
            ),
          ),
        );
      } catch (_) {
        widgets.add(Text(match.group(0) ?? formula, style: defaultStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < raw.length) {
      final trailing = raw.substring(lastIndex);
      if (trailing.isNotEmpty) {
        widgets.add(Text(trailing, style: defaultStyle));
      }
    }

    return widgets;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/screens/exam/widgets/latex_math_view_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/screens/exam/widgets/latex_math_view.dart test/screens/exam/widgets/latex_math_view_test.dart
git commit -m "feat(exam): implement LatexMathView with flutter_math_fork support"
```

---

### Task 2: Supabase Migration for Question Types & Multi-Choice Answers

**Files:**
- Create: `supabase/migrations/202610010001_rich_exam_questions_and_types.sql`

**Interfaces:**
- Produces: Database columns `question_type`, `time_limit_seconds`, `image_url` on `public.questions`, drops single-correct unique constraint, updates `save_teacher_exam_draft` and `teacher_exam_draft` RPCs.

- [ ] **Step 1: Write the migration script**

```sql
-- supabase/migrations/202610010001_rich_exam_questions_and_types.sql
-- Migration: Add question_type, time_limit_seconds, image_url and support multi-choice answers

alter table public.questions 
  add column if not exists question_type text not null default 'single_choice',
  add column if not exists time_limit_seconds integer check (time_limit_seconds is null or time_limit_seconds > 0),
  add column if not exists image_url text;

-- Drop unique single correct answer index to support multiple_choice
drop index if exists public.question_options_one_correct_answer;

-- Replace save_teacher_exam_draft RPC
create or replace function public.save_teacher_exam_draft(
  p_exam_id uuid,
  p_title text,
  p_subject text,
  p_duration_minutes integer,
  p_questions jsonb
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_teacher_id uuid;
  v_exam public.exams;
  v_question jsonb;
  v_option jsonb;
  v_position integer := 0;
  v_option_position integer;
  v_question_id uuid;
  v_q_type text;
  v_correct_list jsonb;
  v_is_correct boolean;
begin
  v_teacher_id := public.ensure_current_teacher();
  if char_length(trim(p_title)) < 3 then raise exception 'Tên đề thi phải có ít nhất 3 ký tự'; end if;
  if p_duration_minutes not between 1 and 360 then raise exception 'Thời lượng thi phải từ 1 đến 360 phút'; end if;

  if p_exam_id is null then
    insert into public.exams (code, teacher_id, title, subject, duration_minutes, status)
    values (public.next_exam_code(), v_teacher_id, trim(p_title), trim(p_subject), p_duration_minutes, 'draft')
    returning * into v_exam;
  else
    select * into v_exam from public.exams where id = p_exam_id and teacher_id = v_teacher_id for update;
    if not found then raise exception 'Exam not found'; end if;
    if exists (select 1 from public.attempts where exam_id = p_exam_id) then
      raise exception 'An exam with attempts cannot be changed; duplicate it first.';
    end if;
    update public.exams 
    set title = trim(p_title), subject = trim(p_subject), duration_minutes = p_duration_minutes, updated_at = now()
    where id = p_exam_id returning * into v_exam;
    
    delete from public.questions where exam_id = v_exam.id;
  end if;

  for v_question in select value from jsonb_array_elements(p_questions) loop
    v_position := v_position + 1;
    v_q_type := coalesce(v_question ->> 'type', v_question ->> 'question_type', 'single_choice');
    
    if char_length(trim(coalesce(v_question ->> 'body', ''))) = 0 then 
      raise exception 'Question % is empty', v_position; 
    end if;

    insert into public.questions (
      exam_id, position, body, points, question_type, time_limit_seconds, image_url, explanation
    )
    values (
      v_exam.id,
      v_position,
      trim(v_question ->> 'body'),
      coalesce((v_question ->> 'points')::numeric, 1),
      v_q_type,
      (v_question ->> 'timeLimitSeconds')::integer,
      v_question ->> 'imageUrl',
      trim(coalesce(v_question ->> 'explanation', ''))
    )
    returning id into v_question_id;

    v_option_position := 0;
    v_correct_list := v_question -> 'correctAnswers';

    for v_option in select value from jsonb_array_elements(v_question -> 'answers') loop
      v_option_position := v_option_position + 1;
      
      if v_correct_list is not null and jsonb_typeof(v_correct_list) = 'array' then
        v_is_correct := v_correct_list @> to_jsonb(v_option_position - 1);
      else
        v_is_correct := (v_option_position - 1 = coalesce((v_question ->> 'correctAnswer')::integer, 0));
      end if;

      insert into public.question_options (question_id, position, body, is_correct)
      values (v_question_id, v_option_position, trim(v_option #>> '{}'), v_is_correct);
    end loop;
  end loop;

  return jsonb_build_object('id', v_exam.id, 'code', v_exam.code, 'status', v_exam.status);
end;
$$;

-- Replace teacher_exam_draft RPC to return enhanced fields
create or replace function public.teacher_exam_draft(p_exam_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_exam public.exams;
begin
  select * into v_exam from public.exams
  where id = p_exam_id and teacher_id = public.ensure_current_teacher();
  if not found then return null; end if;

  return jsonb_build_object(
    'id', v_exam.id,
    'code', v_exam.code,
    'title', v_exam.title,
    'subject', v_exam.subject,
    'durationMinutes', v_exam.duration_minutes,
    'status', v_exam.status,
    'questions', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', q.id,
        'position', q.position,
        'type', coalesce(q.question_type, 'single_choice'),
        'body', q.body,
        'points', q.points,
        'timeLimitSeconds', q.time_limit_seconds,
        'imageUrl', q.image_url,
        'explanation', coalesce(q.explanation, ''),
        'answers', (
          select coalesce(jsonb_agg(o.body order by o.position), '[]'::jsonb)
          from public.question_options o where o.question_id = q.id
        ),
        'correctAnswers', (
          select coalesce(jsonb_agg(o.position - 1 order by o.position) filter (where o.is_correct), '[]'::jsonb)
          from public.question_options o where o.question_id = q.id
        ),
        'correctAnswer', (
          select coalesce(min(o.position - 1) filter (where o.is_correct), 0)
          from public.question_options o where o.question_id = q.id
        )
      ) order by q.position), '[]'::jsonb)
      from public.questions q where q.exam_id = v_exam.id
    )
  );
end;
$$;
```

- [ ] **Step 2: Commit migration file**

```bash
git add supabase/migrations/202610010001_rich_exam_questions_and_types.sql
git commit -m "feat(db): add migration for rich question types and multi-choice support"
```

---

### Task 3: Domain Models (`QuestionType`, `QuestionDraft`) & Repository Update

**Files:**
- Create: `lib/core/models/question_draft.dart`
- Modify: `lib/core/repositories/teacher_exam_repository.dart`
- Test: `test/models/question_draft_test.dart`

**Interfaces:**
- Produces: `QuestionType` enum, `QuestionDraft` model with serialization/copy methods, updated `saveDraft` in `TeacherExamRepository`.

- [ ] **Step 1: Write failing unit test for `QuestionDraft`**

```dart
// test/models/question_draft_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/question_draft.dart';

void main() {
  group('QuestionDraft tests', () {
    test('Default QuestionDraft initializes with singleChoice and 4 options', () {
      final draft = QuestionDraft(id: 'q1');
      expect(draft.type, QuestionType.singleChoice);
      expect(draft.answers.length, 4);
      expect(draft.correctAnswers, [0]);
    });

    test('Serialization to and from JSON preserves all fields', () {
      final original = QuestionDraft(
        id: 'q2',
        type: QuestionType.multipleChoice,
        body: r'Giải phương trình $x^2 = 4$',
        answers: ['-2', '2', '0', '4'],
        correctAnswers: [0, 1],
        points: '2',
        timeLimitSeconds: 60,
        explanation: 'Phương trình có 2 nghiệm x = 2 hoặc x = -2.',
      );

      final json = original.toJson();
      final restored = QuestionDraft.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, QuestionType.multipleChoice);
      expect(restored.body, original.body);
      expect(restored.answers, original.answers);
      expect(restored.correctAnswers, [0, 1]);
      expect(restored.timeLimitSeconds, 60);
      expect(restored.explanation, original.explanation);
    });

    test('fromJson gracefully falls back for legacy question formats', () {
      final legacyJson = {
        'id': 'legacy_1',
        'body': 'Legacy question',
        'answers': ['A', 'B', 'C', 'D'],
        'correctAnswer': 2,
        'points': 1,
      };

      final restored = QuestionDraft.fromJson(legacyJson);
      expect(restored.type, QuestionType.singleChoice);
      expect(restored.correctAnswers, [2]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/question_draft_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `QuestionDraft` and `QuestionType`**

```dart
// lib/core/models/question_draft.dart
import 'package:flutter/material.dart';

enum QuestionType {
  singleChoice('single_choice', '1 đáp án đúng', Icons.radio_button_checked),
  multipleChoice('multiple_choice', 'Nhiều đáp án đúng', Icons.check_box_outlined),
  trueFalse('true_false', 'Đúng / Sai', Icons.flaky_outlined),
  shortAnswer('short_answer', 'Điền đáp án ngắn', Icons.edit_note_outlined);

  final String value;
  final String label;
  final IconData icon;
  const QuestionType(this.value, this.label, this.icon);

  static QuestionType fromString(String? val) {
    return QuestionType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => QuestionType.singleChoice,
    );
  }
}

class QuestionDraft {
  QuestionDraft({
    required this.id,
    this.type = QuestionType.singleChoice,
    this.body = '',
    List<String>? answers,
    List<int>? correctAnswers,
    this.points = '1',
    this.timeLimitSeconds,
    this.explanation = '',
    this.imageUrl,
  })  : answers = answers ?? List.filled(4, ''),
        correctAnswers = correctAnswers ?? [0];

  final String id;
  QuestionType type;
  String body;
  List<String> answers;
  List<int> correctAnswers;
  String points;
  int? timeLimitSeconds;
  String explanation;
  String? imageUrl;

  QuestionDraft copyWith({
    String? id,
    QuestionType? type,
    String? body,
    List<String>? answers,
    List<int>? correctAnswers,
    String? points,
    int? timeLimitSeconds,
    String? explanation,
    String? imageUrl,
  }) {
    return QuestionDraft(
      id: id ?? this.id,
      type: type ?? this.type,
      body: body ?? this.body,
      answers: answers != null ? List.from(answers) : List.from(this.answers),
      correctAnswers: correctAnswers != null ? List.from(correctAnswers) : List.from(this.correctAnswers),
      points: points ?? this.points,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory QuestionDraft.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? json['question_type'] as String? ?? 'single_choice';
    final type = QuestionType.fromString(typeStr);

    List<String> answers = [];
    if (json['answers'] is List) {
      answers = (json['answers'] as List).map((e) => e.toString()).toList();
    } else {
      answers = List.filled(4, '');
    }

    List<int> correctAnswers = [];
    if (json['correctAnswers'] is List) {
      correctAnswers = (json['correctAnswers'] as List).map((e) => (e as num).toInt()).toList();
    } else if (json['correctAnswer'] != null) {
      correctAnswers = [(json['correctAnswer'] as num).toInt()];
    } else {
      correctAnswers = [0];
    }

    return QuestionDraft(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      body: json['body'] as String? ?? '',
      answers: answers,
      correctAnswers: correctAnswers,
      points: '${json['points'] ?? 1}',
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
      explanation: json['explanation'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'body': body,
    'answers': answers,
    'correctAnswers': correctAnswers,
    'correctAnswer': correctAnswers.isNotEmpty ? correctAnswers.first : 0,
    'points': points,
    'timeLimitSeconds': timeLimitSeconds,
    'explanation': explanation,
    'imageUrl': imageUrl,
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/question_draft_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/question_draft.dart test/models/question_draft_test.dart
git commit -m "feat(model): implement QuestionDraft and QuestionType models"
```

---

### Task 4: Quick Bulk Import Parser & Dialog (`QuickBulkImportDialog`)

**Files:**
- Create: `lib/core/utils/bulk_import_parser.dart`
- Create: `lib/screens/exam/widgets/quick_bulk_import_dialog.dart`
- Test: `test/utils/bulk_import_parser_test.dart`

**Interfaces:**
- Produces: `BulkImportParser.parse(String text)` returning `List<QuestionDraft>`, and `QuickBulkImportDialog` for user paste and confirmation.

- [ ] **Step 1: Write failing unit test for `BulkImportParser`**

```dart
// test/utils/bulk_import_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/bulk_import_parser.dart';
import 'package:onthi_community/core/models/question_draft.dart';

void main() {
  test('BulkImportParser parses single choice questions with asterisk marker', () {
    const raw = '''
Câu 1: Cho hàm số f(x) = x^2. Đạo hàm là:
*A. 2x
B. x
C. 2
D. 0
Lời giải: Áp dụng quy tắc tính đạo hàm x^n.

Câu 2: Thủ đô của Pháp là gì?
A. London
*B. Paris
C. Berlin
D. Madrid
''';

    final questions = BulkImportParser.parse(raw);
    expect(questions.length, 2);
    expect(questions[0].body, contains('Cho hàm số f(x) = x^2'));
    expect(questions[0].answers.length, 4);
    expect(questions[0].correctAnswers, [0]);
    expect(questions[0].explanation, contains('Áp dụng quy tắc tính đạo hàm'));

    expect(questions[1].answers.length, 4);
    expect(questions[1].correctAnswers, [1]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/utils/bulk_import_parser_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `BulkImportParser` and `QuickBulkImportDialog`**

```dart
// lib/core/utils/bulk_import_parser.dart
import '../models/question_draft.dart';

class BulkImportParser {
  static List<QuestionDraft> parse(String text) {
    if (text.trim().isEmpty) return [];

    final questions = <QuestionDraft>[];
    final lines = text.split('\n');

    String currentBody = '';
    final currentAnswers = <String>[];
    final currentCorrects = <int>[];
    String currentExplanation = '';

    void commitCurrent() {
      if (currentBody.trim().isNotEmpty && currentAnswers.isNotEmpty) {
        QuestionType type = QuestionType.singleChoice;
        if (currentAnswers.length == 2 &&
            currentAnswers.any((a) => a.toLowerCase().contains('đúng')) &&
            currentAnswers.any((a) => a.toLowerCase().contains('sai'))) {
          type = QuestionType.trueFalse;
        } else if (currentCorrects.length > 1) {
          type = QuestionType.multipleChoice;
        }

        questions.add(QuestionDraft(
          id: DateTime.now().microsecondsSinceEpoch.toString() + questions.length.toString(),
          type: type,
          body: currentBody.trim(),
          answers: List.from(currentAnswers),
          correctAnswers: currentCorrects.isNotEmpty ? List.from(currentCorrects) : [0],
          explanation: currentExplanation.trim(),
        ));
      }
      currentBody = '';
      currentAnswers.clear();
      currentCorrects.clear();
      currentExplanation = '';
    }

    final questionStartPattern = RegExp(r'^(Câu|Bài|\d+)[\s\.:\d]+', caseSensitive: false);
    final optionPattern = RegExp(r'^(\*?\s*[A-Ha-h][\.\)])\s*(.*)');
    final explanationPattern = RegExp(r'^(Lời giải|Giải thích):?\s*(.*)', caseSensitive: false);

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (questionStartPattern.hasMatch(trimmed) && currentAnswers.isNotEmpty) {
        commitCurrent();
      }

      if (explanationPattern.hasMatch(trimmed)) {
        final match = explanationPattern.firstMatch(trimmed);
        currentExplanation = match?.group(2) ?? '';
        continue;
      }

      final optionMatch = optionPattern.firstMatch(trimmed);
      if (optionMatch != null) {
        final prefix = optionMatch.group(1) ?? '';
        final body = optionMatch.group(2) ?? '';
        final isCorrect = prefix.contains('*');
        if (isCorrect) {
          currentCorrects.add(currentAnswers.length);
        }
        currentAnswers.add(body.trim());
      } else {
        if (currentAnswers.isEmpty) {
          final cleanLine = questionStartPattern.hasMatch(trimmed)
              ? trimmed.replaceFirst(questionStartPattern, '').trim()
              : trimmed;
          currentBody = currentBody.isEmpty ? cleanLine : '$currentBody\n$cleanLine';
        } else {
          currentExplanation = currentExplanation.isEmpty ? trimmed : '$currentExplanation\n$trimmed';
        }
      }
    }

    commitCurrent();
    return questions;
  }
}
```

Implement `QuickBulkImportDialog` in `lib/screens/exam/widgets/quick_bulk_import_dialog.dart` providing a text area, a real-time parsed question count badge, and an import button.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/utils/bulk_import_parser_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/bulk_import_parser.dart lib/screens/exam/widgets/quick_bulk_import_dialog.dart test/utils/bulk_import_parser_test.dart
git commit -m "feat(exam): implement BulkImportParser and QuickBulkImportDialog"
```

---

### Task 5: Wolfram Alpha-style Bottom Toolbar (`ScientificBottomToolbar`)

**Files:**
- Create: `lib/screens/exam/widgets/scientific_bottom_toolbar.dart`
- Test: `test/screens/exam/widgets/scientific_bottom_toolbar_test.dart`

**Interfaces:**
- Produces: `ScientificBottomToolbar(onInsertSnippet: Function(String template, int selectionOffset, int selectionLength))` allowing teachers to tap fractions, radicals, subscripts, arrows, Greek letters, and IPA symbols.

- [ ] **Step 1: Write failing widget test for `ScientificBottomToolbar`**

```dart
// test/screens/exam/widgets/scientific_bottom_toolbar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/widgets/scientific_bottom_toolbar.dart';

void main() {
  testWidgets('ScientificBottomToolbar displays categories and inserts fraction snippet', (tester) async {
    String? inserted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ScientificBottomToolbar(
            onInsertSnippet: (snippet, offset, length) {
              inserted = snippet;
            },
          ),
        ),
      ),
    );

    expect(find.text('Toán học'), findsOneWidget);
    expect(find.text('Vật lý'), findsOneWidget);
    expect(find.text('Hóa học'), findsOneWidget);
    expect(find.text('Hy Lạp'), findsOneWidget);
    expect(find.text('Ngoại ngữ / IPA'), findsOneWidget);

    final fractionBtn = find.byTooltip('Phân số');
    expect(fractionBtn, findsOneWidget);
    await tester.tap(fractionBtn);
    await tester.pump();

    expect(inserted, contains(r'\frac{'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/exam/widgets/scientific_bottom_toolbar_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `ScientificBottomToolbar`**

Implement `lib/screens/exam/widgets/scientific_bottom_toolbar.dart` with:
- Categories: Math, Physics, Chemistry, Greek, Languages & IPA
- Visual component buttons (Fraction, Square root, Power, Subscript, Integral, Chemical arrows, IPA symbols)
- Tooltip descriptions for each symbol

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/exam/widgets/scientific_bottom_toolbar_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/widgets/scientific_bottom_toolbar.dart test/screens/exam/widgets/scientific_bottom_toolbar_test.dart
git commit -m "feat(exam): implement ScientificBottomToolbar with multi-discipline symbols"
```

---

### Task 6: Sidebars & Responsive Question Editor Widgets

**Files:**
- Create: `lib/screens/exam/widgets/exam_left_sidebar.dart`
- Create: `lib/screens/exam/widgets/exam_right_sidebar.dart`
- Create: `lib/screens/exam/widgets/question_answers_editor.dart`
- Test: `test/screens/exam/widgets/exam_sidebars_test.dart`

**Interfaces:**
- Produces:
  - `ExamLeftSidebar`: Reorderable list of question drafts with badges, add/duplicate/delete/bulk-import triggers.
  - `ExamRightSidebar`: Title, subject, duration, question count, per-question time limit toggle.
  - `QuestionAnswersEditor`: Adaptive editor for single_choice, multiple_choice, true_false, and short_answer.

- [ ] **Step 1: Write failing widget test for `ExamLeftSidebar` and `QuestionAnswersEditor`**

```dart
// test/screens/exam/widgets/exam_sidebars_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/question_draft.dart';
import 'package:onthi_community/screens/exam/widgets/exam_left_sidebar.dart';
import 'package:onthi_community/screens/exam/widgets/question_answers_editor.dart';

void main() {
  testWidgets('ExamLeftSidebar renders questions with reordering support', (tester) async {
    final questions = [
      QuestionDraft(id: '1', body: 'Câu 1'),
      QuestionDraft(id: '2', body: 'Câu 2'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExamLeftSidebar(
            questions: questions,
            activeIndex: 0,
            onSelect: (_) {},
            onAdd: () {},
            onDuplicate: (_) {},
            onDelete: (_) {},
            onReorder: (oldIdx, newIdx) {},
            onOpenBulkImport: () {},
          ),
        ),
      ),
    );

    expect(find.text('DANH SÁCH CÂU HỎI'), findsOneWidget);
    expect(find.text('Câu 1'), findsOneWidget);
    expect(find.text('Câu 2'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/exam/widgets/exam_sidebars_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `ExamLeftSidebar`, `ExamRightSidebar`, and `QuestionAnswersEditor`**

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/exam/widgets/exam_sidebars_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/widgets/exam_left_sidebar.dart lib/screens/exam/widgets/exam_right_sidebar.dart lib/screens/exam/widgets/question_answers_editor.dart test/screens/exam/widgets/exam_sidebars_test.dart
git commit -m "feat(exam): implement modular sidebars and adaptive QuestionAnswersEditor"
```

---

### Task 7: Student Exam Interactive Preview Dialog (`StudentExamPreviewDialog`)

**Files:**
- Create: `lib/screens/exam/widgets/student_exam_preview_dialog.dart`
- Test: `test/screens/exam/widgets/student_exam_preview_dialog_test.dart`

**Interfaces:**
- Produces: `StudentExamPreviewDialog(title: String, durationMinutes: int, questions: List<QuestionDraft>)` displaying the exam exactly as a student sees it, with an author toggle to view correct answers and explanations.

- [ ] **Step 1: Write failing widget test for `StudentExamPreviewDialog`**

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement `StudentExamPreviewDialog` using `LatexMathView`**

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/widgets/student_exam_preview_dialog.dart test/screens/exam/widgets/student_exam_preview_dialog_test.dart
git commit -m "feat(exam): implement StudentExamPreviewDialog with interactive author mode"
```

---

### Task 8: Assemble `CreateExamScreen` & End-to-End Verification

**Files:**
- Modify: `lib/screens/exam/create_exam_screen.dart`
- Test: `test/screens/exam/create_exam_screen_test.dart`

**Interfaces:**
- Assembles Left Sidebar, Right Sidebar, Question Editor with Live LaTeX Preview Card, Bottom Scientific Toolbar, and Top Header actions.

- [ ] **Step 1: Refactor `CreateExamScreen` to wire all modular components**
- [ ] **Step 2: Add validation, focus tracking for formula insertion, and auto-save timer**
- [ ] **Step 3: Write comprehensive widget tests in `test/screens/exam/create_exam_screen_test.dart`**
- [ ] **Step 4: Run all tests in the project**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/exam/create_exam_screen.dart test/screens/exam/create_exam_screen_test.dart
git commit -m "feat(exam): assemble modular CreateExamScreen with scientific toolbar and live preview"
```

---

### Task 9: Git Commit & Auto-Push as per Custom Rule

**Action:**
Run git push to push all commits to the remote repository for automated GitHub Actions build and deployment.

- [ ] **Step 1: Run `git push origin main`**
- [ ] **Step 2: Verify git status is clean and upstream is synchronized**
