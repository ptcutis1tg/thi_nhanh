import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/assessment.dart';
import '../../core/repositories/assessment_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/exam_shuffle_helper.dart';

class TakingExamScreen extends StatefulWidget {
  final String? examId;
  final String? attemptId;
  final String? roomId;
  final bool isAuthorPreview;
  final bool enableAntiCheat;
  final bool shuffleQuestions;
  final List<Map<String, dynamic>>? initialQuestions;
  final Future<void> Function(Map<String, dynamic> attemptPayload)?
  onSubmitAttempt;

  const TakingExamScreen({
    super.key,
    this.examId,
    this.attemptId,
    this.roomId,
    this.isAuthorPreview = false,
    this.enableAntiCheat = true,
    this.shuffleQuestions = true,
    this.initialQuestions,
    this.onSubmitAttempt,
  });

  @override
  State<TakingExamScreen> createState() => _TakingExamScreenState();
}

class _TakingExamScreenState extends State<TakingExamScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  bool _isAuthorPreview = false;
  String? _resolvedExamId;
  String _examTitle = 'Đang tải bài thi...';
  int _durationMinutes = 45;
  int _remainingSeconds = 45 * 60;
  Timer? _timer;

  int _violationCount = 0;
  bool _isShowingViolationDialog = false;

  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers =
      {}; // questionIndex -> selectedOptionId / label
  final Map<int, bool> _flaggedQuestions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isAuthorPreview = widget.isAuthorPreview;
    _resolvedExamId = widget.examId;
    if (widget.initialQuestions != null) {
      _questions = List.of(widget.initialQuestions!);
      if (_resolvedExamId == null && _questions.isNotEmpty) {
        _resolvedExamId = _questions.first['exam_id']?.toString();
      }
      _maybeShuffleQuestions();
      _isLoading = false;
    } else {
      _loadExamAndQuestions();
    }
  }

  void _maybeShuffleQuestions() {
    if (widget.shuffleQuestions && _questions.isNotEmpty) {
      final seed = (widget.attemptId ?? widget.roomId ?? widget.examId ?? 'anti_cheat_seed').hashCode;
      _questions = ExamShuffleHelper.shuffleQuestionsAndOptions(
        _questions,
        seed: seed,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!widget.enableAntiCheat || _isAuthorPreview || _hasSubmitted || _isLoading) {
      return;
    }

    final isLeaving = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden;

    if (isLeaving && !_isShowingViolationDialog) {
      _handleViolation();
    }
  }

  void _handleViolation() {
    if (!mounted || _hasSubmitted) return;

    _violationCount++;

    if (_violationCount <= 3) {
      _isShowingViolationDialog = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.error, width: 2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'CẢNH BÁO VI PHẠM',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phát hiện bạn vừa rời khỏi màn hình bài thi hoặc chuyển tab!',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Lần vi phạm: $_violationCount/3',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quy chế phòng thi: Nếu vi phạm quá 3 lần, bài thi sẽ bị hệ thống tự động thu hồi và nộp bài ngay lập tức!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  _isShowingViolationDialog = false;
                  Navigator.of(ctx).pop();
                },
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Tôi đã hiểu & Quay lại làm bài'),
                ),
              ),
            ),
          ],
        ),
      ).then((_) {
        _isShowingViolationDialog = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⛔ BÀI THI ĐÃ BỊ THU HỒI DO VI PHẠM QUÁ 3 LẦN!'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 5),
        ),
      );
      _submitExam();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingSeconds <= 0) {
      Future<void>.microtask(_submitExam);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _hasSubmitted) {
        timer.cancel();
      } else if (_remainingSeconds <= 1) {
        setState(() => _remainingSeconds = 0);
        timer.cancel();
        _submitExam();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String get _remainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadExamAndQuestions() async {
    setState(() => _isLoading = true);
    try {
      if (widget.attemptId != null && widget.attemptId!.isNotEmpty) {
        final attempt = await context.read<AssessmentRepository>().loadAttempt(
          widget.attemptId!,
        );
        _applyAttempt(attempt);
        return;
      }

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
        _resolvedExamId = exam['id']?.toString();
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
            .select(
              'id, exam_id, position, body, explanation, points, question_options(id, position, body, is_correct)',
            )
            .eq('exam_id', examIdStr)
            .order('position', ascending: true);

        final qList = (qRes as List<dynamic>).cast<Map<String, dynamic>>();

        if (qList.isNotEmpty) {
          _questions = qList;
          _maybeShuffleQuestions();
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải câu hỏi từ Supabase: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.attemptId == null || widget.attemptId!.isEmpty) {
          _startTimer();
        }
      }
    }
  }

  void _applyAttempt(AttemptPayload attempt) {
    _examTitle = attempt.title;
    _durationMinutes = attempt.durationMinutes;
    _remainingSeconds = attempt.expiresAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 24 * 60 * 60);
    _isAuthorPreview = attempt.isAuthorPreview;
    _questions = attempt.questions
        .map(
          (question) => <String, dynamic>{
            'id': question.id,
            'position': question.position,
            'body': question.body,
            'points': question.points,
            'options': question.options
                .map(
                  (option) => <String, dynamic>{
                    'id': option.id,
                    'position': option.position,
                    'body': option.body,
                  },
                )
                .toList(),
          },
        )
        .toList();
    _maybeShuffleQuestions();
    _selectedAnswers.clear();
    for (var index = 0; index < _questions.length; index++) {
      final selected = attempt.answers[_questions[index]['id'] as String];
      if (selected != null) _selectedAnswers[index] = selected;
    }
    _hasSubmitted = attempt.status == 'submitted';
    if (mounted) setState(() => _isLoading = false);

    if (_hasSubmitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAlreadySubmittedDialog(attempt.attemptId);
      });
      return;
    }

    if (attempt.isExpired || _remainingSeconds <= 0) {
      _remainingSeconds = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showExpiredAttemptDialog(attempt);
      });
      return;
    }

    if (attempt.isOpen) _startTimer();
  }

  Future<void> _showExpiredAttemptDialog(AttemptPayload attempt) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_filled_rounded,
                color: Color(0xFFD97706),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bài thi đã hết thời gian',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời gian làm bài cho đề thi này đã kết thúc trước đó. Bạn có thể nộp các câu đã làm để hệ thống chấm điểm hoặc quay lại danh sách bài thi.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Đã làm: ${_selectedAnswers.length}/${_questions.length} câu',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                context.go('/student/history?tab=in_progress');
              }
            },
            child: const Text('Quay về Lịch sử'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Nộp bài chấm điểm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlreadySubmittedDialog(String attemptId) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Bài thi đã nộp'),
        content: const Text(
          'Bài thi này đã được hoàn thành và nộp trước đó. Bạn có thể chuyển sang xem kết quả làm bài.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/student/history');
            },
            child: const Text('Về Lịch sử'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final resolvedRoomId = widget.roomId;
              context.go(
                '/result?attemptId=${Uri.encodeComponent(attemptId)}'
                '${resolvedRoomId == null ? '' : '&roomId=${Uri.encodeComponent(resolvedRoomId)}'}',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xem kết quả'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePressSubmit() async {
    if (_questions.isEmpty || _isSubmitting || _hasSubmitted) return;

    final answeredCount = _selectedAnswers.length;
    final totalCount = _questions.length;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                color: AppTheme.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Xác nhận nộp bài thi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đã làm $answeredCount / $totalCount câu hỏi.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (answeredCount < totalCount) ...[
                Text(
                  'Còn ${totalCount - answeredCount} câu chưa chọn đáp án. Bạn có chắc chắn muốn nộp bài ngay bây giờ?',
                  style: const TextStyle(fontSize: 13, color: AppTheme.warning),
                ),
              ] else ...[
                const Text(
                  'Bạn đã hoàn thành tất cả câu hỏi. Bạn có chắc chắn muốn kết thúc bài thi và xem kết quả?',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text(
                'Làm tiếp',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      Navigator.of(context).pop(true);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Nộp bài ngay'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await _submitExam();
    }
  }

  Future<void> _submitExam() async {
    if (_questions.isEmpty || _isSubmitting || _hasSubmitted) return;

    setState(() => _isSubmitting = true);

    if (widget.attemptId != null &&
        widget.attemptId!.isNotEmpty &&
        widget.onSubmitAttempt == null) {
      try {
        final result = await context.read<AssessmentRepository>().submit(
          widget.attemptId!,
        );
        _timer?.cancel();
        _hasSubmitted = true;
        if (mounted) {
          setState(() => _isSubmitting = false);
          final resolvedRoomId = result.roomId ?? widget.roomId;
          context.go(
            '/result?attemptId=${Uri.encodeComponent(result.attemptId)}'
            '${resolvedRoomId == null ? '' : '&roomId=${Uri.encodeComponent(resolvedRoomId)}'}',
          );
        }
      } catch (e) {
        _showSubmitError(e);
      }
      return;
    }

    // Compatibility path for author previews and injected widget tests. Real
    // attempts are always scored by the submit_attempt RPC above.
    int correctCount = 0;
    int wrongCount = 0;
    int skippedCount = 0;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selectedOptId = _selectedAnswers[i];
      final options =
          (q['question_options'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          (q['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          [];

      if (selectedOptId == null) {
        skippedCount++;
      } else {
        final selectedOpt = options.firstWhere(
          (opt) =>
              opt['id'].toString() == selectedOptId ||
              opt['body'] == selectedOptId,
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

    final resolvedExamId = _resolvedExamId ??
        widget.examId ??
        (_questions.isNotEmpty ? _questions.first['exam_id']?.toString() : null);

    final payload = <String, dynamic>{
      if (resolvedExamId != null && resolvedExamId.isNotEmpty)
        'exam_id': resolvedExamId,
      'status': 'submitted',
      'started_at': DateTime.now()
          .subtract(Duration(minutes: _durationMinutes))
          .toIso8601String(),
      'submitted_at': DateTime.now().toIso8601String(),
      'score': finalScore,
      'violations': _violationCount,
      'is_author_preview': _isAuthorPreview,
    };

    // Save attempt to Supabase with local resilient fallback
    bool savedToCloud = false;
    try {
      if (widget.onSubmitAttempt != null) {
        await widget.onSubmitAttempt!(payload);
        savedToCloud = true;
      } else {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;

        payload['user_id'] = user?.id;
        if (user == null) {
          payload['guest_name'] = 'Học sinh';
        }

        if (widget.attemptId != null && widget.attemptId!.isNotEmpty) {
          await client
              .from('attempts')
              .update({
                'status': 'submitted',
                'score': finalScore,
                'submitted_at': DateTime.now().toIso8601String(),
                'violations': _violationCount,
              })
              .eq('id', widget.attemptId!);
          savedToCloud = true;
        } else if (resolvedExamId != null && resolvedExamId.isNotEmpty) {
          await client.from('attempts').insert(payload);
          savedToCloud = true;
        } else {
          debugPrint('Không có exam_id hợp lệ để lưu lên Supabase, kích hoạt lưu cục bộ.');
        }
      }
    } catch (e) {
      debugPrint('Lỗi lưu bài làm lên Supabase, kích hoạt lưu cục bộ: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        final localAttempts = prefs.getStringList('local_exam_attempts') ?? [];
        final localRecord = jsonEncode({
          'exam_id': payload['exam_id'],
          'title': _examTitle,
          'score': finalScore,
          'correct': correctCount,
          'total': _questions.length,
          'submitted_at': payload['submitted_at'],
        });
        localAttempts.add(localRecord);
        await prefs.setStringList('local_exam_attempts', localAttempts);
      } catch (errStorage) {
        debugPrint('Lỗi lưu bộ nhớ đệm: $errStorage');
      }
    }

    _hasSubmitted = true;

    if (mounted) {
      setState(() => _isSubmitting = false);
      try {
        context.go(
          '/result?score=$finalScore&total=${_questions.length}&correct=$correctCount&wrong=$wrongCount&skipped=$skippedCount&title=${Uri.encodeComponent(_examTitle)}&offlineSaved=${!savedToCloud}',
        );
      } catch (_) {
        // Bỏ qua lỗi điều hướng nếu môi trường kiểm thử không cấu hình GoRouter
      }
    }
  }

  void _showSubmitError(Object error) {
    debugPrint('Lỗi nộp bài thi: $error');
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final errorStr = error.toString().toLowerCase();
    final isClosedOrExpired = errorStr.contains('closed') ||
        errorStr.contains('expired') ||
        errorStr.contains('hết hạn') ||
        errorStr.contains('đã đóng') ||
        errorStr.contains('submitted');

    if (isClosedOrExpired) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Bài thi đã kết thúc'),
          content: const Text(
            'Bài thi này đã được hệ thống ghi nhận kết thúc hoặc đã quá hạn làm bài.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/student/history?tab=in_progress');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Về danh sách bài thi'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Không thể nộp bài: $error'),
        backgroundColor: AppTheme.error,
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: _handlePressSubmit,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thoát'),
        content: const Text(
          'Bạn có chắc muốn thoát? Kết quả bài thi sẽ không được lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(
              'Ở lại',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return Column(
              children: [
                if (_isAuthorPreview)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    color: const Color(0xFFFEF3C7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Chế độ xem trước của tác giả (không tính vào Bảng xếp hạng công khai)',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isMobile && _questions.isNotEmpty)
                  _buildMobileQuestionQuickStrip(),

                Expanded(
                  child: isMobile
                      ? _buildMobileQuestionView()
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: _buildQuestionArea(isMobile: false),
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

                if (isMobile && _questions.isNotEmpty)
                  _buildMobileBottomActionBar(),
              ],
            );
          },
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
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Thoát bài thi',
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                context.pop();
              }
            },
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit_square, color: AppTheme.primary, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _examTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              Text(
                _remainingTime,
                style: AppTheme.firaCodeStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.border, height: 1),
      ),
    );
  }

  Widget _buildMobileQuestionQuickStrip() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _questions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final isCurrent = index == _currentQuestionIndex;
                final isAnswered = _selectedAnswers.containsKey(index);
                final isFlagged = _flaggedQuestions[index] == true;

                Color bgColor = Colors.white;
                Color textColor = AppTheme.textMain;
                Border border = Border.all(color: AppTheme.border);

                if (isCurrent) {
                  bgColor = AppTheme.surfaceLavender;
                  textColor = AppTheme.primary;
                  border = Border.all(color: AppTheme.primary, width: 2);
                } else if (isAnswered) {
                  bgColor = AppTheme.primary;
                  textColor = Colors.white;
                  border = Border.all(color: AppTheme.primaryDark);
                }

                return InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _currentQuestionIndex = index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                        if (isFlagged)
                          Positioned(
                            top: 1,
                            right: 1,
                            child: Icon(
                              Icons.flag,
                              size: 10,
                              color: isAnswered ? Colors.amberAccent : AppTheme.warning,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Container(
            height: 28,
            width: 1,
            color: AppTheme.border,
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: AppTheme.primary, size: 22),
            tooltip: 'Xem ma trận câu hỏi',
            onPressed: () => _showQuestionGridBottomSheet(context),
          ),
        ],
      ),
    );
  }

  void _showQuestionGridBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final answeredCount = _selectedAnswers.length;
            final totalCount = _questions.length;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Danh sách câu hỏi',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLavender,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '$answeredCount / $totalCount câu',
                            style: AppTheme.firaCodeStyle.copyWith(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _buildLegendItem(AppTheme.primary, 'Đã làm', isFilled: true),
                        _buildLegendItem(AppTheme.surfaceLavender, 'Đang làm', isOutline: true),
                        _buildLegendItem(AppTheme.border, 'Chưa làm'),
                        _buildLegendItem(AppTheme.warning, 'Cờ xem lại', isFlag: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.1,
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
                            bgColor = AppTheme.surfaceLavender;
                            textColor = AppTheme.primary;
                            border = Border.all(color: AppTheme.primary, width: 2);
                          } else if (isAnswered) {
                            bgColor = AppTheme.primary;
                            textColor = Colors.white;
                            border = Border.all(color: AppTheme.primaryDark);
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => _currentQuestionIndex = index);
                            },
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  if (isFlagged)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Icon(
                                        Icons.flag,
                                        size: 10,
                                        color: isAnswered ? Colors.amberAccent : AppTheme.warning,
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isFilled = false, bool isOutline = false, bool isFlag = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFlag)
          const Icon(Icons.flag, size: 14, color: AppTheme.warning)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isFilled ? color : (isOutline ? color : Colors.white),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: isOutline ? AppTheme.primary : color),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMobileQuestionView() {
    if (_questions.isEmpty) {
      return const Center(
        child: Text('Bài thi hiện chưa có câu hỏi trong cơ sở dữ liệu.'),
      );
    }

    final q = _questions[_currentQuestionIndex];
    final qBody = q['body']?.toString() ?? '';
    final options =
        (q['question_options'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        (q['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    if (!widget.shuffleQuestions) {
      options.sort(
        (a, b) =>
            (a['position'] as int? ?? 0).compareTo(b['position'] as int? ?? 0),
      );
    }

    final isFlagged = _flaggedQuestions[_currentQuestionIndex] == true;

    return SelectionContainer.disabled(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Câu ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _flaggedQuestions[_currentQuestionIndex] = !isFlagged;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFlagged ? Icons.flag : Icons.flag_outlined,
                            size: 18,
                            color: isFlagged ? AppTheme.warning : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFlagged ? 'Đã ghim cờ' : 'Ghim cờ',
                            style: TextStyle(
                              color: isFlagged ? AppTheme.warning : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isFlagged ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                qBody,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 20),
              Column(
                children: List.generate(options.length, (optIdx) {
                  final opt = options[optIdx];
                  final optId =
                      opt['id']?.toString() ??
                      opt['body']?.toString() ??
                      optIdx.toString();
                  final optLetter = String.fromCharCode(65 + optIdx);
                  final optBody = opt['body']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOptionTile(optId, optLetter, optBody),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomActionBar() {
    final isFirstQuestion = _currentQuestionIndex == 0;
    final isLastQuestion = _currentQuestionIndex >= _questions.length - 1;
    final isFlagged = _flaggedQuestions[_currentQuestionIndex] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: !isFirstQuestion && !_isSubmitting
                  ? () => setState(() => _currentQuestionIndex--)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              label: const Text('Câu trước', maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isFlagged ? 'Bỏ cờ' : 'Đánh dấu cờ',
            icon: Icon(
              isFlagged ? Icons.flag_rounded : Icons.flag_outlined,
              color: isFlagged ? AppTheme.warning : AppTheme.textSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isFlagged
                  ? AppTheme.warning.withValues(alpha: 0.1)
                  : AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isFlagged ? AppTheme.warning : AppTheme.border,
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                _flaggedQuestions[_currentQuestionIndex] = !isFlagged;
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: (_isSubmitting || _hasSubmitted)
                  ? null
                  : (!isLastQuestion
                      ? () => setState(() => _currentQuestionIndex++)
                      : _handlePressSubmit),
              icon: _isSubmitting && isLastQuestion
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      !isLastQuestion
                          ? Icons.chevron_right_rounded
                          : (_hasSubmitted ? Icons.check_circle_outline : Icons.send_rounded),
                      size: 20,
                    ),
              label: Text(
                _isSubmitting && isLastQuestion
                    ? 'Đang nộp...'
                    : (_hasSubmitted && isLastQuestion
                        ? 'Đã nộp'
                        : (!isLastQuestion ? 'Câu sau' : 'Nộp bài')),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: !isLastQuestion
                    ? AppTheme.primary
                    : (_hasSubmitted ? AppTheme.textSecondary : AppTheme.success),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea({bool isMobile = false}) {
    if (_questions.isEmpty) {
      return const Center(
        child: Text('Bài thi hiện chưa có câu hỏi trong cơ sở dữ liệu.'),
      );
    }

    final q = _questions[_currentQuestionIndex];
    final qBody = q['body']?.toString() ?? '';
    final options =
        (q['question_options'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        (q['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    if (!widget.shuffleQuestions) {
      options.sort(
        (a, b) =>
            (a['position'] as int? ?? 0).compareTo(b['position'] as int? ?? 0),
      );
    }

    final isFlagged = _flaggedQuestions[_currentQuestionIndex] == true;
    final isLastQuestion = _currentQuestionIndex >= _questions.length - 1;

    return SelectionContainer.disabled(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Câu hỏi ${_currentQuestionIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _flaggedQuestions[_currentQuestionIndex] = !isFlagged;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFlagged ? Icons.flag : Icons.flag_outlined,
                        size: 18,
                        color: isFlagged
                            ? AppTheme.warning
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFlagged ? 'Đã đánh dấu' : 'Đánh dấu xem lại',
                        style: TextStyle(
                          color: isFlagged
                              ? AppTheme.warning
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isFlagged
                              ? FontWeight.bold
                              : FontWeight.normal,
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
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 4,
                children: List.generate(options.length, (optIdx) {
                  final opt = options[optIdx];
                  final optId =
                      opt['id']?.toString() ??
                      opt['body']?.toString() ??
                      optIdx.toString();
                  final optLetter = String.fromCharCode(65 + optIdx);
                  final optBody = opt['body']?.toString() ?? '';

                  return _buildOptionTile(optId, optLetter, optBody);
                }),
              ),
            ),

            const Divider(height: 32, color: AppTheme.border),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _currentQuestionIndex > 0 && !_isSubmitting
                    ? () => setState(() => _currentQuestionIndex--)
                    : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Câu trước'),
                ),
                ElevatedButton.icon(
                  onPressed: (_isSubmitting || _hasSubmitted)
                      ? null
                      : (!isLastQuestion
                            ? () => setState(() => _currentQuestionIndex++)
                            : _handlePressSubmit),
                  icon: _isSubmitting && isLastQuestion
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          !isLastQuestion
                              ? Icons.chevron_right
                              : (_hasSubmitted
                                    ? Icons.check_circle_outline
                                    : Icons.send),
                        ),
                  label: Text(
                    _isSubmitting && isLastQuestion
                        ? 'Đang nộp bài...'
                        : (_hasSubmitted && isLastQuestion
                              ? 'Đã nộp bài'
                              : (!isLastQuestion ? 'Câu sau' : 'Nộp bài')),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isLastQuestion
                        ? null
                        : (_hasSubmitted
                              ? AppTheme.textSecondary
                              : AppTheme.success),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String optId, String letter, String text) {
    final isSelected = _selectedAnswers[_currentQuestionIndex] == optId;

    return InkWell(
      onTap: _isSubmitting
          ? null
          : () async {
              final questionIndex = _currentQuestionIndex;
              final previous = _selectedAnswers[questionIndex];
              setState(() {
                _selectedAnswers[questionIndex] = optId;
              });
              if (widget.attemptId != null && widget.attemptId!.isNotEmpty) {
                try {
                  await context.read<AssessmentRepository>().saveAnswer(
                    attemptId: widget.attemptId!,
                    questionId: _questions[questionIndex]['id'].toString(),
                    optionId: optId,
                  );
                } catch (e) {
                  if (!mounted) return;
                  setState(() {
                    if (previous == null) {
                      _selectedAnswers.remove(questionIndex);
                    } else {
                      _selectedAnswers[questionIndex] = previous;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không lưu được đáp án: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.circle, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '$letter.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
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
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Danh sách câu hỏi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_selectedAnswers.length}/${_questions.length}',
                style: AppTheme.firaCodeStyle.copyWith(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
                  bgColor = AppTheme.surfaceLavender;
                  textColor = AppTheme.primary;
                  border = Border.all(color: AppTheme.primary, width: 2);
                } else if (isAnswered) {
                  bgColor = AppTheme.primary;
                  textColor = Colors.white;
                  border = Border.all(color: AppTheme.primaryDark);
                }

                return InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _currentQuestionIndex = index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: border,
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                        if (isFlagged)
                          const Positioned(
                            top: 2,
                            right: 2,
                            child: Icon(
                              Icons.flag,
                              size: 10,
                              color: AppTheme.warning,
                            ),
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
              onPressed: (_isSubmitting || _hasSubmitted)
                  ? null
                  : _handlePressSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasSubmitted
                    ? AppTheme.textSecondary
                    : AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đang nộp bài...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      _hasSubmitted ? 'Đã nộp bài' : 'Nộp bài thi',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


