import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/assessment.dart';
import '../../core/repositories/assessment_repository.dart';
import '../../core/theme/app_theme.dart';

class TakingExamScreen extends StatefulWidget {
  const TakingExamScreen({super.key, this.attemptId, this.roomId});

  final String? attemptId;
  final String? roomId;

  @override
  State<TakingExamScreen> createState() => _TakingExamScreenState();
}

class _TakingExamScreenState extends State<TakingExamScreen> {
  late final Future<AttemptPayload> _attemptFuture;
  Timer? _clock;
  AttemptPayload? _attempt;
  int _questionIndex = 0;
  bool _isSubmitting = false;
  final Map<String, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _attemptFuture = _load();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<AttemptPayload> _load() async {
    final attemptId = widget.attemptId;
    if (attemptId == null || attemptId.isEmpty) {
      throw const FormatException('Thiếu mã lượt làm bài.');
    }
    final payload = await context.read<AssessmentRepository>().loadAttempt(attemptId);
    _attempt = payload;
    _answers.addAll(payload.answers);
    return payload;
  }

  Duration get _remaining {
    final expiry = _attempt?.expiresAt;
    if (expiry == null) return Duration.zero;
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get _timeLabel {
    final value = _remaining;
    String pad(int number) => number.toString().padLeft(2, '0');
    return '${pad(value.inHours)}:${pad(value.inMinutes.remainder(60))}:${pad(value.inSeconds.remainder(60))}';
  }

  Future<void> _select(ExamQuestion question, ExamOption option) async {
    final attempt = _attempt;
    if (attempt == null || !attempt.isOpen || _remaining == Duration.zero) return;
    setState(() => _answers[question.id] = option.id);
    try {
      await context.read<AssessmentRepository>().saveAnswer(
        attemptId: attempt.attemptId,
        questionId: question.id,
        optionId: option.id,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa lưu được đáp án. Hệ thống sẽ thử lại khi bạn chọn lại.')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final attempt = _attempt;
    if (attempt == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await context.read<AssessmentRepository>().submit(attempt.attemptId);
      if (mounted) {
        context.go(
          '/result?attemptId=${attempt.attemptId}${widget.roomId != null ? '&roomId=${widget.roomId}' : ''}',
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể nộp bài. Vui lòng thử lại.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Thi Nhanh'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              child: Chip(
                avatar: const Icon(Icons.timer_outlined, color: AppTheme.primary),
                label: Text(_timeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: FutureBuilder<AttemptPayload>(
          future: _attemptFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _Failure(message: '${snapshot.error}');
            final attempt = snapshot.requireData;
            if (attempt.questions.isEmpty) return const _Failure(message: 'Đề này chưa có câu hỏi.');
            final question = attempt.questions[_questionIndex];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(attempt.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: (_questionIndex + 1) / attempt.questions.length),
                    const SizedBox(height: 20),
                    Expanded(child: _QuestionCard(question: question, index: _questionIndex, total: attempt.questions.length, selectedOptionId: _answers[question.id], onSelected: (option) => _select(question, option))),
                    const SizedBox(height: 18),
                    Row(children: [
                      OutlinedButton.icon(onPressed: _questionIndex == 0 ? null : () => setState(() => _questionIndex--), icon: const Icon(Icons.chevron_left), label: const Text('Câu trước')),
                      const Spacer(),
                      Text('${_answers.length}/${attempt.questions.length} đã lưu', style: const TextStyle(color: AppTheme.textSecondary)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : (_questionIndex == attempt.questions.length - 1 ? _submit : () => setState(() => _questionIndex++)),
                        icon: Icon(_questionIndex == attempt.questions.length - 1 ? Icons.send : Icons.chevron_right),
                        label: Text(_isSubmitting ? 'Đang nộp...' : _questionIndex == attempt.questions.length - 1 ? 'Nộp bài' : 'Câu sau'),
                      ),
                    ]),
                  ]),
                ),
              ),
            );
          },
        ),
      );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.index, required this.total, required this.selectedOptionId, required this.onSelected});
  final ExamQuestion question;
  final int index;
  final int total;
  final String? selectedOptionId;
  final ValueChanged<ExamOption> onSelected;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Câu ${index + 1}/$total', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(question.body, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 22),
            ...question.options.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RadioListTile<String>(
                value: option.id,
                groupValue: selectedOptionId,
                title: Text(option.body),
                onChanged: (_) => onSelected(option),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.border)),
              ),
            )),
          ]),
        ),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48, color: AppTheme.error), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: () => context.go('/search'), child: const Text('Quay lại tìm đề'))])));
}
