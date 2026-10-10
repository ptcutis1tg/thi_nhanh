import 'package:flutter/material.dart';
import '../../../core/models/question_draft.dart';
import '../../../core/models/scientific_shortcut.dart';
import '../../../core/theme/app_theme.dart';
import 'scientific_text_field.dart';

class QuestionAnswersEditor extends StatelessWidget {
  const QuestionAnswersEditor({
    super.key,
    required this.question,
    required this.onChanged,
    this.shortcutCategory = ScientificCategory.math,
    this.shortcuts = const [],
    this.onFocusTarget,
  });

  final QuestionDraft question;
  final VoidCallback onChanged;
  final ScientificCategory shortcutCategory;
  final List<ScientificShortcut> shortcuts;
  final ValueChanged<ScientificInputTarget>? onFocusTarget;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.singleChoice:
        return _buildSingleChoice(context);
      case QuestionType.multipleChoice:
        return _buildMultipleChoice(context);
      case QuestionType.trueFalse:
        return _buildTrueFalse(context);
      case QuestionType.shortAnswer:
        return _buildShortAnswer(context);
    }
  }

  Widget _buildSingleChoice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Các đáp án (chọn 1 đáp án đúng tròn bên trái):',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...List.generate(question.answers.length, (index) {
          final isSelected = question.correctAnswers.contains(index);
          final letter = String.fromCharCode(65 + index);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Radio<int>(
                  value: index,
                  groupValue: question.correctAnswers.isNotEmpty
                      ? question.correctAnswers.first
                      : -1,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    if (val != null) {
                      question.correctAnswers = [val];
                      onChanged();
                    }
                  },
                ),
                Expanded(
                  child: ScientificTextField(
                    key: ValueKey('answer-${question.id}-$index'),
                    initialValue: question.answers[index],
                    category: shortcutCategory,
                    shortcuts: shortcuts,
                    fieldLabel: 'Đáp án $letter',
                    onFocused: onFocusTarget,
                    onChanged: (val) {
                      question.answers[index] = val;
                      onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: '$letter. Đáp án *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      suffixIcon: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppTheme.success,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Xóa lựa chọn này',
                  onPressed: question.answers.length <= 2
                      ? null
                      : () {
                          question.answers.removeAt(index);
                          question.correctAnswers.remove(index);
                          for (
                            int i = 0;
                            i < question.correctAnswers.length;
                            i++
                          ) {
                            if (question.correctAnswers[i] > index) {
                              question.correctAnswers[i]--;
                            }
                          }
                          if (question.correctAnswers.isEmpty &&
                              question.answers.isNotEmpty) {
                            question.correctAnswers = [0];
                          }
                          onChanged();
                        },
                  icon: Icon(
                    Icons.close,
                    color: question.answers.length <= 2
                        ? Colors.grey.shade300
                        : AppTheme.error,
                  ),
                ),
              ],
            ),
          );
        }),
        if (question.answers.length < 8)
          TextButton.icon(
            onPressed: () {
              question.answers.add('');
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Thêm phương án lựa chọn'),
          ),
      ],
    );
  }

  Widget _buildMultipleChoice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Các đáp án (tích chọn 1 hoặc NHIỀU đáp án đúng):',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...List.generate(question.answers.length, (index) {
          final isChecked = question.correctAnswers.contains(index);
          final letter = String.fromCharCode(65 + index);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Checkbox(
                  value: isChecked,
                  activeColor: AppTheme.primary,
                  onChanged: (checked) {
                    if (checked == true) {
                      if (!question.correctAnswers.contains(index)) {
                        question.correctAnswers.add(index);
                        question.correctAnswers.sort();
                      }
                    } else {
                      question.correctAnswers.remove(index);
                    }
                    onChanged();
                  },
                ),
                Expanded(
                  child: ScientificTextField(
                    key: ValueKey('answer-multi-${question.id}-$index'),
                    initialValue: question.answers[index],
                    category: shortcutCategory,
                    shortcuts: shortcuts,
                    fieldLabel: 'Đáp án $letter',
                    onFocused: onFocusTarget,
                    onChanged: (val) {
                      question.answers[index] = val;
                      onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: '$letter. Đáp án *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      suffixIcon: isChecked
                          ? const Icon(
                              Icons.check_circle,
                              color: AppTheme.success,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Xóa lựa chọn này',
                  onPressed: question.answers.length <= 2
                      ? null
                      : () {
                          question.answers.removeAt(index);
                          question.correctAnswers.remove(index);
                          for (
                            int i = 0;
                            i < question.correctAnswers.length;
                            i++
                          ) {
                            if (question.correctAnswers[i] > index) {
                              question.correctAnswers[i]--;
                            }
                          }
                          onChanged();
                        },
                  icon: Icon(
                    Icons.close,
                    color: question.answers.length <= 2
                        ? Colors.grey.shade300
                        : AppTheme.error,
                  ),
                ),
              ],
            ),
          );
        }),
        if (question.answers.length < 8)
          TextButton.icon(
            onPressed: () {
              question.answers.add('');
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Thêm phương án lựa chọn'),
          ),
      ],
    );
  }

  Widget _buildTrueFalse(BuildContext context) {
    if (question.answers.length < 2) {
      question.answers = ['Đúng', 'Sai'];
    }
    final isTrueCorrect = question.correctAnswers.contains(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn khẳng định đúng cho câu hỏi này:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTrueCorrect
                      ? AppTheme.success
                      : AppTheme.background,
                  foregroundColor: isTrueCorrect
                      ? Colors.white
                      : AppTheme.textMain,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: isTrueCorrect ? AppTheme.success : AppTheme.border,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  question.correctAnswers = [0];
                  onChanged();
                },
                icon: Icon(
                  isTrueCorrect ? Icons.check_circle : Icons.circle_outlined,
                ),
                label: const Text(
                  'ĐÚNG',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isTrueCorrect
                      ? AppTheme.error
                      : AppTheme.background,
                  foregroundColor: !isTrueCorrect
                      ? Colors.white
                      : AppTheme.textMain,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: !isTrueCorrect ? AppTheme.error : AppTheme.border,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  question.correctAnswers = [1];
                  onChanged();
                },
                icon: Icon(
                  !isTrueCorrect ? Icons.cancel : Icons.circle_outlined,
                ),
                label: const Text(
                  'SAI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortAnswer(BuildContext context) {
    if (question.answers.isEmpty) {
      question.answers = [''];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đáp án chuẩn xác (Học sinh phải nhập đúng từ/số này):',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...List.generate(question.answers.length, (idx) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: ScientificTextField(
                    key: ValueKey('short-ans-${question.id}-$idx'),
                    initialValue: question.answers[idx],
                    category: shortcutCategory,
                    shortcuts: shortcuts,
                    fieldLabel: idx == 0
                        ? 'Đáp án chính'
                        : 'Đáp án tương đương ${idx + 1}',
                    onFocused: onFocusTarget,
                    onChanged: (val) {
                      question.answers[idx] = val;
                      onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: idx == 0
                          ? 'Đáp án chính *'
                          : 'Đáp án tương đương chấp nhận',
                      hintText: 'Ví dụ: 42 hoặc H2O',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (idx > 0) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      question.answers.removeAt(idx);
                      onChanged();
                    },
                    icon: const Icon(Icons.close, color: AppTheme.error),
                  ),
                ],
              ],
            ),
          );
        }),
        if (question.answers.length < 5)
          TextButton.icon(
            onPressed: () {
              question.answers.add('');
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Thêm phương án chấp nhận tương đương'),
          ),
      ],
    );
  }
}
