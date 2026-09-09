import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class TeacherStudentResultsScreen extends StatefulWidget {
  const TeacherStudentResultsScreen({super.key});

  @override
  State<TeacherStudentResultsScreen> createState() => _TeacherStudentResultsScreenState();
}

class _TeacherStudentResultsScreenState extends State<TeacherStudentResultsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('attempts')
          .select('''
            id,
            guest_name,
            score,
            status,
            submitted_at,
            exams (
              title
            )
          ''')
          .eq('status', 'submitted')
          .order('submitted_at', ascending: false);

      if (mounted) {
        setState(() {
          _submissions = List<Map<String, dynamic>>.from(res as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải kết quả làm bài của học sinh: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '📈 Kết Quả & Bài Nộp Học Sinh',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
                else if (_submissions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 56, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text('Chưa có lượt nộp bài nào từ học sinh.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng số lượt nộp bài: ${_submissions.length}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _submissions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0ECFF)),
                          itemBuilder: (context, index) {
                            final sub = _submissions[index];
                            final examMap = sub['exams'] as Map<String, dynamic>?;
                            final examTitle = examMap?['title'] as String? ?? 'Bài kiểm tra';
                            final studentName = sub['guest_name'] as String? ?? 'Học sinh';
                            final score = (sub['score'] as num?)?.toDouble() ?? 0.0;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF0ECFF),
                                child: Text(studentName.isNotEmpty ? studentName[0].toUpperCase() : 'H', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              ),
                              title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Đề: $examTitle', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: score >= 8.0 ? const Color(0xFFDCFCE7) : (score >= 5.0 ? const Color(0xFFFEF9C3) : const Color(0xFFFEE2E2)),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${score.toStringAsFixed(1)} điểm',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: score >= 8.0 ? const Color(0xFF15803D) : (score >= 5.0 ? const Color(0xFFA16207) : const Color(0xFFB91C1C)),
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
      ),
    );
  }
}
