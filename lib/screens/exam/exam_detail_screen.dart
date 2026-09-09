import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class ExamDetailScreen extends StatefulWidget {
  const ExamDetailScreen({super.key});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  final _roomCodeController = TextEditingController();
  bool _saved = false;
  bool _isLoading = true;
  Map<String, dynamic>? _examData;

  @override
  void initState() {
    super.initState();
    _fetchRealExam();
  }

  Future<void> _fetchRealExam() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final res = await client.from('exams').select().order('created_at', ascending: false).limit(1).maybeSingle();
      if (mounted) {
        setState(() {
          _examData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin đề thi: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _start() {
    if (_roomCodeController.text.trim().isNotEmpty) {
      context.go('/room/password');
      return;
    }
    context.go('/taking_exam');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = _examData?['title'] as String? ?? 'Đề thi trắc nghiệm ôn tập';
    final subject = _examData?['subject'] as String? ?? 'Tổng hợp';
    final totalQuestions = (_examData?['total_questions'] as num?)?.toInt() ?? 40;
    final examCode = _examData?['code'] as String? ?? 'DT001';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton(onPressed: () => context.go('/home'), child: const Text('Trang chủ')),
                    const Icon(Icons.chevron_right),
                    TextButton(onPressed: () => context.go('/search'), child: const Text('Tìm kiếm')),
                    const Icon(Icons.chevron_right),
                    const Text('Chi tiết đề thi'),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 840;
                  final summary = _ExamSummaryCard(
                    title: title,
                    subject: subject,
                    questionsCount: totalQuestions,
                    code: examCode,
                  );
                  final action = _ActionPanel(
                    controller: _roomCodeController,
                    saved: _saved,
                    onStart: _start,
                    onSaved: () => setState(() => _saved = !_saved),
                  );
                  return Column(
                    children: [
                      summary,
                      const SizedBox(height: 28),
                      if (narrow)
                        action
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(flex: 2, child: _ExamInformation()),
                            const SizedBox(width: 28),
                            SizedBox(width: 360, child: action),
                          ],
                        ),
                      if (narrow) ...[const SizedBox(height: 28), const _ExamInformation()],
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamSummaryCard extends StatelessWidget {
  const _ExamSummaryCard({
    required this.title,
    required this.subject,
    required this.questionsCount,
    required this.code,
  });

  final String title;
  final String subject;
  final int questionsCount;
  final String code;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final cover = Container(
            width: narrow ? double.infinity : 290,
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [Color(0xFFE7E4FF), Color(0xFFF7F4FF)]),
            ),
            child: const Icon(Icons.description_outlined, size: 92, color: AppTheme.primary),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, children: [Chip(label: Text(subject)), Chip(label: Text('Mã: $code'))]),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const Divider(height: 36),
              Wrap(
                spacing: 30,
                runSpacing: 16,
                children: [
                  _Fact(Icons.format_list_numbered, '$questionsCount câu hỏi'),
                  const _Fact(Icons.schedule_outlined, '60 phút'),
                  const _Fact(Icons.bar_chart_rounded, 'Độ khó: Chuẩn kiến thức'),
                ],
              ),
            ],
          );
          return narrow
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [cover, const SizedBox(height: 24), details])
              : Row(children: [cover, const SizedBox(width: 26), Expanded(child: details)]);
        }),
      );
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, color: AppTheme.primary), const SizedBox(width: 8), Text(text)],
      );
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.controller,
    required this.saved,
    required this.onStart,
    required this.onSaved,
  });

  final TextEditingController controller;
  final bool saved;
  final VoidCallback onStart;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: const Border(top: BorderSide(color: AppTheme.primary, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sẵn sàng làm bài?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Mã phòng thi (nếu có)',
                hintText: 'Nhập mã phòng PTxxxxxx do giáo viên cung cấp',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Vào làm bài ngay'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onSaved,
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              label: Text(saved ? 'Đã lưu vào yêu thích' : 'Lưu vào yêu thích'),
            ),
          ],
        ),
      );
}

class _ExamInformation extends StatelessWidget {
  const _ExamInformation();
  @override
  Widget build(BuildContext context) => Column(
        children: const [
          _InfoBox(
            icon: Icons.info_outline,
            title: 'Giới thiệu bài thi',
            body: 'Đề thi trắc nghiệm được hệ thống tự động lưu trữ và đồng bộ dữ liệu chuẩn với CSDL Supabase.',
          ),
          SizedBox(height: 22),
          _InfoBox(
            icon: Icons.gavel_outlined,
            title: 'Hướng dẫn & Quy chế',
            body: '• Giữ kết nối mạng ổn định trong suốt quá trình chọn đáp án.\n• Hệ thống tự động lưu kết quả nộp bài khi hoàn thành.',
          ),
        ],
      );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: AppTheme.primary), const SizedBox(width: 10), Text(title, style: Theme.of(context).textTheme.titleLarge)]),
            const SizedBox(height: 14),
            Text(body, style: const TextStyle(height: 1.7)),
          ],
        ),
      );
}
