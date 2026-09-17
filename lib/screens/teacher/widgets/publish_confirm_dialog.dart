import 'package:flutter/material.dart';
import '../../../core/repositories/teacher_exam_repository.dart';
import '../../../core/theme/app_theme.dart';

class PublishConfirmDialog extends StatefulWidget {
  const PublishConfirmDialog({
    super.key,
    required this.summary,
    required this.onConfirmed,
  });

  final TeacherExamSummary summary;
  final Future<void> Function() onConfirmed;

  @override
  State<PublishConfirmDialog> createState() => _PublishConfirmDialogState();
}

class _PublishConfirmDialogState extends State<PublishConfirmDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get _hasQuestions => widget.summary.questionCount > 0;
  bool get _hasValidTitle => widget.summary.title.trim().length >= 3;
  bool get _canPublish => _hasQuestions && _hasValidTitle;

  Future<void> _handleConfirm() async {
    if (!_canPublish || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirmed();
      if (mounted) {
        setState(() => _isLoading = false);
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('PostgrestException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xuất bản đề thi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Công khai bộ đề lên hệ thống để học sinh thi hoặc tạo phòng',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Exam Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEBE6F8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBadge(Icons.subject_rounded, s.subject),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.timer_outlined, '${s.durationMinutes} phút'),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.help_outline_rounded, '${s.questionCount} câu'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Checklist
              const Text(
                'Điều kiện kiểm tra:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMain),
              ),
              const SizedBox(height: 10),
              _buildChecklistItem(
                isValid: _hasValidTitle,
                title: 'Tên đề thi hợp lệ (ít nhất 3 ký tự)',
              ),
              const SizedBox(height: 8),
              _buildChecklistItem(
                isValid: _hasQuestions,
                title: 'Đề có ít nhất 1 câu hỏi (Hiện có ${s.questionCount} câu)',
                errorText: 'Bạn cần thêm câu hỏi trước khi xuất bản',
              ),
              const SizedBox(height: 16),

              // Explanation note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sau khi xuất bản, đề thi sẽ chuyển sang trạng thái "Đã công khai". Học sinh có thể tìm kiếm và làm bài ngay.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context, rootNavigator: true).maybePop(false),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _canPublish && !_isLoading ? _handleConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isLoading ? 'Đang xuất bản...' : 'Xác nhận Xuất bản'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E0F8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({required bool isValid, required String title, String? errorText}) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: isValid ? AppTheme.success : AppTheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isValid ? title : (errorText ?? title),
            style: TextStyle(
              fontSize: 13,
              color: isValid ? AppTheme.textMain : AppTheme.error,
              fontWeight: isValid ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
