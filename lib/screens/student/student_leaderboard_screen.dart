import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class LeaderboardUser {
  final String name;
  final String email;
  final double avgScore;
  final int totalTests;
  final int rank;

  LeaderboardUser({
    required this.name,
    required this.email,
    required this.avgScore,
    required this.totalTests,
    required this.rank,
  });
}

class StudentLeaderboardScreen extends StatefulWidget {
  const StudentLeaderboardScreen({super.key});

  @override
  State<StudentLeaderboardScreen> createState() => _StudentLeaderboardScreenState();
}

class _StudentLeaderboardScreenState extends State<StudentLeaderboardScreen> {
  bool _isLoading = true;
  List<LeaderboardUser> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('attempts')
          .select('user_id, guest_name, score')
          .eq('status', 'submitted');

      final Map<String, List<double>> userScores = {};
      final List<dynamic> list = response as List<dynamic>;

      for (var item in list) {
        final key = (item['guest_name'] as String?) ?? (item['user_id'] as String?) ?? 'Học sinh';
        final score = (item['score'] as num?)?.toDouble() ?? 0.0;
        userScores.putIfAbsent(key, () => []).add(score);
      }

      final List<LeaderboardUser> users = [];
      userScores.forEach((nameKey, scores) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        users.add(LeaderboardUser(
          name: nameKey.contains('@') ? nameKey.split('@').first : nameKey,
          email: nameKey.contains('@') ? nameKey : 'hocsinh@gmail.com',
          avgScore: avg,
          totalTests: scores.length,
          rank: 0,
        ));
      });

      users.sort((a, b) => b.avgScore.compareTo(a.avgScore));

      final List<LeaderboardUser> rankedUsers = [];
      for (int i = 0; i < users.length; i++) {
        final u = users[i];
        rankedUsers.add(LeaderboardUser(
          name: u.name,
          email: u.email,
          avgScore: u.avgScore,
          totalTests: u.totalTests,
          rank: i + 1,
        ));
      }

      if (mounted) {
        setState(() {
          _leaderboard = rankedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải bảng xếp hạng: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserEmail = authProvider.userEmail;

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
                      '🥇 Bảng Xếp Hạng Học Sinh Toàn Hệ Thống',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
                else if (_leaderboard.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Chưa có dữ liệu xếp hạng học sinh nào.'),
                  )
                else ...[
                  // Top 3 Podium
                  if (_leaderboard.length >= 3) _buildPodiumSection(_leaderboard.take(3).toList()),

                  const SizedBox(height: 32),

                  // Leaderboard List
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _leaderboard.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0ECFF)),
                      itemBuilder: (context, index) {
                        final user = _leaderboard[index];
                        final isMe = user.email.toLowerCase() == currentUserEmail.toLowerCase();

                        return Container(
                          color: isMe ? const Color(0xFFF0ECFF).withValues(alpha: 0.5) : Colors.transparent,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.rank == 1
                                  ? const Color(0xFFFFD700)
                                  : (user.rank == 2 ? const Color(0xFFC0C0C0) : (user.rank == 3 ? const Color(0xFFCD7F32) : const Color(0xFFE5E7EB))),
                              child: Text(
                                '#${user.rank}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: user.rank <= 3 ? Colors.white : AppTheme.textMain,
                                ),
                              ),
                            ),
                            title: Text(
                              user.name + (isMe ? ' (Bạn)' : ''),
                              style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                            ),
                            subtitle: Text('Đã hoàn thành ${user.totalTests} bài thi'),
                            trailing: Text(
                              '${user.avgScore.toStringAsFixed(1)} điểm',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumSection(List<LeaderboardUser> top3) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top3.length > 1) _buildPodiumCard(top3[1], 2, 140, const Color(0xFFC0C0C0), '🥈'),
        const SizedBox(width: 16),
        _buildPodiumCard(top3[0], 1, 170, const Color(0xFFFFD700), '🥇'),
        const SizedBox(width: 16),
        if (top3.length > 2) _buildPodiumCard(top3[2], 3, 120, const Color(0xFFCD7F32), '🥉'),
      ],
    );
  }

  Widget _buildPodiumCard(LeaderboardUser user, int rank, double height, Color crownColor, String badge) {
    return Container(
      width: 160,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: crownColor, width: 2),
        boxShadow: [
          BoxShadow(color: crownColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${user.avgScore.toStringAsFixed(1)} điểm', style: TextStyle(fontSize: 12, color: crownColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
