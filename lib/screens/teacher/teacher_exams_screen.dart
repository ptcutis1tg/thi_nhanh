import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      
      var query = client.from('exams').select('id, title, subject, total_questions, created_at, code');
      final res = await query.order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _exams = List<Map<String, dynamic>>.from(res as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách đề thi của giáo viên: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _exams.where((e) {
      final title = (e['title'] as String? ?? '').toLowerCase();
      final subject = (e['subject'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || subject.contains(q);
    }).toList();

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '📁 Quản Lý Kho Đề Thi Trắc Nghiệm',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/create_exam'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tạo Đề Thi Mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bộ đề theo tên hoặc môn học...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E0F8)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
                else if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        const Icon(Icons.folder_open_rounded, size: 56, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        const Text('Chưa có đề thi nào được tạo.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/create_exam'),
                          child: const Text('Soạn Đề Ngay'),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final exam = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0ECFF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.assignment_outlined, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam['title'] as String? ?? 'Đề thi trắc nghiệm',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Môn: ${exam['subject'] ?? 'Tổng hợp'} • ${exam['total_questions'] ?? 40} câu hỏi • Mã đề: ${exam['code'] ?? 'DT001'}',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => context.go('/create_room'),
                                  icon: const Icon(Icons.meeting_room_outlined, size: 16),
                                  label: const Text('Tạo Phòng Thi'),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => context.go('/create_exam'),
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
