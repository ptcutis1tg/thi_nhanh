import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_theme.dart';

class TeacherStudentResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? testSubmissions;
  const TeacherStudentResultsScreen({super.key, this.testSubmissions});

  @override
  State<TeacherStudentResultsScreen> createState() => _TeacherStudentResultsScreenState();
}

class _TeacherStudentResultsScreenState extends State<TeacherStudentResultsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _submissions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    if (widget.testSubmissions != null) {
      setState(() {
        _submissions = widget.testSubmissions!;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final results = await ProfileService.fetchTeacherStudentResultsSecure(
      userId: auth.user?.id,
      userEmail: auth.userEmail,
      userName: auth.userName,
    );

    if (mounted) {
      setState(() {
        _submissions = results;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSubmissions {
    if (_searchQuery.isEmpty) return _submissions;
    final query = _searchQuery.toLowerCase();
    return _submissions.where((sub) {
      final studentName = (sub['studentName'] as String? ?? '').toLowerCase();
      final examTitle = (sub['examTitle'] as String? ?? '').toLowerCase();
      final subject = (sub['subject'] as String? ?? '').toLowerCase();
      return studentName.contains(query) || examTitle.contains(query) || subject.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final filtered = _filteredSubmissions;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 32,
              vertical: compact ? 20 : 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
                          tooltip: 'Quay lại',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '📈 Kết Quả & Bài Nộp Học Sinh',
                            style: TextStyle(
                              fontSize: compact ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMain,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _loadSubmissions,
                          icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                          tooltip: 'Làm mới',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search Field
                    if (_submissions.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEBE6FC)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                key: const Key('results-search-field'),
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Tìm theo tên học sinh, đề thi, môn học...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                                onChanged: (val) {
                                  setState(() => _searchQuery = val.trim());
                                },
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      )
                    else if (_submissions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEBE6FC)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1EDFD),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 48,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Chưa có lượt nộp bài nào từ học sinh',
                              style: TextStyle(
                                color: AppTheme.textMain,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Khi học sinh hoàn thành đề thi hoặc bài kiểm tra phòng thi, kết quả sẽ hiển thị tại đây.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEBE6FC)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Không tìm thấy kết quả phù hợp',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Xóa bộ lọc tìm kiếm'),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(compact ? 16 : 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEBE6FC)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng số lượt nộp bài: ${filtered.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: Color(0xFFF0ECFF)),
                              itemBuilder: (context, index) {
                                final sub = filtered[index];
                                final examTitle = sub['examTitle'] as String? ?? 'Bài kiểm tra';
                                final studentName = sub['studentName'] as String? ?? 'Học sinh';
                                final score = (sub['score'] as num?)?.toDouble() ?? 0.0;
                                final attemptId = sub['attemptId']?.toString();
                                final submittedAt = DateTime.tryParse(sub['submittedAt']?.toString() ?? '')?.toLocal();
                                final timeStr = submittedAt != null
                                    ? '${submittedAt.hour.toString().padLeft(2, '0')}:${submittedAt.minute.toString().padLeft(2, '0')} ${submittedAt.day.toString().padLeft(2, '0')}/${submittedAt.month.toString().padLeft(2, '0')}'
                                    : null;

                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    onTap: attemptId != null && attemptId.isNotEmpty
                                        ? () => context.go('/result?attemptId=${Uri.encodeComponent(attemptId)}')
                                        : null,
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFF0ECFF),
                                      child: Text(
                                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'H',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      studentName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Đề: $examTitle',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (timeStr != null)
                                          Text(
                                            'Nộp lúc: $timeStr',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: score >= 8.0
                                            ? const Color(0xFFDCFCE7)
                                            : (score >= 5.0 ? const Color(0xFFFEF9C3) : const Color(0xFFFEE2E2)),
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(
                                          color: score >= 8.0
                                              ? const Color(0xFFBBF7D0)
                                              : (score >= 5.0 ? const Color(0xFFFDE68A) : const Color(0xFFFECACA)),
                                        ),
                                      ),
                                      child: Text(
                                        '${score.toStringAsFixed(1)} điểm',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: score >= 8.0
                                              ? const Color(0xFF15803D)
                                              : (score >= 5.0 ? const Color(0xFFA16207) : const Color(0xFFB91C1C)),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
