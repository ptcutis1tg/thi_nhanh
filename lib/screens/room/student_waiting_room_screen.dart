import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class StudentWaitingRoomScreen extends StatefulWidget {
  const StudentWaitingRoomScreen({super.key});

  @override
  State<StudentWaitingRoomScreen> createState() => _StudentWaitingRoomScreenState();
}

class _StudentWaitingRoomScreenState extends State<StudentWaitingRoomScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _roomData;
  List<Map<String, dynamic>> _participants = [];

  @override
  void initState() {
    super.initState();
    _fetchRealRoom();
  }

  Future<void> _fetchRealRoom() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      // Fetch latest active room
      final roomRes = await client.from('rooms').select('id, code, title, exam_id').order('created_at', ascending: false).limit(1).maybeSingle();
      
      if (roomRes != null) {
        final roomId = roomRes['id'];
        final attemptsRes = await client.from('attempts').select('guest_name, user_id, status').eq('room_id', roomId);
        if (mounted) {
          setState(() {
            _roomData = roomRes;
            _participants = List<Map<String, dynamic>>.from(attemptsRes as List);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu phòng chờ học sinh: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roomTitle = _roomData?['title'] as String? ?? 'Phòng thi trực tuyến';
    final roomCode = _roomData?['code'] as String? ?? 'PT123456';
    final participantsCount = _participants.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                // Top Header Navigation
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
                    ),
                    const SizedBox(width: 8),
                    const Text('Phòng Chờ Thi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),

                // Hero Banner
                _buildHeroBanner(roomTitle),
                const SizedBox(height: 32),

                // Info Grid
                _buildInfoGrid(roomCode),
                const SizedBox(height: 32),

                // Participants Section
                _buildParticipantsSection(participantsCount),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/taking_exam');
        },
        backgroundColor: AppTheme.success,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Bắt Đầu Bài Thi'),
      ),
    );
  }

  Widget _buildHeroBanner(String title) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.hourglass_bottom, color: AppTheme.primary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Đang chờ mở phòng thi. Vui lòng giữ màn hình này và chuẩn bị sẵn sàng.',
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoGrid(String code) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room Code Card
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Sao chép mã'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),

        // Exam Details Card
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin bài thi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(height: 32, color: AppTheme.border),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem(Icons.schedule, 'Thời gian làm bài', '60 phút')),
                    Expanded(child: _buildInfoItem(Icons.format_list_numbered, 'Số lượng câu hỏi', 'Tự động đồng bộ')),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem(Icons.school_outlined, 'Giáo viên', 'Hệ thống')),
                    Expanded(child: _buildInfoItem(Icons.rule, 'Quy chế', 'Không thoát màn hình', isError: true)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              isError
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(value, style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  : Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection(int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.group, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Học sinh trong phòng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count học sinh trong phòng',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppTheme.border),
          if (_participants.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Hiện tại bạn là học sinh đầu tiên trong phòng thi này.', style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: _participants.map((p) {
                final name = (p['guest_name'] as String?) ?? 'Học sinh';
                final initials = name.isNotEmpty ? name[0].toUpperCase() : 'H';
                return _buildAvatarItem(name, initials);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarItem(String name, String initials) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
