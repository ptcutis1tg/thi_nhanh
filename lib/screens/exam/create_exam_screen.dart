import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/question_draft.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/repositories/teacher_exam_repository.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/exam_left_sidebar.dart';
import 'widgets/exam_right_sidebar.dart';
import 'widgets/latex_math_view.dart';
import 'widgets/question_answers_editor.dart';
import 'widgets/quick_bulk_import_dialog.dart';
import 'widgets/scientific_bottom_toolbar.dart';
import 'widgets/student_exam_preview_dialog.dart';
import 'widgets/inline_visual_math_editor.dart';
import '../../core/models/scientific_shortcut.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key, this.examId});

  final String? examId;

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _editorController = InlineVisualMathEditorController();
  final _examNameController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  String? _selectedSubject;
  bool _isConfigured = false;
  bool _isLoading = false;
  String? _examId;
  String _status = 'draft';
  int _activeQuestionIndex = 0;
  DateTime? _lastSavedAt;
  bool _perQuestionTimerEnabled = false;
  ScientificCategory _scientificCategory = ScientificCategory.math;
  Map<ScientificCategory, List<ScientificShortcut>> _scientificShortcuts =
      ScientificShortcutStore.freshDefaults();

  final List<QuestionDraft> _questions = [];

  // Active controller and focus tracking for snippet insertion
  TextEditingController? _activeTextController;
  final Map<String, TextEditingController> _bodyControllers = {};
  final Map<String, TextEditingController> _explanationControllers = {};

  double get _totalPoints => _questions.fold<double>(
    0,
    (sum, question) =>
        sum + (double.tryParse(question.points.replaceAll(',', '.')) ?? 0),
  );

  void _distributePointsEvenly() {
    if (_questions.isEmpty) return;
    const totalHundredths = 1000;
    final base = totalHundredths ~/ _questions.length;
    var remainder = totalHundredths % _questions.length;
    setState(() {
      for (final question in _questions) {
        final value = base + (remainder > 0 ? 1 : 0);
        if (remainder > 0) remainder--;
        question.points = (value / 100).toStringAsFixed(2);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _examId = widget.examId;
    if (_examId != null) {
      _loadExistingExam();
    }
  }

  Future<void> _loadExistingExam() async {
    setState(() => _isLoading = true);
    final exam = await context.read<TeacherExamRepository>().draft(_examId!);
    if (!mounted) return;

    if (exam != null) {
      setState(() {
        _examNameController.text = exam['title'] as String;
        _durationController.text = '${exam['durationMinutes']}';
        _selectedSubject = exam['subject'] as String;
        _status = exam['status'] as String;

        _questions.clear();
        final rawQuestions = exam['questions'] as List<dynamic>? ?? [];
        for (var item in rawQuestions) {
          _questions.add(
            QuestionDraft.fromJson(Map<String, dynamic>.from(item as Map)),
          );
        }

        if (_questions.any(
          (q) => q.timeLimitSeconds != null && q.timeLimitSeconds! > 0,
        )) {
          _perQuestionTimerEnabled = true;
        }

        if (_questions.isEmpty) _addQuestion();
        _isConfigured = true;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _durationController.dispose();
    for (var c in _bodyControllers.values) {
      c.dispose();
    }
    for (var c in _explanationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _configureExam() {
    final title = _examNameController.text.trim();
    if (title.isEmpty || _selectedSubject == null) {
      _showMessage('Hãy nhập tên đề và chọn môn học.', isError: true);
      return;
    }
    if (title.length < 3) {
      _showMessage('Tên đề thi phải có ít nhất 3 ký tự.', isError: true);
      return;
    }
    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration < 1 || duration > 360) {
      _showMessage('Thời lượng thi phải từ 1 đến 360 phút.', isError: true);
      return;
    }
    setState(() {
      _isConfigured = true;
      if (_questions.isEmpty) {
        _addQuestion();
      }
    });
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        QuestionDraft(id: DateTime.now().microsecondsSinceEpoch.toString()),
      );
      _activeQuestionIndex = _questions.length - 1;
    });
  }

  void _duplicateQuestion(int index) {
    final original = _questions[index];
    final copy = original.copyWith(
      id: '${DateTime.now().microsecondsSinceEpoch}_copy',
    );
    setState(() {
      _questions.insert(index + 1, copy);
      _activeQuestionIndex = index + 1;
    });
    _showMessage('Đã nhân bản câu hỏi ${index + 1}.');
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      _showMessage('Đề cần có ít nhất một câu hỏi.', isError: true);
      return;
    }
    setState(() {
      _questions.removeAt(index);
      _activeQuestionIndex = _activeQuestionIndex.clamp(
        0,
        _questions.length - 1,
      );
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
      _activeQuestionIndex = newIndex;
    });
  }

  void _handleBulkImport(List<QuestionDraft> importedQuestions) {
    if (importedQuestions.isEmpty) return;
    setState(() {
      _questions.addAll(importedQuestions);
      _activeQuestionIndex = _questions.length - 1;
    });
    _showMessage(
      'Đã nhập thành công ${importedQuestions.length} câu hỏi vào đề!',
    );
  }

  void _insertSnippetAtCursor(
    String template,
    int selectionOffset,
    int selectionLength,
  ) {
    final q = _questions[_activeQuestionIndex];
    setState(() {
      q.body = q.body.isEmpty ? template : '${q.body} $template';
    });
  }

  Future<bool> _saveDraft() async {
    if (!context.read<AuthProvider>().hasSupabaseSession) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bạn cần đăng nhập bằng tài khoản Supabase trước khi lưu đề.',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
        context.go('/greeting');
      }
      return false;
    }
    if (!_isConfigured) return false;

    setState(() => _isLoading = true);
    try {
      final savedId = await context.read<TeacherExamRepository>().saveDraft(
        examId: _examId,
        title: _examNameController.text.trim(),
        subject: _selectedSubject ?? '',
        durationMinutes: int.tryParse(_durationController.text) ?? 45,
        questions: _questions.map((q) => q.toJson()).toList(),
      );
      if (!mounted) return false;
      setState(() {
        _examId = savedId;
        _lastSavedAt = DateTime.now();
        _isLoading = false;
      });
      _showMessage('Đã lưu nháp thành công.');
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage(
          'Lỗi khi lưu đề: ${e.toString().replaceAll('PostgrestException: ', '')}',
          isError: true,
        );
      }
      return false;
    }
  }

  Future<void> _publishExam() async {
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.body.trim().isEmpty) {
        setState(() => _activeQuestionIndex = i);
        _showMessage(
          'Hãy nhập nội dung cho Câu ${i + 1} trước khi xuất bản.',
          isError: true,
        );
        return;
      }

      if (q.type == QuestionType.singleChoice ||
          q.type == QuestionType.multipleChoice) {
        if (q.answers.any((a) => a.trim().isEmpty)) {
          setState(() => _activeQuestionIndex = i);
          _showMessage(
            'Hãy điền đầy đủ nội dung các đáp án cho Câu ${i + 1}.',
            isError: true,
          );
          return;
        }
        if (q.correctAnswers.isEmpty) {
          setState(() => _activeQuestionIndex = i);
          _showMessage(
            'Hãy chọn ít nhất một đáp án đúng cho Câu ${i + 1}.',
            isError: true,
          );
          return;
        }
      } else if (q.type == QuestionType.shortAnswer) {
        if (q.answers.isEmpty || q.answers.first.trim().isEmpty) {
          setState(() => _activeQuestionIndex = i);
          _showMessage(
            'Hãy nhập đáp án chuẩn cho Câu điền khuyết số ${i + 1}.',
            isError: true,
          );
          return;
        }
      }
    }

    final success = await _saveDraft();
    if (!success || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final repo = context.read<TeacherExamRepository>();
      await repo.publish(_examId!);
      if (!mounted) return;

      setState(() {
        _status = 'published';
        _isLoading = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 28,
              ),
              SizedBox(width: 10),
              Text('Xuất bản thành công!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đề "${_examNameController.text}" đã được công khai lên hệ thống.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Học sinh có thể bắt đầu làm bài hoặc bạn có thể mở phòng thi ngay.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/teacher_exams');
              },
              child: const Text('Về danh sách đề'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/create_room?examId=$_examId');
              },
              icon: const Icon(Icons.meeting_room_outlined),
              label: const Text('Tạo phòng thi ngay'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage(
          'Lỗi khi xuất bản: ${e.toString().replaceAll('PostgrestException: ', '')}',
          isError: true,
        );
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isConfigured) return _buildSetup();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: Row(
              children: [
                // 1. Left Sidebar (Question Navigation)
                ExamLeftSidebar(
                  questions: _questions,
                  activeIndex: _activeQuestionIndex,
                  onSelect: (idx) => setState(() => _activeQuestionIndex = idx),
                  onAdd: _addQuestion,
                  onDuplicate: _duplicateQuestion,
                  onDelete: _removeQuestion,
                  onReorder: _reorderQuestions,
                  onOpenBulkImport: () {
                    showDialog(
                      context: context,
                      builder: (ctx) =>
                          QuickBulkImportDialog(onImport: _handleBulkImport),
                    );
                  },
                ),
                // 2. Center Workspace (Editor + Bottom Scientific Toolbar)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildCenterEditor()),
                      ScientificBottomToolbar(
                        onInsertSnippet: _insertSnippetAtCursor,
                        onInsertMathBlock: (type) =>
                            _editorController.insertMathBlock(type),
                        onCategoryChanged: (category) {
                          setState(() => _scientificCategory = category);
                        },
                        onShortcutsChanged: (shortcuts) {
                          setState(() => _scientificShortcuts = shortcuts);
                        },
                      ),
                    ],
                  ),
                ),
                // 3. Right Sidebar (Overview & Timer settings)
                ExamRightSidebar(
                  examTitle: _examNameController.text,
                  subject: _selectedSubject ?? '',
                  durationMinutes: int.tryParse(_durationController.text) ?? 45,
                  questionCount: _questions.length,
                  perQuestionTimerEnabled: _perQuestionTimerEnabled,
                  onTogglePerQuestionTimer: (enabled) {
                    setState(() {
                      _perQuestionTimerEnabled = enabled;
                      if (!enabled) {
                        for (var q in _questions) {
                          q.timeLimitSeconds = null;
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          _buildBottomStatusBar(),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back, color: AppTheme.textMain),
            onPressed: () => context.go('/teacher_exams'),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit_document, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _examNameController.text.isEmpty
                        ? 'Soạn đề thi'
                        : _examNameController.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _status == 'published'
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    _status == 'published' ? 'Đã xuất bản' : 'Bản nháp',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _status == 'published'
                          ? AppTheme.success
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => StudentExamPreviewDialog(
                  examTitle: _examNameController.text,
                  subject: _selectedSubject ?? '',
                  durationMinutes: int.tryParse(_durationController.text) ?? 45,
                  questions: _questions,
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Xem trước học sinh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterEditor() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final question = _questions[_activeQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Header & Type Selector
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLavender,
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'CÂU ${_activeQuestionIndex + 1}',
                          style: AppTheme.firaCodeStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Question Type Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<QuestionType>(
                            value: question.type,
                            items: QuestionType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(
                                      t.icon,
                                      size: 18,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newType) {
                              if (newType != null) {
                                setState(() {
                                  question.type = newType;
                                  if (newType == QuestionType.trueFalse) {
                                    question.answers = ['Đúng', 'Sai'];
                                    question.correctAnswers = [0];
                                  } else if (newType ==
                                          QuestionType.shortAnswer &&
                                      question.answers.isEmpty) {
                                    question.answers = [''];
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Points input
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: TextEditingController(
                            text: question.points,
                          ),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Điểm',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.inputRadius,
                              ),
                            ),
                          ),
                          onChanged: (val) => question.points = val,
                        ),
                      ),
                      if (_perQuestionTimerEnabled) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: TextEditingController(
                              text: question.timeLimitSeconds?.toString() ?? '',
                            ),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Giây / câu',
                              suffixText: 's',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.inputRadius,
                                ),
                              ),
                            ),
                            onChanged: (val) =>
                                question.timeLimitSeconds = int.tryParse(val),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Nhân bản',
                        onPressed: () =>
                            _duplicateQuestion(_activeQuestionIndex),
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa câu này',
                        onPressed: () => _removeQuestion(_activeQuestionIndex),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Question Body input
                  const Text(
                    'Nội dung câu hỏi * (hỗ trợ nhập công thức trực quan [ ] hoặc LaTeX):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  InlineVisualMathEditor(
                    key: ValueKey('visual-editor-${question.id}'),
                    initialLatex: question.body,
                    controller: _editorController,
                    shortcutCategory: _scientificCategory,
                    shortcuts:
                        _scientificShortcuts[_scientificCategory] ?? const [],
                    onChanged: (val) {
                      question.body = val;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  // Live Preview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLavender.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardRadius / 2,
                      ),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Xem trước hiển thị trực tiếp (Live Preview):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LatexMathView(
                          text: question.body.isEmpty
                              ? 'Bản xem trước đề bài sẽ xuất hiện tại đây khi bạn gõ.'
                              : question.body,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Answers Section
                  QuestionAnswersEditor(
                    question: question,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 28),
                  // Explanation field
                  const Text(
                    'Lời giải thích chi tiết (hiển thị khi học sinh xem lại bài):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: ValueKey('explanation-${question.id}'),
                    initialValue: question.explanation,
                    maxLines: 3,
                    onChanged: (val) => question.explanation = val,
                    decoration: const InputDecoration(
                      hintText:
                          'Nhập các bước giải, hướng dẫn hoặc kiến thức liên quan...',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Text(
            _lastSavedAt == null
                ? 'Chưa lưu nháp'
                : 'Đã lưu nháp lúc ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _saveDraft,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Lưu bản nháp'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _publishExam,
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text('Lưu & Xuất bản ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetup() => Scaffold(
    backgroundColor: AppTheme.background,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.luminescenceShadow,
            ),
            padding: const EdgeInsets.all(36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLavender,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tạo đề mới',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập thông tin chung một lần. Sau đó bạn chỉ tập trung soạn câu hỏi.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 28),
                TextField(
                  key: const Key('setup-name'),
                  controller: _examNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên đề thi *',
                    hintText: 'Ví dụ: Ôn tập Toán 12 chương 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  key: const Key('setup-subject'),
                  value: _selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Môn học *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Toán', child: Text('Toán')),
                    DropdownMenuItem(value: 'Vật lý', child: Text('Vật lý')),
                    DropdownMenuItem(value: 'Hóa học', child: Text('Hóa học')),
                    DropdownMenuItem(
                      value: 'Tiếng Anh',
                      child: Text('Tiếng Anh'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedSubject = value),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Thời lượng (phút)',
                    suffixText: 'phút',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('setup-continue'),
                    onPressed: _configureExam,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Bắt đầu soạn câu hỏi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
