import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/teacher_exam_repository.dart';
import '../../core/repositories/room_repository.dart';
import '../../core/theme/app_theme.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _roomNameController = TextEditingController();
  final _passwordController = TextEditingController();
  List<TeacherExamSummary> _createdExams = [];
  TeacherExamSummary? _selectedExam;
  bool _requirePassword = false;
  bool _isLoadingExams = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadCreatedExams();
  }

  Future<void> _loadCreatedExams() async {
    final exams = await context.read<TeacherExamRepository>().summaries();
    if (mounted) setState(() {
      _createdExams = exams.where((exam) => exam.status == 'published').toList();
      _isLoadingExams = false;
    });
  }

  Future<void> _createRoom() async {
    if (_roomNameController.text.trim().isEmpty || _selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hãy đặt tên phòng và chọn đề thi.'), backgroundColor: AppTheme.error));
      return;
    }
    setState(() => _isCreating = true);
    try {
      final room = await context.read<RoomRepository>().create(
            examId: _selectedExam!.id,
            name: _roomNameController.text.trim(),
            password: _requirePassword ? _passwordController.text : null,
          );
      if (mounted) context.go('/teacher_waiting_room?roomId=${room.id}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo phòng: $error'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tạo phòng thi', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Chọn một đề bạn đã khởi tạo, sau đó mời học sinh vào phòng.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('1. Thông tin phòng thi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      TextField(controller: _roomNameController, decoration: const InputDecoration(labelText: 'Tên phòng thi *', prefixIcon: Icon(Icons.meeting_room_outlined))),
                      const SizedBox(height: 18),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Yêu cầu mật khẩu'),
                        subtitle: const Text('Học sinh cần nhập mật khẩu trước khi vào phòng.'),
                        value: _requirePassword,
                        onChanged: (value) => setState(() => _requirePassword = value),
                      ),
                      if (_requirePassword) ...[
                        const SizedBox(height: 8),
                        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu phòng', prefixIcon: Icon(Icons.lock_outline))),
                      ],
                      const Divider(height: 56),
                      const Text('2. Chọn đề thi đã tạo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Chỉ những đề bạn đã khởi tạo mới có thể dùng để mở phòng.', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 18),
                      if (_isLoadingExams)
                        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                      else if (_createdExams.isEmpty)
                        _EmptyExamState(onCreateExam: () => context.go('/teacher_exams'))
                      else ...[
                        DropdownButtonFormField<TeacherExamSummary>(
                          value: _selectedExam,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Đề thi *', prefixIcon: Icon(Icons.menu_book_outlined)),
                          items: _createdExams.map((exam) => DropdownMenuItem(value: exam, child: Text(exam.title, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (exam) => setState(() => _selectedExam = exam),
                        ),
                        if (_selectedExam != null) ...[
                          const SizedBox(height: 16),
                          _ExamPreview(exam: _selectedExam!),
                        ],
                      ],
                      const SizedBox(height: 36),
                      SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(onPressed: _selectedExam == null ? null : _createRoom, icon: const Icon(Icons.play_arrow), label: const Text('Khởi tạo phòng thi'))),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _EmptyExamState extends StatelessWidget {
  const _EmptyExamState({required this.onCreateExam});
  final VoidCallback onCreateExam;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: .06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withValues(alpha: .2))),
        child: Column(children: [
          const Icon(Icons.note_add_outlined, size: 36, color: AppTheme.primary),
          const SizedBox(height: 10),
          const Text('Bạn chưa có đề nào để mở phòng.', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Hãy khởi tạo đề trước, rồi quay lại chọn đề cho phòng thi.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: onCreateExam, icon: const Icon(Icons.add), label: const Text('Tạo đề mới')),
        ]),
      );
}

class _ExamPreview extends StatelessWidget {
  const _ExamPreview({required this.exam});
  final TeacherExamSummary exam;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: .06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withValues(alpha: .28))),
        child: Row(children: [
          const Icon(Icons.check_circle, color: AppTheme.success),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${exam.subject} • ${exam.questionCount} câu • ${exam.durationMinutes} phút', style: const TextStyle(color: AppTheme.textSecondary))])),
        ]),
      );
}
