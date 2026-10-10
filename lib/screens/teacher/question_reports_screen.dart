import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/question_report_repository.dart';
import '../../core/theme/app_theme.dart';

class QuestionReportsScreen extends StatefulWidget {
  const QuestionReportsScreen({super.key});

  @override
  State<QuestionReportsScreen> createState() => _QuestionReportsScreenState();
}

class _QuestionReportsScreenState extends State<QuestionReportsScreen> {
  List<QuestionReport> _reports = [];
  bool _loading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final reports = await context
          .read<QuestionReportRepository>()
          .teacherReports();
      if (mounted) setState(() => _reports = reports);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải báo cáo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<QuestionReport> get _visible => _filter == 'all'
      ? _reports
      : _reports.where((report) => report.status == _filter).toList();

  Future<void> _resolve(QuestionReport report, bool accepted) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(accepted ? 'Đánh dấu đã xử lý' : 'Bỏ qua báo cáo'),
        content: TextField(
          key: const Key('teacher-report-note'),
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Ghi chú cho quyết định (không bắt buộc)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(accepted ? 'Đã sửa xong' : 'Bỏ qua'),
          ),
        ],
      ),
    );
    final note = controller.text;
    controller.dispose();
    if (confirmed != true) return;
    if (!mounted) return;
    await context.read<QuestionReportRepository>().resolve(
      reportId: report.id,
      accepted: accepted,
      teacherNote: note,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Báo cáo câu hỏi'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _filterChip('pending', 'Chờ xử lý'),
                _filterChip('resolved', 'Đã xử lý'),
                _filterChip('dismissed', 'Đã bỏ qua'),
                _filterChip('all', 'Tất cả'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _visible.isEmpty
                ? const Center(child: Text('Không có báo cáo trong mục này.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: _visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _reportCard(_visible[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) => ChoiceChip(
    label: Text(label),
    selected: _filter == value,
    onSelected: (_) => setState(() => _filter = value),
  );

  Widget _reportCard(QuestionReport report) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${report.examTitle} · Câu ${report.questionPosition}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _statusBadge(report.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.questionBody,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            report.categoryInfo?.label ?? 'Vấn đề khác',
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (report.detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(report.detail),
          ],
          if (report.teacherNote.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Ghi chú: ${report.teacherNote}'),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    context.go('/create_exam?examId=${report.examId}'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Mở đề để sửa'),
              ),
              if (report.status == 'pending') ...[
                FilledButton.icon(
                  key: Key('resolve-report-${report.id}'),
                  onPressed: () => _resolve(report, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Đã xử lý'),
                ),
                TextButton(
                  onPressed: () => _resolve(report, false),
                  child: const Text('Bỏ qua'),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );

  Widget _statusBadge(String status) {
    final label = switch (status) {
      'resolved' => 'Đã xử lý',
      'dismissed' => 'Đã bỏ qua',
      _ => 'Chờ xử lý',
    };
    final color = switch (status) {
      'resolved' => AppTheme.success,
      'dismissed' => AppTheme.textSecondary,
      _ => AppTheme.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
