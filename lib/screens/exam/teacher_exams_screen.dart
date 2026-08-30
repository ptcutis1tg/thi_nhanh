import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/teacher_exam_repository.dart';
import '../../core/theme/app_theme.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen> {
  List<TeacherExamSummary> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exams = await context.read<TeacherExamRepository>().summaries();
    if (mounted) setState(() {
      _exams = exams;
      _loading = false;
    });
  }

  Future<void> _publish(TeacherExamSummary exam) async {
    await context.read<TeacherExamRepository>().publish(exam.id);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đề đã được xuất bản và có thể dùng để tạo phòng.'), backgroundColor: AppTheme.success));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        floatingActionButton: FloatingActionButton.extended(onPressed: () => context.go('/create_exam'), icon: const Icon(Icons.add), label: const Text('Tạo đề mới')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Quản lý đề thi', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Xem lại, chỉnh sửa nháp hoặc xuất bản đề để dùng cho phòng thi.', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 28),
                      if (_exams.isEmpty)
                        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.menu_book_outlined, size: 48, color: AppTheme.primary), const SizedBox(height: 12), const Text('Chưa có đề nào.'), const SizedBox(height: 12), ElevatedButton(onPressed: () => context.go('/create_exam'), child: const Text('Tạo đề đầu tiên'))])))
                      else Expanded(child: ListView.separated(itemCount: _exams.length, separatorBuilder: (_, __) => const SizedBox(height: 14), itemBuilder: (_, index) => _ExamRow(exam: _exams[index], onEdit: () => context.go('/create_exam?examId=${_exams[index].id}'), onPublish: _exams[index].status == 'published' ? null : () => _publish(_exams[index])))),
                    ]),
            ),
          ),
        ),
      );
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({required this.exam, required this.onEdit, required this.onPublish});
  final TeacherExamSummary exam;
  final VoidCallback onEdit;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final published = exam.status == 'published';
    return Card(child: Padding(padding: const EdgeInsets.all(22), child: Row(children: [
      Icon(published ? Icons.public : Icons.edit_note_outlined, color: published ? AppTheme.success : AppTheme.primary, size: 30),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(exam.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text('${exam.subject} • ${exam.questionCount} câu • ${exam.durationMinutes} phút', style: const TextStyle(color: AppTheme.textSecondary))])),
      Chip(label: Text(published ? 'Đã xuất bản' : 'Bản nháp'), backgroundColor: published ? AppTheme.success.withValues(alpha: .10) : AppTheme.primary.withValues(alpha: .10)),
      const SizedBox(width: 10),
      TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Sửa')),
      if (!published) ElevatedButton(onPressed: onPublish, child: const Text('Xuất bản')),
    ])));
  }
}
