import 'package:flutter/material.dart';
import '../../../core/models/question_draft.dart';
import '../../../core/theme/app_theme.dart';
import 'latex_math_view.dart';

class StudentExamPreviewDialog extends StatefulWidget {
  const StudentExamPreviewDialog({
    super.key,
    required this.examTitle,
    required this.subject,
    required this.durationMinutes,
    required this.questions,
  });

  final String examTitle;
  final String subject;
  final int durationMinutes;
  final List<QuestionDraft> questions;

  @override
  State<StudentExamPreviewDialog> createState() => _StudentExamPreviewDialogState();
}

class _StudentExamPreviewDialogState extends State<StudentExamPreviewDialog> {
  int _currentIndex = 0;
  bool _showSolutions = false;
  final Map<int, Set<int>> _selectedOptions = {}; // questionIndex -> set of option indexes
  final Map<int, String> _shortAnswers = {};

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Đề thi chưa có câu hỏi nào để xem trước.'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ],
          ),
        ),
      );
    }

    final q = widget.questions[_currentIndex];
    final isLast = _currentIndex >= widget.questions.length - 1;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textMain),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Xem trước góc nhìn học sinh',
                      style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.examTitle.isEmpty ? 'Bài thi' : widget.examTitle,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                '${widget.subject} • ${widget.durationMinutes} phút • ${widget.questions.length} câu',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilterChip(
                label: const Text('Hiện đáp án & Lời giải'),
                selected: _showSolutions,
                selectedColor: AppTheme.success.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.success,
                labelStyle: TextStyle(
                  color: _showSolutions ? AppTheme.success : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (val) => setState(() => _showSolutions = val),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            // Question Navigation Sidebar
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'BẢNG CÂU HỎI',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: widget.questions.length,
                      itemBuilder: (ctx, idx) {
                        final isCur = idx == _currentIndex;
                        final hasAnswer = _selectedOptions[idx]?.isNotEmpty == true ||
                            (_shortAnswers[idx]?.isNotEmpty == true);

                        return InkWell(
                          onTap: () => setState(() => _currentIndex = idx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCur
                                  ? AppTheme.primary
                                  : (hasAnswer ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.background),
                              border: Border.all(
                                color: isCur ? AppTheme.primary : AppTheme.border,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCur ? Colors.white : (hasAnswer ? AppTheme.primary : AppTheme.textMain),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Question Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question header chip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    'Câu ${_currentIndex + 1}/${widget.questions.length}',
                                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.border,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${q.points} điểm',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Question body
                            LatexMathView(
                              text: q.body.isEmpty ? 'Chưa có nội dung đề bài.' : q.body,
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
                            ),
                            const SizedBox(height: 28),
                            // Options
                            _buildPreviewOptions(q),
                            // Explanation
                            if (_showSolutions && q.explanation.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline, color: AppTheme.success, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Lời giải thích chi tiết:',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LatexMathView(
                                      text: q.explanation,
                                      textStyle: const TextStyle(fontSize: 14, color: AppTheme.textMain),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            const Divider(color: AppTheme.border),
                            const SizedBox(height: 16),
                            // Bottom Nav Buttons
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                                  icon: const Icon(Icons.chevron_left),
                                  label: const Text('Câu trước'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: !isLast
                                      ? () => setState(() => _currentIndex++)
                                      : () => Navigator.pop(context),
                                  icon: Icon(!isLast ? Icons.chevron_right : Icons.check),
                                  label: Text(!isLast ? 'Câu sau' : 'Hoàn tất xem thử'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewOptions(QuestionDraft q) {
    final curSelected = _selectedOptions[_currentIndex] ?? <int>{};

    if (q.type == QuestionType.shortAnswer) {
      final isCorrect = _showSolutions &&
          q.answers.any((ans) =>
              ans.trim().toLowerCase() == (_shortAnswers[_currentIndex] ?? '').trim().toLowerCase());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (val) => setState(() => _shortAnswers[_currentIndex] = val),
            decoration: InputDecoration(
              hintText: 'Nhập câu trả lời của bạn...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_showSolutions) ...[
            const SizedBox(height: 10),
            Text(
              'Đáp án chấp nhận: ${q.answers.join(' hoặc ')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCorrect ? AppTheme.success : AppTheme.error,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      children: List.generate(q.answers.length, (optIdx) {
        final optLetter = String.fromCharCode(65 + optIdx);
        final optBody = q.answers[optIdx];
        final isChosen = curSelected.contains(optIdx);
        final isCorrectAnswer = q.correctAnswers.contains(optIdx);

        Color borderColor = AppTheme.border;
        Color bgColor = Colors.white;

        if (_showSolutions) {
          if (isCorrectAnswer) {
            borderColor = AppTheme.success;
            bgColor = AppTheme.success.withValues(alpha: 0.08);
          } else if (isChosen && !isCorrectAnswer) {
            borderColor = AppTheme.error;
            bgColor = AppTheme.error.withValues(alpha: 0.08);
          }
        } else if (isChosen) {
          borderColor = AppTheme.primary;
          bgColor = AppTheme.primary.withValues(alpha: 0.06);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isChosen || (_showSolutions && isCorrectAnswer) ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                if (q.type == QuestionType.multipleChoice) {
                  if (curSelected.contains(optIdx)) {
                    curSelected.remove(optIdx);
                  } else {
                    curSelected.add(optIdx);
                  }
                } else {
                  curSelected.clear();
                  curSelected.add(optIdx);
                }
                _selectedOptions[_currentIndex] = curSelected;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isChosen ? AppTheme.primary : AppTheme.background,
                    child: Text(
                      optLetter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isChosen ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: LatexMathView(
                      text: optBody,
                      textStyle: const TextStyle(fontSize: 15),
                    ),
                  ),
                  if (_showSolutions && isCorrectAnswer)
                    const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
