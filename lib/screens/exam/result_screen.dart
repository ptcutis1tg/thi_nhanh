import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/assessment.dart';
import '../../core/repositories/assessment_repository.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/report_question_dialog.dart';
import '../../shared/widgets/top_nav_bar.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    this.score,
    this.total,
    this.correct,
    this.wrong,
    this.skipped,
    this.title,
    this.attemptId,
    this.roomId,
  });

  final double? score;
  final int? total;
  final int? correct;
  final int? wrong;
  final int? skipped;
  final String? title;
  final String? attemptId;
  final String? roomId;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = false;
  String? _error;
  AttemptReviewPayload? _review;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.attemptId != null && widget.attemptId!.isNotEmpty) {
      _loadReview();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReview({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final review = await context.read<AssessmentRepository>().loadReview(
        widget.attemptId!,
      );
      if (!mounted) return;
      setState(() {
        _review = review;
        _error = null;
        _isLoading = false;
      });
      if (!review.resultReleased && review.roomId != null) {
        _refreshTimer ??= Timer.periodic(
          const Duration(seconds: 5),
          (_) => _loadReview(silent: true),
        );
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  bool get _usesLegacyData =>
      widget.attemptId == null || widget.attemptId!.isEmpty;
  double get _score => _review?.score ?? widget.score ?? 0;
  int get _total => _review?.totalQuestions ?? widget.total ?? 0;
  int get _correct => _review?.correctCount ?? widget.correct ?? 0;
  int get _wrong => _review?.wrongCount ?? widget.wrong ?? 0;
  int get _skipped => _review?.skippedCount ?? widget.skipped ?? 0;
  String get _title =>
      _review?.title ?? widget.title ?? 'Bài thi vừa hoàn thành';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: TopNavBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _review == null) {
      return Scaffold(
        appBar: const TopNavBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 12),
              const Text('Không tải được kết quả bài thi.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadReview,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_usesLegacyData && _review != null && !_review!.resultReleased) {
      return _buildWaitingResult();
    }

    return Scaffold(
      appBar: const TopNavBar(),
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: widget.attemptId == null ? () async {} : _loadReview,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  children: [
                    _buildScoreCard(),
                    const SizedBox(height: 24),
                    _buildStats(),
                    if (_review != null) ...[
                      const SizedBox(height: 24),
                      _buildAttemptDetails(),
                      if (_review!.questions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildQuestionReview(),
                      ],
                    ],
                    const SizedBox(height: 28),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingResult() {
    final review = _review!;
    return Scaffold(
      appBar: const TopNavBar(),
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppTheme.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Đã nộp bài thành công',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    review.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Giáo viên chưa công bố kết quả. Điểm và lời giải sẽ tự động xuất hiện khi phòng thi kết thúc.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đã trả lời ${review.answeredCount}/${review.totalQuestions} câu • ${review.durationFormatted}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _loadReview(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Kiểm tra kết quả'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home),
                        label: const Text('Về trang chủ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium,
            color: AppTheme.success,
            size: 56,
          ),
          const SizedBox(height: 12),
          const Text(
            'Chúc mừng bạn đã hoàn thành bài thi!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 22),
          Semantics(
            label: 'Điểm số ${_score.toStringAsFixed(2)} trên 10',
            child: CircleAvatar(
              radius: 72,
              backgroundColor: AppTheme.primary,
              child: CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Điểm số',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      Text(
                        _score.toStringAsFixed(2),
                        style: AppTheme.firaCodeStyle.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Text(
                        '/10',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_review != null) ...[
            const SizedBox(height: 12),
            Text(
              '${_review!.earnedPoints.toStringAsFixed(2)}/${_review!.totalPoints.toStringAsFixed(2)} điểm trọng số',
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildStats() => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      _stat(Icons.check_circle, AppTheme.success, 'Câu đúng', '$_correct'),
      _stat(Icons.cancel, AppTheme.warning, 'Câu sai', '$_wrong'),
      _stat(Icons.help, AppTheme.textSecondary, 'Bỏ qua', '$_skipped'),
      if (_review?.rank != null)
        _stat(
          Icons.leaderboard,
          AppTheme.primary,
          'Xếp hạng',
          '#${_review!.rank}/${_review!.participantCount ?? '-'}',
        ),
    ],
  );

  Widget _stat(
    IconData icon,
    Color color,
    String label,
    String value,
  ) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildAttemptDetails() => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 32,
        runSpacing: 16,
        alignment: WrapAlignment.spaceAround,
        children: [
          _detail(
            Icons.quiz_outlined,
            'Đã trả lời',
            '${_review!.answeredCount}/$_total câu',
          ),
          _detail(
            Icons.timer_outlined,
            'Thời gian làm bài',
            _review!.durationFormatted,
          ),
          _detail(
            Icons.check_circle_outline,
            'Trạng thái',
            _review!.status == 'expired' ? 'Hết giờ tự nộp' : 'Đã nộp',
          ),
        ],
      ),
    ),
  );

  Widget _detail(IconData icon, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppTheme.primary),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ],
  );

  Widget _buildQuestionReview() => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xem lại bài làm',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mở từng câu để xem đáp án và lời giải.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ..._review!.questions.map(_questionTile),
        ],
      ),
    ),
  );

  Widget _questionTile(ReviewQuestion question) {
    final color = question.isCorrect
        ? AppTheme.success
        : (question.isSkipped ? AppTheme.textSecondary : AppTheme.warning);
    final status = question.isCorrect
        ? 'Đúng'
        : (question.isSkipped ? 'Bỏ qua' : 'Sai');
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Text('${question.position}', style: TextStyle(color: color)),
      ),
      title: Text('Câu ${question.position} • $status'),
      subtitle: Text('+${question.earnedPoints}/${question.points} điểm'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            question.body,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        ...question.options.map((option) {
          final selected = option.id == question.selectedOptionId;
          final optionColor = option.isCorrect
              ? AppTheme.success
              : (selected ? AppTheme.warning : AppTheme.textSecondary);
          return ListTile(
            dense: true,
            leading: Icon(
              option.isCorrect
                  ? Icons.check_circle
                  : (selected ? Icons.cancel : Icons.radio_button_unchecked),
              color: optionColor,
            ),
            title: Text(option.body),
            trailing: selected ? const Text('Bạn chọn') : null,
          );
        }),
        if (question.explanation.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppTheme.primary.withValues(alpha: .06),
            child: Text('Giải thích: ${question.explanation}'),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: Key('report-question-${question.id}'),
            onPressed: () => _reportQuestion(question),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Báo câu này có lỗi'),
          ),
        ),
      ],
    );
  }

  Future<void> _reportQuestion(ReviewQuestion question) async {
    final review = _review;
    if (review == null) return;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ReportQuestionDialog(
        attemptId: review.attemptId,
        examId: review.examId,
        examTitle: review.title,
        questionId: question.id,
        questionPosition: question.position,
        questionBody: question.body,
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi báo cáo cho giáo viên.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Widget _buildActions() => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      OutlinedButton.icon(
        onPressed: () => context.go('/student/history'),
        icon: const Icon(Icons.history),
        label: const Text('Xem lịch sử thi'),
      ),
      if (widget.roomId != null)
        OutlinedButton.icon(
          onPressed: () => context.go('/student/leaderboard'),
          icon: const Icon(Icons.leaderboard),
          label: const Text('Bảng xếp hạng'),
        ),
      ElevatedButton.icon(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.home),
        label: const Text('Về trang chủ'),
      ),
    ],
  );
}
