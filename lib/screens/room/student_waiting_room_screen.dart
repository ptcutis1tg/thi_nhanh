import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';

class StudentWaitingRoomScreen extends StatelessWidget {
  const StudentWaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                // Hero Banner
                _buildHeroBanner(),
                const SizedBox(height: 32),
                
                // Info Grid
                _buildInfoGrid(),
                const SizedBox(height: 32),
                
                // Participants Section
                _buildParticipantsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.hourglass_bottom, color: AppTheme.primary, size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'Kiểm tra giữa kỳ môn Toán Học 10',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Đang chờ giáo viên mở phòng thi. Vui lòng giữ màn hình này và chuẩn bị sẵn sàng.',
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
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
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
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
                  child: const Text(
                    'PT892341',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 2),
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
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin bài thi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(height: 32, color: AppTheme.border),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem(Icons.schedule, 'Thời gian làm bài', '45 phút')),
                    Expanded(child: _buildInfoItem(Icons.format_list_numbered, 'Số lượng câu hỏi', '40 câu trắc nghiệm')),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem(Icons.school_outlined, 'Giáo viên coi thi', 'Cô Nguyễn Thị A')),
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
                        color: AppTheme.error.withOpacity(0.1),
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

  Widget _buildParticipantsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
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
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  '45/50 học sinh đã sẵn sàng',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppTheme.border),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildAvatarItem('Bạn', 'B', isSelf: true),
              _buildAvatarItem('Minh Anh', 'MA'),
              _buildAvatarItem('Hải Bình', 'HB'),
              _buildAvatarItem('Tiến Cường', 'TC'),
              _buildAvatarItem('Đang vào...', '?', isConnecting: true),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 32, color: AppTheme.border),
          TextButton(
            onPressed: () {},
            child: const Text('Xem tất cả danh sách'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarItem(String name, String initials, {bool isSelf = false, bool isConnecting = false}) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConnecting ? AppTheme.background : (isSelf ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isConnecting ? AppTheme.border : (isSelf ? AppTheme.primary : AppTheme.border),
                  width: 2,
                  style: isConnecting ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              alignment: Alignment.center,
              child: isConnecting 
                  ? const Icon(Icons.person_outline, color: AppTheme.textSecondary)
                  : Text(initials, style: TextStyle(fontWeight: FontWeight.bold, color: isSelf ? AppTheme.primary : AppTheme.textSecondary)),
            ),
            if (!isConnecting)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
            fontStyle: isConnecting ? FontStyle.italic : FontStyle.normal,
            color: isConnecting ? AppTheme.textSecondary : AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}
