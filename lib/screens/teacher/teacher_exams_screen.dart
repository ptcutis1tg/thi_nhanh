import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/repositories/teacher_exam_repository.dart';
import '../../core/repositories/saved_exam_repository.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/publish_confirm_dialog.dart';
import 'widgets/delete_draft_confirm_dialog.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen> {
  bool _isLoading = true;
  List<TeacherExamSummary> _exams = [];
  List<TeacherExamSummary> _savedExams = [];
  String _searchQuery = '';
  String _selectedSubject = 'Tất cả môn';
  String _activeTab = 'all'; // 'all' | 'draft' | 'published' | 'saved'

  final List<String> _subjects = const [
    'Tất cả môn',
    'Toán',
    'Vật lý',
    'Hóa học',
    'Tiếng Anh',
    'Sinh học',
    'Lịch sử',
    'Địa lý',
    'Tin học',
  ];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);

    try {
      TeacherExamRepository? repo;
      try {
        repo = context.read<TeacherExamRepository>();
      } catch (_) {
        repo = null;
      }

      SavedExamRepository? savedRepo;
      try {
        savedRepo = context.read<SavedExamRepository?>();
      } catch (_) {
        savedRepo = null;
      }

      final list = repo != null
          ? await repo.summaries()
          : <TeacherExamSummary>[];
      final savedList = savedRepo != null
          ? await savedRepo.getSavedExams()
          : <TeacherExamSummary>[];

      if (mounted) {
        setState(() {
          _exams = list;
          _savedExams = savedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách đề thi của giáo viên: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(
          'Không thể tải danh sách đề thi: ${e.toString().replaceAll('PostgrestException: ', '')}',
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _loadExams,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  Future<void> _handlePublish(TeacherExamSummary exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => PublishConfirmDialog(
        summary: exam,
        onConfirmed: () async {
          final repo = context.read<TeacherExamRepository>();
          await repo.publish(exam.id);
        },
      ),
    );

    if (confirmed == true && mounted) {
      await _loadExams();
      if (!mounted) return;

      setState(() {
        _activeTab = 'published';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Đề "${exam.title}" đã được công khai thành công!'),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Tạo phòng ngay',
            textColor: Colors.white,
            onPressed: () => context.go('/create_room?examId=${exam.id}'),
          ),
        ),
      );
    }
  }

  Future<void> _handleDeleteDraft(TeacherExamSummary exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => DeleteDraftConfirmDialog(
        summary: exam,
        onConfirmed: () async {
          final repo = context.read<TeacherExamRepository>();
          await repo.deleteDraft(exam.id);
        },
      ),
    );

    if (confirmed == true && mounted) {
      await _loadExams();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa bản nháp "${exam.title}".'),
          backgroundColor: AppTheme.textMain,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    final allCount = _exams.length;
    final draftCount = _exams.where((e) => e.isDraft).length;
    final publishedCount = _exams.where((e) => e.isPublished).length;
    final savedCount = _savedExams.length;

    final pool = _activeTab == 'saved' ? _savedExams : _exams;
    final filtered = pool.where((e) {
      // Filter by tab
      if (_activeTab == 'draft' && !e.isDraft) return false;
      if (_activeTab == 'published' && !e.isPublished) return false;

      // Filter by subject
      if (_selectedSubject != 'Tất cả môn' &&
          e.subject.toLowerCase() != _selectedSubject.toLowerCase()) {
        return false;
      }

      // Filter by search query
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final title = e.title.toLowerCase();
        final subject = e.subject.toLowerCase();
        final code = e.code.toLowerCase();
        return title.contains(q) || subject.contains(q) || code.contains(q);
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width < 600 ? 14 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            '📁 Quản Lý Kho Đề Thi Trắc Nghiệm',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMain,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/teacher/question_reports'),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Báo lỗi câu hỏi'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/create_exam'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tạo Đề Thi Mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Not authenticated prompt
                if (!isAuthenticated) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.amber,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bạn chưa đăng nhập tài khoản',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Đăng nhập để xem danh sách đề thi đã tạo, soạn bản nháp và công khai đề thi cho học sinh.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.go('/greeting'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                          ),
                          child: const Text('Đăng nhập ngay'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tabs: Tất cả, Đề nháp, Đã công khai, Đề đã lưu
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(
                          'all',
                          'Tất cả ($allCount)',
                          Icons.dashboard_outlined,
                        ),
                        const SizedBox(width: 6),
                        _buildTabButton(
                          'draft',
                          'Đề nháp ($draftCount)',
                          Icons.edit_note_rounded,
                          badgeColor: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 6),
                        _buildTabButton(
                          'published',
                          'Đã công khai ($publishedCount)',
                          Icons.public_rounded,
                          badgeColor: AppTheme.success,
                        ),
                        const SizedBox(width: 6),
                        _buildTabButton(
                          'saved',
                          'Đề đã lưu ($savedCount)',
                          Icons.bookmark_added_rounded,
                          badgeColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Search & Filter Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText:
                              'Tìm kiếm bộ đề theo tên, môn học hoặc mã đề (DT...)...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppTheme.primary,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.inputRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.inputRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Subject filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _subjects.map((subject) {
                      final isSelected = _selectedSubject == subject;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSubject = subject);
                            }
                          },
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.border,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Body content
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filtered.isEmpty)
                  _buildEmptyState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildExamCard(filtered[index]);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(
    String tabKey,
    String label,
    IconData icon, {
    Color? badgeColor,
  }) {
    final isActive = _activeTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Colors.white
                  : (badgeColor ?? AppTheme.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Chưa có đề thi nào trong danh mục này.';
    if (_activeTab == 'draft') {
      message = 'Bạn không có bản nháp nào đang soạn.';
    } else if (_activeTab == 'published') {
      message =
          'Chưa có đề nào được công khai. Hãy chọn đề nháp và bấm "Public đề".';
    } else if (_activeTab == 'saved') {
      message =
          'Bạn chưa lưu đề thi nào từ cộng đồng. Hãy khám phá và lưu đề từ trang Tìm kiếm.';
    } else if (_searchQuery.isNotEmpty) {
      message = 'Không tìm thấy đề thi phù hợp với từ khóa "$_searchQuery".';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(
            _activeTab == 'draft'
                ? Icons.edit_note_rounded
                : Icons.folder_open_rounded,
            size: 56,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go('/create_exam'),
            icon: const Icon(Icons.add),
            label: const Text('Soạn Đề Thi Mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(TeacherExamSummary exam) {
    final isSaved = _savedExams.any((s) => s.id == exam.id);
    final isDraft = exam.isDraft && !isSaved;
    final codeDisplay = exam.code.isNotEmpty ? exam.code : 'Mã: Đang tạo';

    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final isNarrow = cardConstraints.maxWidth < 640;

        final avatar = Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDraft
                ? const Color(0xFFFFFBEB)
                : (isSaved
                      ? const Color(0xFFF0ECFF)
                      : AppTheme.surfaceLavender),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isSaved
                ? Icons.bookmark_added_rounded
                : (isDraft
                      ? Icons.edit_note_rounded
                      : Icons.assignment_outlined),
            color: isDraft ? const Color(0xFFD97706) : AppTheme.primary,
            size: 26,
          ),
        );

        final mainInfo = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  exam.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSaved
                        ? const Color(0xFFEDE9FE)
                        : (isDraft
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFD1FAE5)),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSaved
                            ? Icons.bookmark_added_rounded
                            : (isDraft
                                  ? Icons.edit_note_rounded
                                  : Icons.check_circle_rounded),
                        size: 14,
                        color: isSaved
                            ? AppTheme.primary
                            : (isDraft
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF065F46)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSaved
                            ? 'Đề lưu từ cộng đồng'
                            : (isDraft ? 'Bản nháp' : 'Đã công khai'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSaved
                              ? AppTheme.primary
                              : (isDraft
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Môn: ${exam.subject} • ${exam.questionCount} câu hỏi • ${exam.durationMinutes} phút • Mã: $codeDisplay',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isNarrow ? WrapAlignment.end : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isSaved) ...[
              // Create Room Button
              ElevatedButton.icon(
                onPressed: () => context.go('/create_room?examId=${exam.id}'),
                icon: const Icon(Icons.meeting_room_outlined, size: 16),
                label: const Text('Tạo Phòng Thi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
              ),
              // View Detail Button
              OutlinedButton.icon(
                onPressed: () => context.go('/exam_detail?examId=${exam.id}'),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                label: const Text('Xem chi tiết'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
              ),
            ] else if (isDraft) ...[
              // Primary Public Button
              ElevatedButton.icon(
                onPressed: () => _handlePublish(exam),
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('Public đề'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
              ),
              // Edit Button
              OutlinedButton.icon(
                onPressed: () => context.go('/create_exam?examId=${exam.id}'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Sửa'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
              ),
              // Delete Button
              IconButton(
                tooltip: 'Xóa bản nháp',
                onPressed: () => _handleDeleteDraft(exam),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.error,
                ),
              ),
            ] else ...[
              // Create Room Button
              ElevatedButton.icon(
                onPressed: () => context.go('/create_room?examId=${exam.id}'),
                icon: const Icon(Icons.meeting_room_outlined, size: 16),
                label: const Text('Tạo Phòng Thi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
              ),
              // View Detail Button
              OutlinedButton.icon(
                onPressed: () => context.go('/exam_detail?examId=${exam.id}'),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                label: const Text('Xem chi tiết'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
              ),
              // Edit Button
              IconButton(
                tooltip: 'Chỉnh sửa đề thi',
                onPressed: () => context.go('/create_exam?examId=${exam.id}'),
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              ),
            ],
          ],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: isDraft
                  ? const Color(0xFFFDE68A)
                  : (isSaved
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : AppTheme.border),
              width: isDraft ? 1.5 : 1.0,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              onTap: () {
                if (isDraft) {
                  context.go('/create_exam?examId=${exam.id}');
                } else {
                  context.go('/exam_detail?examId=${exam.id}');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              avatar,
                              const SizedBox(width: 14),
                              Expanded(child: mainInfo),
                            ],
                          ),
                          const SizedBox(height: 12),
                          actions,
                        ],
                      )
                    : Row(
                        children: [
                          avatar,
                          const SizedBox(width: 16),
                          Expanded(child: mainInfo),
                          const SizedBox(width: 16),
                          actions,
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
