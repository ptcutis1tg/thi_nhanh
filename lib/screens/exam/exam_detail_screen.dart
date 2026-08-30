import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/repositories/assessment_repository.dart';

class ExamDetailScreen extends StatefulWidget {
  const ExamDetailScreen({super.key});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  static const _demoExamId = '10000000-0000-4000-8000-000000000002';
  final _roomCodeController = TextEditingController();
  bool _saved = false;
  bool _isStarting = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_roomCodeController.text.trim().isNotEmpty) {
      context.go('/room/password');
      return;
    }
    setState(() => _isStarting = true);
    try {
      final attempt = await context.read<AssessmentRepository>().beginPractice(_demoExamId);
      if (mounted) context.go('/taking_exam?attemptId=${attempt.attemptId}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Không thể bắt đầu đề. Hãy kiểm tra cấu hình Supabase và migrations.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [TextButton(onPressed: () => context.go('/home'), child: const Text('Trang chủ')), const Icon(Icons.chevron_right), TextButton(onPressed: () => context.go('/search'), child: const Text('Tìm kiếm')), const Icon(Icons.chevron_right), const Text('Chi tiết đề thi')]),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 840;
            final summary = _ExamSummaryCard();
            final action = _ActionPanel(controller: _roomCodeController, saved: _saved, isStarting: _isStarting, onStart: _start, onSaved: () => setState(() => _saved = !_saved));
            return Column(children: [
              summary,
              const SizedBox(height: 28),
              if (narrow) action else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Expanded(flex: 2, child: _ExamInformation()), const SizedBox(width: 28), SizedBox(width: 360, child: action)]),
              if (narrow) ...[const SizedBox(height: 28), const _ExamInformation()],
            ]);
          }),
        ]),
      ),
    ),
  );
}

class _ExamSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppTheme.border)),
    child: LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 760;
      final cover = Container(width: narrow ? double.infinity : 290, height: 210, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFFE7E4FF), Color(0xFFF7F4FF)])), child: const Icon(Icons.waves_rounded, size: 92, color: AppTheme.primary));
      final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, children: const [Chip(label: Text('Vật lý')), Chip(label: Text('ĐT'))]),
        const SizedBox(height: 12), Text('Ôn tập Dao động cơ học - Vật lý 12 cơ bản và nâng cao', style: Theme.of(context).textTheme.headlineSmall),
        const Divider(height: 36),
        Wrap(spacing: 30, runSpacing: 16, children: const [_Fact(Icons.format_list_numbered, '50 câu hỏi'), _Fact(Icons.schedule_outlined, '90 phút'), _Fact(Icons.bar_chart_rounded, 'Độ khó: Trung bình'), _Fact(Icons.groups_outlined, '1.2k lượt làm')]),
      ]);
      return narrow ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [cover, const SizedBox(height: 24), details]) : Row(children: [cover, const SizedBox(width: 26), Expanded(child: details)]);
    }),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: AppTheme.primary), const SizedBox(width: 8), Text(text)]);
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.controller, required this.saved, required this.isStarting, required this.onStart, required this.onSaved});
  final TextEditingController controller;
  final bool saved;
  final bool isStarting;
  final Future<void> Function() onStart;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: const Border(top: BorderSide(color: AppTheme.primary, width: 3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Sẵn sàng làm bài?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 20),
      TextField(controller: controller, decoration: const InputDecoration(labelText: 'Mã phòng thi (nếu có)', hintText: 'Nhập mã phòng do giáo viên cung cấp')),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: isStarting ? null : onStart, icon: isStarting ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow), label: Text(isStarting ? 'Đang chuẩn bị đề...' : 'Bắt đầu tự luyện')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: onSaved, icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border), label: Text(saved ? 'Đã lưu vào yêu thích' : 'Lưu vào yêu thích')),
    ]),
  );
}

class _ExamInformation extends StatelessWidget {
  const _ExamInformation();
  @override
  Widget build(BuildContext context) => Column(children: const [_InfoBox(icon: Icons.info_outline, title: 'Giới thiệu', body: 'Đề thi được biên soạn nhằm giúp học sinh lớp 12 ôn tập và củng cố kiến thức chuyên đề Dao động cơ học. Đề bao phủ từ các khái niệm cơ bản đến bài toán vận dụng cao.'), SizedBox(height: 22), _InfoBox(icon: Icons.view_list_outlined, title: 'Cấu trúc đề thi', body: '• Dao động điều hòa (15 câu)\n• Con lắc lò xo (10 câu)\n• Con lắc đơn (10 câu)\n• Dao động tắt dần, cưỡng bức, cộng hưởng (5 câu)\n• Tổng hợp dao động (10 câu)'), SizedBox(height: 22), _InfoBox(icon: Icons.gavel_outlined, title: 'Hướng dẫn & Lưu ý', body: '• Không thoát khỏi màn hình làm bài hoặc chuyển tab.\n• Bài thi tự nộp khi hết 90 phút.\n• Có thể nộp bài sau khi làm ít nhất 50% số câu hỏi.')]);
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: AppTheme.primary), const SizedBox(width: 10), Text(title, style: Theme.of(context).textTheme.titleLarge)]), const SizedBox(height: 14), Text(body, style: const TextStyle(height: 1.7))]));
}
