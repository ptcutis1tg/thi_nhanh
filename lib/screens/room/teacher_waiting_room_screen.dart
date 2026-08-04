import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';

class TeacherWaitingRoomScreen extends StatefulWidget {
  const TeacherWaitingRoomScreen({super.key});

  @override
  State<TeacherWaitingRoomScreen> createState() => _TeacherWaitingRoomScreenState();
}

class _TeacherWaitingRoomScreenState extends State<TeacherWaitingRoomScreen> {
  bool _showLeaderboard = true;
  bool _shuffleQuestions = false;

  final List<Map<String, dynamic>> _students = [
    {
      'id': 'HS001',
      'name': 'Trần Tuấn Anh',
      'status': 'ready',
      'time': '08:15 AM',
      'avatar': 'T'
    },
    {
      'id': 'HS002',
      'name': 'Lê Thị Bích',
      'status': 'ready',
      'time': '08:16 AM',
      'avatar': 'L'
    },
    {
      'id': 'HS003',
      'name': 'Phạm Văn Cường',
      'status': 'connecting',
      'time': '--',
      'avatar': 'P'
    },
  ];

  void _startExam() {
    context.go('/live_dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32).copyWith(bottom: 120),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(),
                    const SizedBox(height: 32),
                    
                    // Settings Section
                    _buildSettingsSection(),
                    const SizedBox(height: 32),
                    
                    // Students Grid
                    _buildStudentsGrid(),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: const Border(top: BorderSide(color: AppTheme.border)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ElevatedButton.icon(
                    onPressed: _startExam,
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'Bắt đầu làm bài',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'ĐANG CHỜ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Kiểm tra giữa kì Môn Toán Học 10',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lớp 10A1 - Giáo viên: Nguyễn Văn A',
                style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border(top: BorderSide(color: AppTheme.primary, width: 4)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'MÃ PHÒNG THI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PT892341',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 2),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.copy, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('https://thinhanh.vn/join/PT...', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: AppTheme.textMain,
                      elevation: 0,
                    ),
                    child: const Text('Chia sẻ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cài đặt phòng thi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Điều chỉnh các thông số trước khi bắt đầu', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const Text('Hiện Realtime Leaderboard', style: TextStyle(fontWeight: FontWeight.w500)),
              Switch(value: _showLeaderboard, onChanged: (v) => setState(() => _showLeaderboard = v)),
              const SizedBox(width: 24),
              const Text('Trộn câu hỏi & đáp án', style: TextStyle(fontWeight: FontWeight.w500)),
              Switch(value: _shuffleQuestions, onChanged: (v) => setState(() => _shuffleQuestions = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Học sinh đã tham gia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${_students.length}/50',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.grid_view)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.list, color: AppTheme.primary)),
              ],
            ),
          ],
        ),
        const Divider(height: 24, color: AppTheme.border),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              final student = _students[index];
              final isReady = student['status'] == 'ready';
              
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text('${index + 1}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary))),
                    Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(student['avatar'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student['name'], style: TextStyle(fontWeight: FontWeight.bold, fontStyle: isReady ? FontStyle.normal : FontStyle.italic)),
                          Text('ID: ${student['id']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            isReady ? Icons.check_circle : Icons.hourglass_empty,
                            color: isReady ? AppTheme.success : AppTheme.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isReady ? 'Đã sẵn sàng' : 'Đang vào phòng',
                            style: TextStyle(color: isReady ? AppTheme.success : AppTheme.warning, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(student['time'], style: const TextStyle(color: AppTheme.textSecondary)),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.person_remove_outlined),
                      color: AppTheme.error,
                      tooltip: 'Kích khỏi phòng',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
