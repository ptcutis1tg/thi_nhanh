import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class TeacherWaitingRoomScreen extends StatefulWidget {
  const TeacherWaitingRoomScreen({super.key});

  @override
  State<TeacherWaitingRoomScreen> createState() => _TeacherWaitingRoomScreenState();
}

class _TeacherWaitingRoomScreenState extends State<TeacherWaitingRoomScreen> {
  bool _showLeaderboard = true;
  bool _shuffleQuestions = false;
  bool _isLoading = true;

  Map<String, dynamic>? _roomData;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchRealTeacherRoom();
  }

  Future<void> _fetchRealTeacherRoom() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final roomRes = await client.from('rooms').select('id, code, title, exam_id').order('created_at', ascending: false).limit(1).maybeSingle();

      if (roomRes != null) {
        final roomId = roomRes['id'];
        final attemptsRes = await client.from('attempts').select('id, guest_name, user_id, status, started_at').eq('room_id', roomId);
        if (mounted) {
          setState(() {
            _roomData = roomRes;
            _students = List<Map<String, dynamic>>.from(attemptsRes as List);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Lỗi tải phòng thi giáo viên: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startExam() {
    context.go('/live_dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final teacherName = authProvider.userName;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roomTitle = _roomData?['title'] as String? ?? 'Phòng thi trắc nghiệm';
    final roomCode = _roomData?['code'] as String? ?? 'PT123456';

    return Scaffold(
      backgroundColor: AppTheme.background,
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
                    // Back Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
                        ),
                        const SizedBox(width: 8),
                        const Text('Quản Lý Phòng Thi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Header Section
                    _buildHeaderSection(roomTitle, roomCode, teacherName),
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
                color: Colors.white.withValues(alpha: 0.95),
                border: const Border(top: BorderSide(color: AppTheme.border)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ElevatedButton.icon(
                    onPressed: _startExam,
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'Bắt Đầu Cho Học Sinh Làm Bài',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
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

  Widget _buildHeaderSection(String title, String code, String teacher) {
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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'ĐANG CHỜ MỞ PHÒNG',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Giáo viên quản lý: $teacher',
                style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
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
                  Text(
                    code,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 2),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.copy, color: AppTheme.primary),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: AppTheme.primary),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cài đặt phòng thi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Điều chỉnh thông số trước khi cho phép học sinh làm bài', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const Text('Hiện Xếp Hạng Realtime', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Switch(value: _showLeaderboard, onChanged: (v) => setState(() => _showLeaderboard = v)),
              const SizedBox(width: 16),
              const Text('Trộn câu hỏi & đáp án', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
                const Text('Học sinh đã tham gia phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${_students.length} học sinh',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 24, color: AppTheme.border),
        if (_students.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text('Chưa có học sinh nào tham gia phòng thi này.', style: TextStyle(color: AppTheme.textSecondary)),
          )
        else
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
                final name = (student['guest_name'] as String?) ?? 'Học sinh';
                final initials = name.isNotEmpty ? name[0].toUpperCase() : 'H';

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(width: 30, child: Text('${index + 1}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary))),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Color(0xFFF0ECFF), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: const BoxDecoration(color: Color(0xFFDCFCE7), borderRadius: BorderRadius.all(Radius.circular(100))),
                        child: const Text('Đã sẵn sàng', style: TextStyle(color: Color(0xFF15803D), fontSize: 12, fontWeight: FontWeight.bold)),
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
