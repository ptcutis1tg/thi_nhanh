import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/teacher_exam_repository.dart';
import '../../core/theme/app_theme.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key, this.examId});

  final String? examId;

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _QuestionDraft {
  _QuestionDraft({required this.id}) : answers = List.filled(4, '');

  final String id;
  String body = '';
  List<String> answers;
  int correctAnswer = 0;
  String difficulty = 'medium';
  String points = '1';

  factory _QuestionDraft.fromJson(Map<String, dynamic> question) {
    final draft = _QuestionDraft(id: question['id'] as String)
      ..body = question['body'] as String
      ..answers = List<String>.from(question['answers'] as List<dynamic>)
      ..correctAnswer = (question['correctAnswer'] as num).toInt()
      ..points = '${question['points']}';
    return draft;
  }

  Map<String, dynamic> toJson() => {'body': body, 'answers': answers, 'correctAnswer': correctAnswer, 'points': points};
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _examNameController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  String? _selectedSubject;
  bool _isConfigured = false;
  bool _isLoading = false;
  String? _examId;
  String _status = 'draft';
  int _activeQuestionIndex = 0;
  DateTime? _lastSavedAt;
  final List<_QuestionDraft> _questions = [];

  @override
  void initState() {
    super.initState();
    _examId = widget.examId;
    if (_examId != null) _loadExistingExam();
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
        _questions
          ..clear()
          ..addAll((exam['questions'] as List<dynamic>).map((item) => _QuestionDraft.fromJson(Map<String, dynamic>.from(item as Map))));
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
    _questions.add(_QuestionDraft(id: DateTime.now().microsecondsSinceEpoch.toString()));
    _activeQuestionIndex = _questions.length - 1;
  }

  void _removeQuestion() {
    if (_questions.length == 1) {
      _showMessage('Đề cần có ít nhất một câu hỏi.', isError: true);
      return;
    }
    setState(() {
      _questions.removeAt(_activeQuestionIndex);
      _activeQuestionIndex = _activeQuestionIndex.clamp(0, _questions.length - 1);
    });
  }

  Future<bool> _saveDraft() async {
    if (!_isConfigured) return false;
    setState(() => _isLoading = true);
    try {
      final savedId = await context.read<TeacherExamRepository>().saveDraft(
        examId: _examId,
        title: _examNameController.text.trim(),
        subject: _selectedSubject ?? '',
        durationMinutes: int.tryParse(_durationController.text) ?? 45,
        questions: _questions.map((question) => question.toJson()).toList(),
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
        _showMessage('Lỗi khi lưu đề: ${e.toString().replaceAll('PostgrestException: ', '')}', isError: true);
      }
      return false;
    }
  }

  Future<void> _createExam() async {
    final invalidQuestion = _questions.indexWhere((question) =>
        question.body.trim().isEmpty || question.answers.any((answer) => answer.trim().isEmpty));
    if (invalidQuestion >= 0) {
      setState(() => _activeQuestionIndex = invalidQuestion);
      _showMessage('Hãy nhập nội dung và đủ đáp án cho Câu ${invalidQuestion + 1}.', isError: true);
      return;
    }
    final success = await _saveDraft();
    if (success && mounted) {
      context.go('/teacher_exams');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_isConfigured) return _buildSetup();
    return Scaffold(body: Row(children: [_buildSidebar(), Expanded(child: _buildEditor())]));
  }

  Widget _buildSetup() => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 36),
                    const SizedBox(height: 16),
                    Text('Tạo đề mới', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Nhập thông tin chung một lần. Sau đó bạn chỉ tập trung soạn câu hỏi.', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 28),
                    TextField(key: const Key('setup-name'), controller: _examNameController, decoration: const InputDecoration(labelText: 'Tên đề thi *', hintText: 'Ví dụ: Ôn tập Toán 12 chương 1')),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      key: const Key('setup-subject'),
                      value: _selectedSubject,
                      decoration: const InputDecoration(labelText: 'Môn học *'),
                      items: const [
                        DropdownMenuItem(value: 'Toán', child: Text('Toán')),
                        DropdownMenuItem(value: 'Vật lý', child: Text('Vật lý')),
                        DropdownMenuItem(value: 'Hóa học', child: Text('Hóa học')),
                        DropdownMenuItem(value: 'Tiếng Anh', child: Text('Tiếng Anh')),
                      ],
                      onChanged: (value) => setState(() => _selectedSubject = value),
                    ),
                    const SizedBox(height: 18),
                    TextField(controller: _durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Thời lượng (phút)', suffixText: 'phút')),
                    const SizedBox(height: 28),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(key: const Key('setup-continue'), onPressed: _configureExam, icon: const Icon(Icons.arrow_forward), label: const Text('Bắt đầu soạn câu hỏi'))),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildSidebar() => Container(
        width: 256,
        decoration: const BoxDecoration(color: AppTheme.surface, border: Border(right: BorderSide(color: AppTheme.border))),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(16), width: double.infinity, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))), child: const Text('DANH SÁCH CÂU HỎI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.2))),
          Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _questions.length, itemBuilder: (_, index) => _questionListItem(index))),
          Padding(padding: const EdgeInsets.all(16), child: OutlinedButton.icon(key: const Key('add-question'), onPressed: () => setState(_addQuestion), icon: const Icon(Icons.add), label: const Text('Thêm câu hỏi'), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)))),
        ]),
      );

  Widget _questionListItem(int index) {
    final question = _questions[index];
    final active = index == _activeQuestionIndex;
    final title = question.body.trim().isEmpty ? 'Câu hỏi số ${index + 1}' : question.body.trim();
    return InkWell(
      key: Key('question-list-$index'),
      onTap: () => setState(() => _activeQuestionIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: active ? AppTheme.primary.withValues(alpha: .10) : AppTheme.surface, border: Border.all(color: active ? AppTheme.primaryLight : Colors.transparent), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: active ? AppTheme.primary : AppTheme.border, child: Text('${index + 1}', style: TextStyle(color: active ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? AppTheme.primary : AppTheme.textMain)), const Text('Trắc nghiệm', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))])),
        ]),
      ),
    );
  }

  Widget _buildEditor() {
    final question = _questions[_activeQuestionIndex];
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(32).copyWith(bottom: 100),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: Card(child: Padding(padding: const EdgeInsets.all(32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.description_outlined, color: AppTheme.primary), const SizedBox(width: 10), Expanded(child: Text('${_examNameController.text} • $_selectedSubject • ${_durationController.text} phút', style: const TextStyle(fontWeight: FontWeight.w600))),])),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CÂU ${_activeQuestionIndex + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Chỉnh sửa nội dung', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]), IconButton(onPressed: _removeQuestion, icon: const Icon(Icons.delete_outline))]),
            const Divider(height: 42),
            const Text('Nội dung câu hỏi *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextFormField(key: ValueKey('question-${question.id}'), initialValue: question.body, maxLines: 4, onChanged: (value) => setState(() => question.body = value), decoration: const InputDecoration(hintText: 'Nhập nội dung câu hỏi tại đây...')),
            const SizedBox(height: 28),
            const Text('Các đáp án (chọn 1 đáp án đúng)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...List.generate(question.answers.length, (index) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _answerField(question, index))),
            if (question.answers.length < 8) TextButton.icon(onPressed: () => setState(() => question.answers.add('')), icon: const Icon(Icons.add_circle_outline), label: const Text('Thêm lựa chọn')),
          ]))))),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.border))), child: Row(children: [Expanded(child: Text(_lastSavedAt == null ? 'Chưa lưu nháp' : 'Đã lưu nháp lúc ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))), OutlinedButton(onPressed: _saveDraft, child: const Text('Lưu nháp')), const SizedBox(width: 12), ElevatedButton.icon(onPressed: _createExam, icon: const Icon(Icons.check), label: const Text('Lưu & Khởi tạo đề'))]))),
      ]),
    );
  }

  Widget _answerField(_QuestionDraft question, int index) => Row(children: [
        Radio<int>(value: index, groupValue: question.correctAnswer, onChanged: (value) => setState(() => question.correctAnswer = value!)),
        Expanded(child: TextFormField(key: ValueKey('answer-${question.id}-$index'), initialValue: question.answers[index], onChanged: (value) => question.answers[index] = value, decoration: InputDecoration(labelText: '${String.fromCharCode(65 + index)}. Đáp án *'))),
        IconButton(onPressed: question.answers.length <= 2 ? null : () => setState(() { question.answers.removeAt(index); if (question.correctAnswer >= question.answers.length) question.correctAnswer = 0; }), icon: const Icon(Icons.close)),
      ]);
}
