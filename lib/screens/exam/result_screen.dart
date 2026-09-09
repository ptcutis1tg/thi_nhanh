import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';

class ResultScreen extends StatefulWidget {
  final double? score;
  final int? total;
  final int? correct;
  final int? wrong;
  final int? skipped;
  final String? title;

  const ResultScreen({
    super.key,
    this.score,
    this.total,
    this.correct,
    this.wrong,
    this.skipped,
    this.title,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = false;

  double _finalScore = 0.0;
  int _totalQuestions = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _skippedCount = 0;
  String _examTitle = 'Bài thi vừa hoàn thành';
  int _rank = 1;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.score != null) {
      setState(() {
        _finalScore = widget.score!;
        _totalQuestions = widget.total ?? 10;
        _correctCount = widget.correct ?? (_finalScore / 10 * _totalQuestions).round();
        _wrongCount = widget.wrong ?? (_totalQuestions - _correctCount);
        _skippedCount = widget.skipped ?? 0;
        _examTitle = widget.title ?? 'Bài thi vừa hoàn thành';
      });
    } else {
      // Query latest submitted attempt from Supabase
      setState(() => _isLoading = true);
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('attempts')
            .select('score, started_at, submitted_at, exams(title)')
            .eq('status', 'submitted')
            .order('submitted_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (mounted && res != null) {
          final scoreVal = (res['score'] as num?)?.toDouble() ?? 8.5;
          final examMap = res['exams'] as Map<String, dynamic>?;
          final titleStr = examMap?['title'] as String? ?? 'Bài thi vừa hoàn thành';

          setState(() {
            _finalScore = scoreVal;
            _examTitle = titleStr;
            _totalQuestions = 10;
            _correctCount = (scoreVal / 10 * 10).round();
            _wrongCount = 10 - _correctCount;
            _skippedCount = 0;
            _isLoading = false;
          });
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: TopNavBar(),
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          Text(
            _examTitle,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Điểm số', style: TextStyle(color: AppTheme.textSecondary)),
                Text(
                  _finalScore.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primary, height: 1.2),
                ),
                const Text('/10', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
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
        Expanded(child: _buildStatCard(Icons.check_circle, AppTheme.success, 'Câu đúng', '$_correctCount', 'câu')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(Icons.cancel, AppTheme.warning, 'Câu sai', '$_wrongCount', 'câu')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(Icons.help, AppTheme.textSecondary, 'Bỏ qua', '$_skippedCount', 'câu')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(Icons.leaderboard, AppTheme.primary, 'Xếp hạng', '#$_rank', '')),
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
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
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
          onPressed: () {
            context.go('/student/history');
          },
          icon: const Icon(Icons.history),
          label: const Text('Xem lịch sử thi'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.go('/home');
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

