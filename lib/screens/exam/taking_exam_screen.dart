import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class TakingExamScreen extends StatefulWidget {
  final String? examId;
  final String? attemptId;
  final String? roomId;
  final bool isAuthorPreview;
  const TakingExamScreen({
    super.key,
    this.examId,
    this.attemptId,
    this.roomId,
    this.isAuthorPreview = false,
  });

  @override
  State<TakingExamScreen> createState() => _TakingExamScreenState();
}

class _TakingExamScreenState extends State<TakingExamScreen> {
  bool _isLoading = true;
  bool _isAuthorPreview = false;
  String _examTitle = 'Đang tải bài thi...';
  int _durationMinutes = 45;

  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {}; // questionIndex -> selectedOptionId / label
  final Map<int, bool> _flaggedQuestions = {};

  @override
  void initState() {
    super.initState();
    _isAuthorPreview = widget.isAuthorPreview;
    _loadExamAndQuestions();
  }

  Future<void> _loadExamAndQuestions() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      Map<String, dynamic>? exam;

      if (widget.examId != null && widget.examId!.isNotEmpty) {
        exam = await client
            .from('exams')
            .select('id, title, subject, duration_minutes, teacher_id')
            .eq('id', widget.examId!)
            .maybeSingle();
      }

      // If no specific exam found or provided, pick the first published exam from Supabase
      exam ??= await client
          .from('exams')
          .select('id, title, subject, duration_minutes, teacher_id')
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (exam != null) {
        _examTitle = exam['title'] ?? 'Bài kiểm tra';
        _durationMinutes = exam['duration_minutes'] ?? 45;

        // Auto-detect author preview if user owns this exam
        final user = client.auth.currentUser;
        if (user != null && exam['teacher_id'] != null) {
          try {
            final teacher = await client
                .from('teachers')
                .select('id')
                .eq('owner_user_id', user.id)
                .maybeSingle();
            if (teacher != null && teacher['id'] == exam['teacher_id']) {
              _isAuthorPreview = true;
            }
          } catch (_) {}
        }

        final examIdStr = exam['id'].toString();

        final qRes = await client
            .from('questions')
            .select('id, position, body, explanation, points, question_options(id, position, body, is_correct)')
            .eq('exam_id', examIdStr)
            .order('position', ascending: true);

        final qList = (qRes as List<dynamic>).cast<Map<String, dynamic>>();

        if (qList.isNotEmpty) {
          _questions = qList;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải câu hỏi từ Supabase: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitExam() async {
    if (_questions.isEmpty) return;

    int correctCount = 0;
    int wrongCount = 0;
    int skippedCount = 0;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selectedOptId = _selectedAnswers[i];
      final options = (q['question_options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          (q['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          [];

      if (selectedOptId == null) {
        skippedCount++;
      } else {
        final selectedOpt = options.firstWhere(
          (opt) => opt['id'].toString() == selectedOptId || opt['body'] == selectedOptId,
          orElse: () => {},
        );
        if (selectedOpt['is_correct'] == true) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }
    }

    final double rawScore = (correctCount / _questions.length) * 10.0;
    final double finalScore = double.parse(rawScore.toStringAsFixed(1));

    // Save attempt to Supabase
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      
      await client.from('attempts').insert({
        'exam_id': widget.examId ?? (_questions.isNotEmpty ? _questions.first['exam_id'] : null),
        'user_id': user?.id,
        'guest_name': user == null ? 'Học sinh' : null,
        'status': 'submitted',
        'started_at': DateTime.now().subtract(Duration(minutes: _durationMinutes)).toIso8601String(),
        'submitted_at': DateTime.now().toIso8601String(),
        'score': finalScore,
        'is_author_preview': _isAuthorPreview,
      });
    } catch (e) {
      debugPrint('Lỗi lưu bài làm lên Supabase: $e');
    }

    if (mounted) {
      context.go(
        '/result?score=$finalScore&total=${_questions.length}&correct=$correctCount&wrong=$wrongCount&skipped=$skippedCount&title=${Uri.encodeComponent(_examTitle)}',
      );
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thoát'),
        content: const Text('Bạn có chắc muốn thoát? Kết quả bài thi sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Ở lại', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu bài thi từ Supabase...'),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildMinimalAppBar(),
        body: Column(
          children: [
            if (_isAuthorPreview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                color: const Color(0xFFFEF3C7),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_outlined, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Chế độ xem trước của tác giả (không tính vào Bảng xếp hạng công khai)',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _buildQuestionArea(),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _buildSidebarNavigator(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMinimalAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.edit_square, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(_examTitle, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$_durationMinutes:00', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              context.pop();
            }
          },
          icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
          label: const Text('Thoát', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.border, height: 1),
      ),
    );
  }

  Widget _buildQuestionArea() {
    if (_questions.isEmpty) {
      return const Center(
        child: Text('Bài thi hiện chưa có câu hỏi trong cơ sở dữ liệu.'),
      );
    }

    final q = _questions[_currentQuestionIndex];
    final qBody = q['body']?.toString() ?? '';
    final options = (q['question_options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        (q['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    options.sort((a, b) => (a['position'] as int? ?? 0).compareTo(b['position'] as int? ?? 0));

    final isFlagged = _flaggedQuestions[_currentQuestionIndex] == true;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Câu hỏi ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _flaggedQuestions[_currentQuestionIndex] = !isFlagged;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      isFlagged ? Icons.flag : Icons.flag_outlined,
                      size: 18,
                      color: isFlagged ? AppTheme.warning : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFlagged ? 'Đã đánh dấu' : 'Đánh dấu xem lại',
                      style: TextStyle(
                        color: isFlagged ? AppTheme.warning : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: isFlagged ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            qBody,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 4,
              children: List.generate(options.length, (optIdx) {
                final opt = options[optIdx];
                final optId = opt['id']?.toString() ?? opt['body']?.toString() ?? optIdx.toString();
                final optLetter = String.fromCharCode(65 + optIdx);
                final optBody = opt['body']?.toString() ?? '';

                return _buildOptionTile(optId, optLetter, optBody);
              }),
            ),
          ),
          
          const Divider(height: 32, color: AppTheme.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _currentQuestionIndex > 0
                    ? () => setState(() => _currentQuestionIndex--)
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Câu trước'),
              ),
              ElevatedButton.icon(
                onPressed: _currentQuestionIndex < _questions.length - 1
                    ? () => setState(() => _currentQuestionIndex++)
                    : _submitExam,
                icon: Icon(_currentQuestionIndex < _questions.length - 1 ? Icons.chevron_right : Icons.send),
                label: Text(_currentQuestionIndex < _questions.length - 1 ? 'Câu sau' : 'Nộp bài'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentQuestionIndex < _questions.length - 1 ? null : AppTheme.success,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String optId, String letter, String text) {
    final isSelected = _selectedAnswers[_currentQuestionIndex] == optId;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAnswers[_currentQuestionIndex] = optId;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border, width: 2),
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: isSelected ? const Icon(Icons.circle, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text(
              '$letter.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarNavigator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh sách câu hỏi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isCurrent = index == _currentQuestionIndex;
                final isAnswered = _selectedAnswers.containsKey(index);
                final isFlagged = _flaggedQuestions[index] == true;

                Color bgColor = Colors.white;
                Color textColor = AppTheme.textMain;
                Border border = Border.all(color: AppTheme.border);

                if (isCurrent) {
                  bgColor = AppTheme.primary;
                  textColor = Colors.white;
                  border = Border.all(color: AppTheme.primary, width: 2);
                } else if (isAnswered) {
                  bgColor = const Color(0xFFF0ECFF);
                  textColor = AppTheme.primary;
                  border = Border.all(color: AppTheme.primaryLight);
                }

                return InkWell(
                  onTap: () => setState(() => _currentQuestionIndex = index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: border,
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                        if (isFlagged)
                          const Positioned(
                            top: 2,
                            right: 2,
                            child: Icon(Icons.flag, size: 10, color: AppTheme.warning),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitExam,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              child: const Text('Nộp bài thi'),
            ),
          ),
        ],
      ),
    );
  }
}
