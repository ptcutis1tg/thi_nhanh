import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ExamRightSidebar extends StatelessWidget {
  const ExamRightSidebar({
    super.key,
    required this.examTitle,
    required this.subject,
    required this.durationMinutes,
    required this.questionCount,
    this.totalPoints = 10.0,
    this.onDistributePointsEvenly,
    required this.perQuestionTimerEnabled,
    required this.onTogglePerQuestionTimer,
  });

  final String examTitle;
  final String subject;
  final int durationMinutes;
  final int questionCount;
  final double totalPoints;
  final VoidCallback? onDistributePointsEvenly;
  final bool perQuestionTimerEnabled;
  final ValueChanged<bool> onTogglePerQuestionTimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'TỔNG QUAN ĐỀ THI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          // Exam summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examTitle.isEmpty ? 'Chưa đặt tên đề' : examTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      subject.isEmpty || subject == 'none' ? 'none' : subject,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$durationMinutes phút',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.quiz_outlined, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$questionCount câu',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'THANG ĐIỂM ĐỀ THI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          // Points overview card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Tổng điểm:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${totalPoints.toStringAsFixed(2)} đ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: (totalPoints - 10.0).abs() < 0.01 ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                if (onDistributePointsEvenly != null && questionCount > 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDistributePointsEvenly,
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Chia đều 10 điểm', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'CẤU HÌNH THỜI GIAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          // Timer toggle card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Tính giờ riêng theo từng câu',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: perQuestionTimerEnabled,
                      activeThumbColor: AppTheme.primary,
                      onChanged: onTogglePerQuestionTimer,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  perQuestionTimerEnabled
                      ? 'Đang bật: Mỗi câu hỏi có thể thiết lập số giây làm bài độc lập.'
                      : 'Đang tắt: Toàn bộ đề thi dùng chung đồng hồ đếm ngược $durationMinutes phút.',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
