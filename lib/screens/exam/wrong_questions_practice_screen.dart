import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/assessment.dart';
import '../../core/repositories/assessment_repository.dart';
import '../../core/theme/app_theme.dart';

class WrongQuestionsPracticeScreen extends StatefulWidget {
  final String? attemptId;
  final AttemptReviewPayload? testReviewPayload;

  const WrongQuestionsPracticeScreen({
    super.key,
    this.attemptId,
    this.testReviewPayload,
  });

  @override
  State<WrongQuestionsPracticeScreen> createState() => _WrongQuestionsPracticeScreenState();
}

class _WrongQuestionsPracticeScreenState extends State<WrongQuestionsPracticeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  AttemptReviewPayload? _reviewPayload;
  List<ReviewQuestion> _wrongQuestions = [];

  // User state in this practice session: questionId -> selectedOptionId
  final Map<String, String> _userAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.testReviewPayload != null) {
      _processPayload(widget.testReviewPayload!);
      return;
    }

    if (widget.attemptId == null || widget.attemptId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Mã bài làm không hợp lệ.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = context.read<AssessmentRepository>();
      final payload = await repo.loadReview(widget.attemptId!);
      if (mounted) {
        _processPayload(payload);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải chi tiết bài làm: $e';
        });
      }
    }
  }

  void _processPayload(AttemptReviewPayload payload) {
    final list = payload.questions.where((q) => !q.isCorrect).toList();
    setState(() {
      _reviewPayload = payload;
      _wrongQuestions = list;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  int get _solvedCorrectCount {
    int count = 0;
    for (final q in _wrongQuestions) {
      final selected = _userAnswers[q.id];
      if (selected != null && selected == q.correctOptionId) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: AppTheme.textMain),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 32, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(compact),
                  const SizedBox(height: 20),

                  // Progress & Overview Card
                  _buildProgressCard(),
                  const SizedBox(height: 24),

                  // Questions List or Empty State
                  if (_wrongQuestions.isEmpty)
                    _buildAllCorrectState()
                  else
                    ..._wrongQuestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildPracticeQuestionCard(index + 1, question),
                      );
                    }),

                  const SizedBox(height: 24),
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool compact) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/history');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
          tooltip: 'Quay lại',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Luyện Lại Câu Sai',
                style: TextStyle(
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (_reviewPayload != null)
                Text(
                  _reviewPayload!.title,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final total = _wrongQuestions.length;
    final solved = _solvedCorrectCount;
    final progress = total > 0 ? (solved / total) : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$total câu cần khắc phục',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              Text(
                'Đã làm đúng: $solved / $total câu',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F0FC),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCorrectState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 60, color: Color(0xFFD97706)),
          const SizedBox(height: 16),
          const Text(
            'Tuyệt vời! Không có câu sai nào!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn đã hoàn thành xuất sắc tất cả câu hỏi trong bài thi này.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/student/history'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xem các bài thi khác'),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeQuestionCard(int practiceIndex, ReviewQuestion question) {
    final selectedOptionId = _userAnswers[question.id];
    final isAnswered = selectedOptionId != null;
    final isNowCorrect = isAnswered && selectedOptionId == question.correctOptionId;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswered
              ? (isNowCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA))
              : const Color(0xFFEBE6FC),
          width: isAnswered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$practiceIndex',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Câu gốc: ${question.position}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (isAnswered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNowCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNowCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 14,
                        color: isNowCorrect ? const Color(0xFF166534) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isNowCorrect ? 'Đã sửa đúng! 🎉' : 'Chưa đúng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isNowCorrect ? const Color(0xFF166534) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Question Body
          Text(
            question.body,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Options
          ...question.options.map((option) {
            final isSelected = selectedOptionId == option.id;
            final isCorrectOption = option.id == question.correctOptionId;

            Color optionBg = const Color(0xFFFAFAFE);
            Color optionBorder = const Color(0xFFEBE6FC);
            Color textColor = AppTheme.textMain;
            IconData icon = Icons.radio_button_unchecked_rounded;
            Color iconColor = AppTheme.textSecondary;

            if (isAnswered) {
              if (isSelected && isNowCorrect) {
                optionBg = const Color(0xFFDCFCE7);
                optionBorder = const Color(0xFF86EFAC);
                textColor = const Color(0xFF166534);
                icon = Icons.check_circle_rounded;
                iconColor = const Color(0xFF166534);
              } else if (isSelected && !isNowCorrect) {
                optionBg = const Color(0xFFFEE2E2);
                optionBorder = const Color(0xFFFCA5A5);
                textColor = const Color(0xFFDC2626);
                icon = Icons.cancel_rounded;
                iconColor = const Color(0xFFDC2626);
              } else if (isCorrectOption) {
                // Show correct option to help student learn
                optionBg = const Color(0xFFF0FDF4);
                optionBorder = const Color(0xFFBBF7D0);
                textColor = const Color(0xFF166534);
                icon = Icons.check_circle_outline_rounded;
                iconColor = const Color(0xFF166534);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _userAnswers[question.id] = option.id;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: optionBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: optionBorder, width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.body,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Text(
                          'Bạn chọn',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explanation Banner (Always revealed once student attempts the question)
          if (isAnswered && question.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb_rounded, size: 16, color: AppTheme.primary),
                      SizedBox(width: 6),
                      Text(
                        'Lời giải chi tiết',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.explanation,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4C1D95), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/history');
            }
          },
          icon: const Icon(Icons.history_rounded, size: 18),
          label: const Text('Quay lại Lịch sử làm bài'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
