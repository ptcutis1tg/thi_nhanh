import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';

class LiveDashboardScreen extends StatefulWidget {
  const LiveDashboardScreen({super.key});

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  final List<Map<String, dynamic>> _students = [
    {
      'name': 'Nguyễn Văn A',
      'initials': 'NA',
      'answered': 15,
      'correct': 10,
      'wrong': 5,
      'completed': false,
    },
    {
      'name': 'Trần Thị B',
      'initials': 'TB',
      'answered': 8,
      'correct': 6,
      'wrong': 2,
      'completed': false,
    },
    {
      'name': 'Lê Văn C',
      'initials': 'LC',
      'answered': 20,
      'correct': 18,
      'wrong': 2,
      'completed': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const TopNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildMetricsRow(),
                const SizedBox(height: 32),
                _buildMonitoringTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF24233a), // Dark theme header
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phòng Thi: PT203948',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Môn: Toán Học - Lớp 10A1 • Đang diễn ra',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận đóng phòng'),
                  content: const Text('Sau khi đóng, học sinh sẽ không thể tiếp tục làm bài hoặc nộp bài. Bạn có chắc chắn?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.pop();
                        context.go('/home');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      child: const Text('Đóng phòng'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.cancel, color: AppTheme.error),
            label: const Text('Đóng phòng thi', style: TextStyle(color: AppTheme.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.error, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.group,
            color: AppTheme.primary,
            label: 'Tổng số học sinh',
            value: '45',
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.timer,
            color: AppTheme.textMain,
            label: 'Thời gian còn lại',
            value: '15:30',
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.check_circle,
            color: AppTheme.success,
            label: 'Đã hoàn thành',
            value: '12/45',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required IconData icon, required Color color, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Table Header Title
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Tiến độ làm bài (Live)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    _buildLegendItem(AppTheme.success, 'Đúng'),
                    const SizedBox(width: 16),
                    _buildLegendItem(AppTheme.warning, 'Sai'),
                    const SizedBox(width: 16),
                    _buildLegendItem(AppTheme.border, 'Chưa làm'),
                  ],
                ),
              ],
            ),
          ),
          
          // Columns Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppTheme.surface,
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Học sinh', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 1, child: Center(child: Text('Câu hỏi HT', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)))),
                Expanded(flex: 8, child: Text('Tiến độ & Kết quả (Tổng 20 câu)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
              ],
            ),
          ),
          
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              final student = _students[index];
              return _buildStudentRow(student);
            },
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () {},
              child: const Text('Xem thêm danh sách'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> student) {
    final int total = 20;
    final int correct = student['correct'];
    final int wrong = student['wrong'];
    final bool isCompleted = student['completed'];
    
    return Container(
      color: isCompleted ? AppTheme.success.withOpacity(0.05) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(student['initials'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                ),
                const SizedBox(width: 12),
                Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                if (isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                    child: const Text('Xong', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.task_alt, color: AppTheme.success)
                  : Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primary, width: 2)),
                      alignment: Alignment.center,
                      child: Text('${student['answered']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Container(
              height: 16,
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(100)),
              clipBehavior: Clip.hardEdge,
              child: Row(
                children: [
                  Expanded(flex: correct, child: Container(color: AppTheme.success)),
                  Expanded(flex: wrong, child: Container(color: AppTheme.warning)),
                  Expanded(flex: total - correct - wrong, child: Container()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
