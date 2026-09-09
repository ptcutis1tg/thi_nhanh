import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class QuestionDraft {
  String title;
  List<String> options;
  int correctOptionIndex;

  QuestionDraft({
    required this.title,
    required this.options,
    this.correctOptionIndex = 0,
  });
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final TextEditingController _examNameController = TextEditingController(text: 'Đề thi trắc nghiệm mới');
  final TextEditingController _durationController = TextEditingController(text: '45');
  String _selectedSubject = 'Toán học';
  String _selectedDifficulty = 'medium';

  int _activeQuestionIndex = 0;
  bool _isSaving = false;

  final List<QuestionDraft> _questions = [
    QuestionDraft(
      title: 'Câu hỏi số 1: Nhập nội dung câu hỏi tại đây...',
      options: ['Phương án A', 'Phương án B', 'Phương án C', 'Phương án D'],
      correctOptionIndex: 0,
    ),
    QuestionDraft(
      title: 'Câu hỏi số 2: Nhập nội dung câu hỏi...',
      options: ['Đáp án 1', 'Đáp án 2', 'Đáp án 3', 'Đáp án 4'],
      correctOptionIndex: 1,
    ),
  ];

  @override
  void dispose() {
    _examNameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveExam({bool isPublished = true}) async {
    final title = _examNameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đề thi!'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final client = Supabase.instance.client;
      
      // Get teacher ID or default
      final teacherRes = await client.from('teachers').select('id').limit(1).maybeSingle();
      final teacherId = teacherRes?['id']?.toString() ?? '00000000-0000-4000-8000-000000000001';

      final examCode = 'DT${(100000 + Random().nextInt(899999)).toString()}';
      final duration = int.tryParse(_durationController.text) ?? 45;

      // 1. Insert Exam
      final examRes = await client.from('exams').insert({
        'code': examCode,
        'teacher_id': teacherId,
        'title': title,
        'description': 'Đề thi được khởi tạo từ hệ thống Thi Nhanh.',
        'subject': _selectedSubject,
        'difficulty': _selectedDifficulty,
        'duration_minutes': duration,
        'status': isPublished ? 'published' : 'draft',
        'published_at': isPublished ? DateTime.now().toIso8601String() : null,
      }).select('id').single();

      final examId = examRes['id'].toString();

      // 2. Insert Questions & Options
      for (int i = 0; i < _questions.length; i++) {
        final qDraft = _questions[i];
        final qRes = await client.from('questions').insert({
          'exam_id': examId,
          'position': i + 1,
          'body': qDraft.title,
          'explanation': 'Đáp án đúng dựa trên quy tắc tính toán.',
          'points': 1.0,
        }).select('id').single();

        final qId = qRes['id'].toString();

        for (int optIdx = 0; optIdx < qDraft.options.length; optIdx++) {
          await client.from('question_options').insert({
            'question_id': qId,
            'position': optIdx + 1,
            'body': qDraft.options[optIdx],
            'is_correct': optIdx == qDraft.correctOptionIndex,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã khởi tạo bộ đề thi thành công với mã $examCode!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/teacher/exams');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo đề thi lên Supabase: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        QuestionDraft(
          title: 'Câu hỏi số ${_questions.length + 1}...',
          options: ['Đáp án A', 'Đáp án B', 'Đáp án C', 'Đáp án D'],
          correctOptionIndex: 0,
        ),
      );
      _activeQuestionIndex = _questions.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Đề Thi Trắc Nghiệm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainCanvas()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DANH SÁCH CÂU HỎI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                  tooltip: 'Thêm câu hỏi',
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isActive = index == _activeQuestionIndex;
                return InkWell(
                  onTap: () => setState(() => _activeQuestionIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary.withOpacity(0.1) : Colors.white,
                      border: Border.all(
                        color: isActive ? AppTheme.primary : AppTheme.border,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.primary : AppTheme.border,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _questions[index].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? AppTheme.primary : AppTheme.textMain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCanvas() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final currentQ = _questions[_activeQuestionIndex];

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin chung Đề thi
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin bộ đề', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _examNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên bộ đề thi *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSubject,
                            decoration: const InputDecoration(labelText: 'Môn học', border: OutlineInputBorder()),
                            items: ['Toán học', 'Vật lý', 'Tiếng Anh', 'Hóa học', 'Tin học', 'Ngữ văn']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedSubject = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Thời gian làm bài (Phút)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Soạn thảo câu hỏi hiện tại
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu hỏi số ${_activeQuestionIndex + 1}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: currentQ.title,
                      onChanged: (val) {
                        setState(() {
                          currentQ.title = val;
                        });
                      },
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung câu hỏi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Các phương án lựa chọn (Đánh dấu phương án đúng):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...List.generate(currentQ.options.length, (optIdx) {
                      final isCorrect = currentQ.correctOptionIndex == optIdx;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCorrect ? AppTheme.success.withOpacity(0.05) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCorrect ? AppTheme.success : AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: optIdx,
                              groupValue: currentQ.correctOptionIndex,
                              onChanged: (val) {
                                setState(() {
                                  currentQ.correctOptionIndex = val!;
                                });
                              },
                              activeColor: AppTheme.success,
                            ),
                            Text(
                              '${String.fromCharCode(65 + optIdx)}.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: currentQ.options[optIdx],
                                onChanged: (val) {
                                  currentQ.options[optIdx] = val;
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Nhập phương án...',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom Action Bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppTheme.border)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tự động kết nối Supabase Database', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => _saveExam(isPublished: false),
                      child: const Text('Lưu nháp'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _saveExam(isPublished: true),
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: Text(_isSaving ? 'Đang tạo đề...' : 'Lưu & Khởi tạo Đề'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
