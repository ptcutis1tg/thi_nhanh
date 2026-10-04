import 'dart:math';

class ExamShuffleHelper {
  /// Deterministically shuffles questions and their options based on a seed.
  /// Does not mutate the original questions list.
  static List<Map<String, dynamic>> shuffleQuestionsAndOptions(
    List<Map<String, dynamic>> questions, {
    required int seed,
    bool shuffleQuestions = true,
    bool shuffleOptions = true,
  }) {
    if (questions.isEmpty) return [];

    final random = Random(seed);

    // Deep copy questions and options
    final List<Map<String, dynamic>> copiedQuestions = questions.map((q) {
      final qMap = Map<String, dynamic>.from(q);

      // Handle 'question_options' or 'options'
      if (qMap.containsKey('question_options') && qMap['question_options'] is List) {
        final optionsList = (qMap['question_options'] as List)
            .map((opt) => Map<String, dynamic>.from(opt as Map))
            .toList();
        qMap['question_options'] = optionsList;
      }
      if (qMap.containsKey('options') && qMap['options'] is List) {
        final optionsList = (qMap['options'] as List)
            .map((opt) => Map<String, dynamic>.from(opt as Map))
            .toList();
        qMap['options'] = optionsList;
      }
      return qMap;
    }).toList();

    // 1. Shuffle questions order
    if (shuffleQuestions) {
      copiedQuestions.shuffle(random);
    }

    // 2. Shuffle options inside each question with deterministic sub-seed
    if (shuffleOptions) {
      for (final q in copiedQuestions) {
        final qId = q['id']?.toString() ?? 'q_${copiedQuestions.indexOf(q)}';
        final optRandom = Random((qId.hashCode ^ seed).toSigned(32));

        if (q.containsKey('question_options') && q['question_options'] is List) {
          (q['question_options'] as List<Map<String, dynamic>>).shuffle(optRandom);
        }
        if (q.containsKey('options') && q['options'] is List) {
          (q['options'] as List<Map<String, dynamic>>).shuffle(optRandom);
        }
      }
    }

    return copiedQuestions;
  }
}
