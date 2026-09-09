import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';

class LiveDashboardScreen extends StatefulWidget {
  final String? roomCode;
  const LiveDashboardScreen({super.key, this.roomCode});

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  bool _isLoading = true;
  String _roomCodeStr = 'PT200001';
  String _roomTitle = 'Phòng thi trực tuyến';
  String _subjectName = 'Toán Học';

  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadLiveRoomData();
  }

  Future<void> _loadLiveRoomData() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final targetCode = widget.roomCode ?? 'PT200001';

      // Query room
      final rRes = await client
          .from('rooms')
          .select('id, code, name, status, exam_id, exams(title, subject)')
          .ilike('code', targetCode)
          .maybeSingle();

      if (rRes != null) {
        _roomCodeStr = rRes['code'] ?? targetCode;
        _roomTitle = rRes['name'] ?? 'Phòng thi';
        final examMap = rRes['exams'] as Map<String, dynamic>?;
        if (examMap != null) {
          _subjectName = examMap['subject'] ?? 'Toán Học';
        }

        final roomId = rRes['id'].toString();

        // Query attempts in this room
        final aRes = await client
            .from('attempts')
            .select('id, guest_name, score, status, started_at, submitted_at')
            .eq('room_id', roomId);

        final aList = aRes as List<dynamic>;
        _students = aList.map((a) {
          final gName = a['guest_name']?.toString() ?? 'Học sinh';
          final initials = gName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
          final isDone = a['status'] == 'submitted';
          final scoreNum = (a['score'] as num?)?.toDouble() ?? 0.0;

          return {
            'name': gName,
            'initials': initials.isEmpty ? 'HS' : initials,
            'answered': isDone ? 20 : 12,
            'correct': isDone ? (scoreNum / 10 * 20).round() : 8,
            'wrong': isDone ? 20 - (scoreNum / 10 * 20).round() : 4,
            'completed': isDone,
            'score': scoreNum,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Lỗi tải Live Dashboard từ Supabase: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        appBar: TopNavBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        color: const Color(0xFF24233a),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phòng Thi: $_roomCodeStr',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Môn: $_subjectName • $_roomTitle • Đang diễn ra',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
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
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.pop();
                        context.go('/home');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      child: const Text('Đóng phòng thi'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.stop_circle, color: Colors.white),
            label: const Text('Kết thúc Phòng thi', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final completedCount = _students.where((s) => s['completed'] == true).length;
    final inProgressCount = _students.length - completedCount;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'SỐ HỌC SINH',
            value: '${_students.length}',
            subtitle: 'Đang kết nối phòng',
            icon: Icons.people,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'ĐANG LÀM BÀI',
            value: '$inProgressCount',
            subtitle: 'Đang tương tác làm bài',
            icon: Icons.edit_note,
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'ĐÃ NỘP BÀI',
            value: '$completedCount',
            subtitle: 'Hoàn thành bài thi',
            icon: Icons.task_alt,
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Danh sách Học sinh & Tiến độ Trực tiếp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              final student = _students[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0ECFF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        student['initials'],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Text(
                        student['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đã trả lời: ${student['answered']}/20 câu',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              Text(
                                student['completed']
                                    ? 'Điểm: ${student['score']} đ'
                                    : '${((student['answered'] / 20) * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: student['completed'] ? AppTheme.success : AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: student['answered'] / 20,
                              minHeight: 8,
                              backgroundColor: AppTheme.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                student['completed'] ? AppTheme.success : AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: student['completed']
                            ? AppTheme.success.withOpacity(0.1)
                            : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        student['completed'] ? 'Đã nộp bài' : 'Đang làm...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: student['completed'] ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
