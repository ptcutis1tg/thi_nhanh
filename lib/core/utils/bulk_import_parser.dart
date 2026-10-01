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
        final hasDung = currentAnswers.any((a) => a.trim().toLowerCase() == 'đúng');
        final hasSai = currentAnswers.any((a) => a.trim().toLowerCase() == 'sai');

        if (currentAnswers.length == 2 && hasDung && hasSai) {
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
