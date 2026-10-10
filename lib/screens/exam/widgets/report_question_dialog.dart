import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/repositories/question_report_repository.dart';
import '../../../core/theme/app_theme.dart';

class ReportQuestionDialog extends StatefulWidget {
  const ReportQuestionDialog({
    super.key,
    required this.attemptId,
    required this.examId,
    required this.examTitle,
    required this.questionId,
    required this.questionPosition,
    required this.questionBody,
  });

  final String attemptId;
  final String examId;
  final String examTitle;
  final String questionId;
  final int questionPosition;
  final String questionBody;

  @override
  State<ReportQuestionDialog> createState() => _ReportQuestionDialogState();
}

class _ReportQuestionDialogState extends State<ReportQuestionDialog> {
  final _detailController = TextEditingController();
  QuestionReportCategory _category = QuestionReportCategory.wrongAnswer;
  bool _submitting = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final detail = _detailController.text.trim();
    if ((_category == QuestionReportCategory.other || detail.isNotEmpty) &&
        detail.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy mô tả vấn đề ít nhất 3 ký tự.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<QuestionReportRepository>().submit(
        attemptId: widget.attemptId,
        examId: widget.examId,
        examTitle: widget.examTitle,
        questionId: widget.questionId,
        questionPosition: widget.questionPosition,
        questionBody: widget.questionBody,
        category: _category,
        detail: _detailController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi báo cáo: $error'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Báo lỗi câu ${widget.questionPosition}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.questionBody,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<QuestionReportCategory>(
                key: const Key('report-category'),
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Vấn đề'),
                items: QuestionReportCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('report-detail'),
                controller: _detailController,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Mô tả thêm (không bắt buộc)',
                  hintText: 'Ví dụ: đáp án B và C đều có thể đúng...',
                  alignLabelWithHint: true,
                ),
              ),
              const Text(
                'Giáo viên sở hữu đề sẽ nhận được báo cáo này.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          key: const Key('submit-question-report'),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.flag_outlined),
          label: const Text('Gửi báo cáo'),
        ),
      ],
    );
  }
}
