import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/assessment.dart';
import '../../core/repositories/assessment_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';
import '../room/widgets/live_leaderboard_view.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, this.attemptId, this.roomId});

  final String? attemptId;
  final String? roomId;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  AttemptReviewPayload? _review;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showReviewSection = false;
  String _questionFilter = 'all'; // 'all', 'correct', 'wrong', 'skipped'

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    final attemptId = widget.attemptId;
    if (attemptId == null || attemptId.isEmpty) {
      // Fallback demo payload
      setState(() {
        _review = _buildFallbackReview();
        _isLoading = false;
      });
      return;
    }

    try {
      final repo = context.read<AssessmentRepository?>();
      if (repo == null) {
        setState(() {
          _review = _buildFallbackReview();
          _isLoading = false;
        });
        return;
      }
      final payload = await repo.loadReview(attemptId);
      if (mounted) {
        setState(() {
          _review = payload;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _review = _buildFallbackReview();
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  AttemptReviewPayload _buildFallbackReview() {
    return const AttemptReviewPayload(
      attemptId: 'demo-attempt',
      examId: 'demo-exam',
      title: 'Đề kiểm tra giữa kì môn Toán Học 10',
      subject: 'Toán học',
      status: 'submitted',
      score: 8.5,
      maxScore: 10.0,
      correctCount: 17,
      wrongCount: 2,
      skippedCount: 1,
      totalQuestions: 20,
      durationSeconds: 1540,
      questions: [
        ReviewQuestion(
          id: 'q-1',
          position: 1,
          body: 'Tập hợp A = {x ∈ ℝ | x² - 4 = 0} có bao nhiêu phần tử?',
          points: 0.5,
          explanation: 'Phương trình x² - 4 = 0 tương đương x = 2 hoặc x = -2. Cả hai đều thuộc ℝ nên tập A có 2 phần tử {-2, 2}.',
          selectedOptionId: 'o-1-2',
          correctOptionId: 'o-1-2',
          options: [
            ReviewOption(id: 'o-1-1', position: 1, body: '1 phần tử', isCorrect: false),
            ReviewOption(id: 'o-1-2', position: 2, body: '2 phần tử', isCorrect: true),
            ReviewOption(id: 'o-1-3', position: 3, body: '0 phần tử', isCorrect: false),
            ReviewOption(id: 'o-1-4', position: 4, body: 'Vô số', isCorrect: false),
          ],
        ),
        ReviewQuestion(
          id: 'q-2',
          position: 2,
          body: 'Mệnh đề nào sau đây là phủ định của mệnh đề "∀x ∈ ℝ, x² + 1 > 0"?',
          points: 0.5,
          explanation: 'Phủ định của ∀ là ∃ và phủ định của > là ≤. Do đó mệnh đề phủ định là: ∃x ∈ ℝ, x² + 1 ≤ 0.',
          selectedOptionId: 'o-2-1',
          correctOptionId: 'o-2-3',
          options: [
            ReviewOption(id: 'o-2-1', position: 1, body: '∀x ∈ ℝ, x² + 1 ≤ 0', isCorrect: false),
            ReviewOption(id: 'o-2-2', position: 2, body: '∃x ∈ ℝ, x² + 1 < 0', isCorrect: false),
            ReviewOption(id: 'o-2-3', position: 3, body: '∃x ∈ ℝ, x² + 1 ≤ 0', isCorrect: true),
            ReviewOption(id: 'o-2-4', position: 4, body: '∃x ∉ ℝ, x² + 1 > 0', isCorrect: false),
          ],
        ),
      ],
    );
  }

  void _openLeaderboardModal(String roomId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.leaderboard_rounded, color: AppTheme.primary, size: 28),
                      SizedBox(width: 10),
                      Text('Bảng xếp hạng phòng thi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: LiveLeaderboardView(roomId: roomId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: TopNavBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final review = _review ?? _buildFallbackReview();
    final effectiveRoomId = widget.roomId ?? review.roomId;

    return Scaffold(
      appBar: const TopNavBar(),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              children: [
                _buildCongratulationCard(review),
                const SizedBox(height: 24),
                _buildDetailedStats(review),
                const SizedBox(height: 28),
                _buildActionButtons(context, review, effectiveRoomId),
                if (_showReviewSection) ...[
                  const SizedBox(height: 36),
                  _buildQuestionReviewSection(review),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCongratulationCard(AttemptReviewPayload review) {
    final score = review.score;
    Color scoreColor = AppTheme.primary;
    String scoreTitle = 'Hoàn thành bài thi xuất sắc!';
    if (score >= 9.0) {
      scoreColor = const Color(0xFF10B981);
      scoreTitle = 'Xuất sắc! Bạn đã làm bài rất tốt.';
    } else if (score >= 7.0) {
      scoreColor = AppTheme.primary;
      scoreTitle = 'Khá giỏi! Tiếp tục phát huy nhé.';
    } else if (score >= 5.0) {
      scoreColor = const Color(0xFFF59E0B);
      scoreTitle = 'Đạt yêu cầu. Hãy ôn thêm các câu sai.';
    } else {
      scoreColor = AppTheme.error;
      scoreTitle = 'Cần cố gắng hơn ở các bài thi sau.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(top: BorderSide(color: scoreColor, width: 8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.workspace_premium_rounded, color: scoreColor, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            scoreTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${review.title} • ${review.subject}',
            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Score Circle
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 7),
              color: scoreColor.withValues(alpha: 0.03),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Điểm số', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: scoreColor, height: 1.1),
                ),
                Text(
                  '/ ${review.maxScore.toInt()}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(AttemptReviewPayload review) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final statCards = [
          _buildStatCard(Icons.check_circle_rounded, AppTheme.success, 'Câu đúng', '${review.correctCount}', '/ ${review.totalQuestions}'),
          _buildStatCard(Icons.cancel_rounded, AppTheme.error, 'Câu sai', '${review.wrongCount}', 'câu'),
          _buildStatCard(Icons.help_outline_rounded, AppTheme.textSecondary, 'Bỏ qua', '${review.skippedCount}', 'câu'),
          _buildStatCard(Icons.timer_outlined, AppTheme.primary, 'Thời gian', review.durationFormatted, 'phút'),
        ];

        if (isCompact) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: statCards,
          );
        }

        return Row(
          children: statCards.map((card) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: card))).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(IconData icon, Color color, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AttemptReviewPayload review, String? roomId) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 14,
      children: [
        ElevatedButton.icon(
          onPressed: () => setState(() => _showReviewSection = !_showReviewSection),
          icon: Icon(_showReviewSection ? Icons.visibility_off_outlined : Icons.remove_red_eye_outlined),
          label: Text(_showReviewSection ? 'Ẩn lời giải' : 'Xem lại bài làm & Lời giải'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
        if (roomId != null && roomId.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _openLeaderboardModal(roomId),
            icon: const Icon(Icons.leaderboard_rounded, color: AppTheme.primary),
            label: const Text('Bảng xếp hạng trực tiếp'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Về trang chủ'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionReviewSection(AttemptReviewPayload review) {
    final filteredQuestions = review.questions.where((q) {
      if (_questionFilter == 'correct') return q.isCorrect;
      if (_questionFilter == 'wrong') return q.isWrong;
      if (_questionFilter == 'skipped') return q.isSkipped;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chi tiết bài làm & Lời giải',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              '${filteredQuestions.length}/${review.questions.length} câu',
              style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tất cả (${review.questions.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Câu đúng (${review.correctCount})', 'correct', color: AppTheme.success),
              const SizedBox(width: 8),
              _buildFilterChip('Câu sai (${review.wrongCount})', 'wrong', color: AppTheme.error),
              const SizedBox(width: 8),
              _buildFilterChip('Chưa làm (${review.skippedCount})', 'skipped', color: AppTheme.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (filteredQuestions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: const Text('Không có câu hỏi nào trong bộ lọc này.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredQuestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final q = filteredQuestions[index];
              return _buildQuestionCard(q);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String key, {Color? color}) {
    final isSelected = _questionFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _questionFilter = key),
      selectedColor: color?.withValues(alpha: 0.15) ?? AppTheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppTheme.primary) : AppTheme.textMain,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildQuestionCard(ReviewQuestion q) {
    Color statusColor = AppTheme.textSecondary;
    String statusText = 'Chưa làm';
    IconData statusIcon = Icons.help_outline;

    if (q.isCorrect) {
      statusColor = AppTheme.success;
      statusText = 'Đúng (+${q.points}đ)';
      statusIcon = Icons.check_circle;
    } else if (q.isWrong) {
      statusColor = AppTheme.error;
      statusText = 'Sai (0đ)';
      statusIcon = Icons.cancel;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: q.isCorrect
              ? AppTheme.success.withValues(alpha: 0.3)
              : (q.isWrong ? AppTheme.error.withValues(alpha: 0.3) : AppTheme.border),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Câu ${q.position}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(q.body, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),

          // Options
          ...q.options.map((opt) {
            final isUserSelected = opt.id == q.selectedOptionId;
            final isCorrectAnswer = opt.isCorrect;

            Color borderColor = AppTheme.border;
            Color bgColor = Colors.transparent;
            Widget? icon;

            if (isCorrectAnswer) {
              borderColor = AppTheme.success;
              bgColor = AppTheme.success.withValues(alpha: 0.08);
              icon = const Icon(Icons.check_circle, color: AppTheme.success, size: 20);
            } else if (isUserSelected && !isCorrectAnswer) {
              borderColor = AppTheme.error;
              bgColor = AppTheme.error.withValues(alpha: 0.08);
              icon = const Icon(Icons.cancel, color: AppTheme.error, size: 20);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: isUserSelected || isCorrectAnswer ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      opt.body,
                      style: TextStyle(
                        fontWeight: isUserSelected || isCorrectAnswer ? FontWeight.bold : FontWeight.normal,
                        color: isCorrectAnswer ? AppTheme.success : (isUserSelected ? AppTheme.error : AppTheme.textMain),
                      ),
                    ),
                  ),
                  if (icon != null) icon,
                ],
              ),
            );
          }),

          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.primary),
                      SizedBox(width: 6),
                      Text('Lời giải chi tiết:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(q.explanation, style: const TextStyle(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
