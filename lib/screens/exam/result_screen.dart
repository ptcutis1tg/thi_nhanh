import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildCongratulationCard(),
                const SizedBox(height: 32),
                _buildDetailedStats(),
                const SizedBox(height: 32),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCongratulationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: const Border(top: BorderSide(color: AppTheme.primary, width: 8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.workspace_premium, color: AppTheme.success, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chúc mừng bạn đã hoàn thành bài thi!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kiểm tra giữa kì Môn Toán Học 10',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Score Circle
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 8),
            ),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Điểm số', style: TextStyle(color: AppTheme.textSecondary)),
                Text('8.5', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primary, height: 1.2)),
                Text('/10', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.check_circle, AppTheme.success, 'Câu đúng', '17', 'câu')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(Icons.cancel, AppTheme.warning, 'Câu sai', '2', 'câu')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(Icons.help, AppTheme.textSecondary, 'Bỏ qua', '1', 'câu')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(Icons.leaderboard, AppTheme.primary, 'Xếp hạng', '5', '/45')),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, Color color, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.remove_red_eye),
          label: const Text('Xem lại bài làm'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
          icon: const Icon(Icons.home),
          label: const Text('Về trang chủ'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
      ],
    );
  }
}
