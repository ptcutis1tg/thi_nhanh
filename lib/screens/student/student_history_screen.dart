import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/profile_service.dart';

class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({super.key});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  bool _isLoading = true;
  StudentProfileData _data = StudentProfileData.empty();
  String _selectedSubject = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final data = await ProfileService.fetchStudentData(
      userId: authProvider.user?.id,
      userEmail: authProvider.userEmail,
      userName: authProvider.userName,
    );
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTests = _selectedSubject == 'Tất cả'
        ? _data.recentTests
        : _data.recentTests.where((t) => t.title.toLowerCase().contains(_selectedSubject.toLowerCase())).toList();

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
                      '📊 Lịch Sử & Kết Quả Bài Thi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Metrics Row
                Row(
                  children: [
                    _buildMetricCard('Tổng số bài đã làm', '${_data.completedTestsCount} bài', Icons.assignment_turned_in_outlined, const Color(0xFF7C3AED)),
                    const SizedBox(width: 16),
                    _buildMetricCard('Điểm trung bình', '${_data.averageScore.toStringAsFixed(1)} / 10', Icons.analytics_outlined, const Color(0xFF2563EB)),
                    const SizedBox(width: 16),
                    _buildMetricCard('Điểm cao nhất', '${_data.highestScore.toStringAsFixed(1)} / 10', Icons.star_outline_rounded, const Color(0xFFD97706)),
                  ],
                ),
                const SizedBox(height: 32),

                // History List Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Danh Sách Bài Thi Đã Hoàn Thành',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          DropdownButton<String>(
                            value: _selectedSubject,
                            items: ['Tất cả', 'Toán', 'Vật lý', 'Hóa', 'Tiếng Anh']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSubject = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                      else if (filteredTests.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.history_outlined, size: 48, color: AppTheme.textSecondary),
                                SizedBox(height: 12),
                                Text('Chưa có lịch sử làm bài thi nào từ hệ thống.', style: TextStyle(color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTests.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0ECFF)),
                          itemBuilder: (context, index) {
                            final test = filteredTests[index];
                            return ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0ECFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(test.subjectIcon, style: const TextStyle(fontSize: 22)),
                              ),
                              title: Text(test.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Ngày nộp: ${test.date}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: test.scoreValue >= 8.0
                                      ? const Color(0xFFDCFCE7)
                                      : (test.scoreValue >= 5.0 ? const Color(0xFFFEF9C3) : const Color(0xFFFEE2E2)),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  test.score,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: test.scoreValue >= 8.0
                                        ? const Color(0xFF15803D)
                                        : (test.scoreValue >= 5.0 ? const Color(0xFFA16207) : const Color(0xFFB91C1C)),
                                  ),
                                ),
                              ),
                              onTap: () => context.go('/exam/physics-12'),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0ECFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
