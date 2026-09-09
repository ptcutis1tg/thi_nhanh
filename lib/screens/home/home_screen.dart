import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/repositories/room_repository.dart';
import '../room/widgets/join_room_guest_dialog.dart';
import '../../core/services/profile_service.dart';
import '../../shared/widgets/exam_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _joinRoomController = TextEditingController();
  late AnimationController _pulseController;

  bool _isLoadingStats = true;
  StudentProfileData _studentStats = StudentProfileData.empty();
  TeacherProfileData _teacherStats = TeacherProfileData.empty();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    final authProvider = context.read<AuthProvider>();
    final studentDataFuture = ProfileService.fetchStudentData(
      userId: authProvider.user?.id,
      userEmail: authProvider.userEmail,
      userName: authProvider.userName,
    );
    final teacherDataFuture = ProfileService.fetchTeacherData(
      userId: authProvider.user?.id,
      userEmail: authProvider.userEmail,
      userName: authProvider.userName,
    );

    final results = await Future.wait([studentDataFuture, teacherDataFuture]);
    if (mounted) {
      setState(() {
        _studentStats = results[0] as StudentProfileData;
        _teacherStats = results[1] as TeacherProfileData;
        _isLoadingStats = false;
      });
    }
  }

  @override
  void dispose() {
    _joinRoomController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinRoom(BuildContext context) async {
    final code = _joinRoomController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã phòng')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    RoomRepository? roomRepo;
    try {
      roomRepo = context.read<RoomRepository>();
    } catch (_) {
      roomRepo = null;
    }

    if (roomRepo == null) {
      context.go('/student_waiting_room?roomId=$code');
      return;
    }

    if (!authProvider.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => JoinRoomGuestDialog(
          roomCode: code,
          onJoin: (guestName, password) async {
            final result = await roomRepo!.joinRoom(
              code: code,
              password: password,
              guestName: guestName,
            );
            if (context.mounted) {
              context.go(
                '/student_waiting_room?roomId=${result.roomId}&participantId=${result.participantId}${result.guestToken != null ? '&guestToken=${result.guestToken}' : ''}',
              );
            }
          },
        ),
      );
    } else {
      try {
        final result = await roomRepo.joinRoom(code: code);
        if (context.mounted) {
          context.go(
            '/student_waiting_room?roomId=${result.roomId}&participantId=${result.participantId}',
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.toLowerCase().contains('password') || errorMsg.toLowerCase().contains('mật khẩu')) {
          showDialog(
            context: context,
            builder: (ctx) => JoinRoomGuestDialog(
              roomCode: code,
              onJoin: (guestName, password) async {
                final result = await roomRepo!.joinRoom(
                  code: code,
                  password: password,
                );
                if (context.mounted) {
                  context.go(
                    '/student_waiting_room?roomId=${result.roomId}&participantId=${result.participantId}',
                  );
                }
              },
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isStudent = authProvider.isStudent;
    final avatarUrl = authProvider.userAvatarUrl;

    ImageProvider? avatarImage;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        final base64Str = avatarUrl.contains(',') ? avatarUrl.split(',').last : avatarUrl;
        avatarImage = MemoryImage(base64Decode(base64Str));
      } catch (e) {
        debugPrint('Lỗi giải mã avatar HomeScreen: $e');
      }
    }

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE), // Light purple tinted background
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 32,
          horizontal: isMobile ? 16 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER SECTION (User Profile, Role Switcher & Quick Room Entry)
                _buildHeaderSection(context, authProvider, avatarImage, isMobile),

                const SizedBox(height: 24),

                // 2. QUICK STATS BAR (REAL SUPABASE DATA)
                _buildQuickStatsBar(isStudent, isMobile),

                const SizedBox(height: 32),

                // 3. MAIN SECTION TITLE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isStudent ? '🚀 Danh Mục Học Tập' : '🛠️ Chức Năng Quản Lý',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      isStudent ? 'Góc nhìn Học sinh' : 'Góc nhìn Giáo viên',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. MAIN FEATURE CARDS GRID (6 Cards with Dedicated Screen Routes)
                _buildFeatureCardsGrid(context, isStudent, isMobile),

                const SizedBox(height: 40),

                // 5. RECENT ACTIVITY SECTION (REAL SUPABASE DATA)
                _buildRecentSection(context, isStudent),

                const SizedBox(height: 40),

                // 6. NOTIFICATIONS & GUIDES SECTION
                _buildInfoAndHelpSection(context, isStudent, isMobile),

                const SizedBox(height: 32),

                // 7. BOTTOM UTILITY BAR
                _buildBottomUtilityBar(context, authProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeaderSection(
    BuildContext context,
    AuthProvider authProvider,
    ImageProvider? avatarImage,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B46C1).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _buildUserInfoRow(authProvider, avatarImage),
                const SizedBox(height: 16),
                _buildQuickRoomInput(),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildUserInfoRow(authProvider, avatarImage)),
                const SizedBox(width: 24),
                SizedBox(width: 420, child: _buildQuickRoomInput()),
              ],
            ),
    );
  }

  Widget _buildUserInfoRow(AuthProvider authProvider, ImageProvider? avatarImage) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? const Icon(Icons.person, size: 28, color: AppTheme.primary)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, ${authProvider.userName} 👋',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  await authProvider.toggleRole();
                  if (!mounted) return;
                  _loadDashboardData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã chuyển sang vai trò ${authProvider.isStudent ? 'Học sinh' : 'Giáo viên'}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0ECFF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFE4DFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authProvider.isStudent ? '🎓 Học sinh' : '👨‍🏫 Giáo viên',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.sync_alt_rounded, size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickRoomInput() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE5E0F8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.meeting_room_outlined, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _joinRoomController,
              onSubmitted: (_) => _handleJoinRoom(context),
              decoration: const InputDecoration(
                hintText: 'Nhập mã phòng PTxxxxxx...',
                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleJoinRoom(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Vào ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- QUICK STATS BAR (REAL DATA) ---
  Widget _buildQuickStatsBar(bool isStudent, bool isMobile) {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final stats = isStudent
        ? [
            {
              'icon': '🔥',
              'title': 'Chuỗi ôn tập',
              'value': '${_studentStats.streakDays} ngày',
              'sub': _studentStats.streakDays > 0 ? 'Giữ vững phong độ!' : 'Hãy tích cực làm bài',
            },
            {
              'icon': '🎯',
              'title': 'Điểm trung bình',
              'value': '${_studentStats.averageScore.toStringAsFixed(1)} / 10',
              'sub': 'Dữ liệu thực tế Supabase',
            },
            {
              'icon': '📝',
              'title': 'Đã hoàn thành',
              'value': '${_studentStats.completedTestsCount} bài',
              'sub': 'Lượt nộp bài thành công',
            },
          ]
        : [
            {
              'icon': '📄',
              'title': 'Đề thi đã tạo',
              'value': '${_teacherStats.createdExamsCount} bộ đề',
              'sub': 'Lưu trên hệ thống',
            },
            {
              'icon': '👥',
              'title': 'Lượt tham gia',
              'value': '${_teacherStats.totalParticipants} học sinh',
              'sub': 'Tổng số bài nộp',
            },
            {
              'icon': '⚡',
              'title': 'Tỉ lệ nộp bài',
              'value': '${_teacherStats.completionRate.toStringAsFixed(0)}%',
              'sub': 'Đúng thời hạn',
            },
          ];

    return isMobile
        ? Column(
            children: stats
                .map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _buildStatCard(s['icon']!, s['title']!, s['value']!, s['sub']!),
                    ))
                .toList(),
          )
        : Row(
            children: stats
                .map((s) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildStatCard(s['icon']!, s['title']!, s['value']!, s['sub']!),
                      ),
                    ))
                .toList(),
          );
  }

  Widget _buildStatCard(String icon, String title, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0ECFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECFF),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                Text(sub, style: TextStyle(fontSize: 11, color: AppTheme.primary.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 6 FEATURE CARDS GRID ---
  Widget _buildFeatureCardsGrid(BuildContext context, bool isStudent, bool isMobile) {
    final List<Map<String, dynamic>> items = isStudent
        ? [
            {
              'title': 'Vào Phòng Thi',
              'desc': 'Tham gia thi trực tiếp với mã phòng từ Giáo viên',
              'icon': Icons.door_front_door_outlined,
              'gradient': const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              'route': '/student_waiting_room',
              'isLive': false,
            },
            {
              'title': 'Tìm Đề Luyện Tập',
              'desc': 'Khám phá hàng ngàn đề trắc nghiệm chuẩn cấu trúc',
              'icon': Icons.search_rounded,
              'gradient': const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              'route': '/search',
              'isLive': false,
            },
            {
              'title': 'Bài Đang Làm',
              'desc': 'Tiếp tục hoàn thành bài thi chưa nộp',
              'icon': Icons.edit_note_rounded,
              'gradient': const [Color(0xFF059669), Color(0xFF047857)],
              'route': '/exam/physics-12',
              'isLive': true,
            },
            {
              'title': 'Lịch Sử & Kết Quả',
              'desc': 'Xem lại điểm số, lời giải chi tiết và đáp án',
              'icon': Icons.analytics_outlined,
              'gradient': const [Color(0xFFD97706), Color(0xFFB45309)],
              'route': '/student/history',
              'isLive': false,
            },
            {
              'title': 'Thành Tích Cá Nhân',
              'desc': 'Bộ sưu tập huy hiệu và chuỗi ngày học tập',
              'icon': Icons.emoji_events_outlined,
              'gradient': const [Color(0xFF9333EA), Color(0xFF7E22CE)],
              'route': '/student/achievements',
              'isLive': false,
            },
            {
              'title': 'Bảng Xếp Hạng',
              'desc': 'Thi đua điểm số cùng bạn học trên toàn hệ thống',
              'icon': Icons.leaderboard_outlined,
              'gradient': const [Color(0xFFDB2777), Color(0xFFBE185D)],
              'route': '/student/leaderboard',
              'isLive': false,
            },
          ]
        : [
            {
              'title': 'Tạo Đề Thi Mới',
              'desc': 'Soạn câu hỏi trắc nghiệm & ma trận đề thi',
              'icon': Icons.add_circle_outline_rounded,
              'gradient': const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              'route': '/create_exam',
              'isLive': false,
            },
            {
              'title': 'Quản Lý Đề Thi',
              'desc': 'Kho lưu trữ bài thi đã tạo và chỉnh sửa',
              'icon': Icons.folder_open_rounded,
              'gradient': const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              'route': '/teacher/exams',
              'isLive': false,
            },
            {
              'title': 'Tạo Phòng Thi',
              'desc': 'Thiết lập thời gian & sinh mã phòng cho Học sinh',
              'icon': Icons.meeting_room_outlined,
              'gradient': const [Color(0xFF059669), Color(0xFF047857)],
              'route': '/create_room',
              'isLive': false,
            },
            {
              'title': 'Phòng Đang Diễn Ra',
              'desc': 'Theo dõi tiến độ làm bài trực tiếp của Học sinh',
              'icon': Icons.sensors_rounded,
              'gradient': const [Color(0xFFDC2626), Color(0xFFB91C1C)],
              'route': '/teacher_waiting_room',
              'isLive': true,
            },
            {
              'title': 'Kết Quả Học Sinh',
              'desc': 'Xem danh sách bài nộp và thống kê điểm số',
              'icon': Icons.assessment_outlined,
              'gradient': const [Color(0xFFD97706), Color(0xFFB45309)],
              'route': '/teacher/student_results',
              'isLive': false,
            },
            {
              'title': 'Thống Kê Giảng Dạy',
              'desc': 'Phân tích phổ điểm và độ khó của từng câu hỏi',
              'icon': Icons.pie_chart_outline_rounded,
              'gradient': const [Color(0xFF9333EA), Color(0xFF7E22CE)],
              'route': '/teacher/analytics',
              'isLive': false,
            },
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 2.4 : 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildGamifiedCard(
          context: context,
          title: item['title'],
          desc: item['desc'],
          icon: item['icon'],
          gradient: item['gradient'],
          route: item['route'],
          isLive: item['isLive'],
        );
      },
    );
  }

  Widget _buildGamifiedCard({
    required BuildContext context,
    required String title,
    required String desc,
    required IconData icon,
    required List<Color> gradient,
    required String route,
    required bool isLive,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(22),
        hoverColor: Colors.white.withValues(alpha: 0.1),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          ScaleTransition(
                            scale: Tween(begin: 0.7, end: 1.2).animate(_pulseController),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF34D399),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'ĐANG MỞ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- RECENT SECTION (REAL SUPABASE DATA) ---
  Widget _buildRecentSection(BuildContext context, bool isStudent) {
    if (isStudent) {
      final tests = _studentStats.recentTests;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🕒 Bài Thi Gần Đây',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
          ),
          const SizedBox(height: 16),
          if (tests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('Chưa có lịch sử làm bài thi nào.', style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tests.length,
                itemBuilder: (context, index) {
                  final t = tests[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: ExamCard(
                      title: t.title,
                      authorName: 'Điểm: ${t.score} • ${t.date}',
                      type: ExamCardType.exam,
                      onTap: () => context.go('/exam/physics-12'),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    } else {
      final rooms = _teacherStats.recentRooms;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏛️ Phòng Thi Vừa Tạo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
          ),
          const SizedBox(height: 16),
          if (rooms.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('Chưa có phòng thi nào được tạo.', style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final r = rooms[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: ExamCard(
                      title: r.title,
                      authorName: 'Mã PT: ${r.roomCode} • ${r.studentsCount} HS',
                      type: ExamCardType.room,
                      onTap: () => context.go('/teacher_waiting_room'),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    }
  }

  // --- INFORMATION & HELP CARDS ---
  Widget _buildInfoAndHelpSection(BuildContext context, bool isStudent, bool isMobile) {
    final infoCards = [
      {
        'icon': '🔔',
        'title': 'Thông báo hệ thống',
        'desc': isStudent
            ? 'Phòng thi Vật Lý 12A1 sẽ diễn ra vào lúc 20:00 tối nay.'
            : 'Hệ thống vừa cập nhật tính năng xuất báo cáo phổ điểm Excel.',
      },
      {
        'icon': '💡',
        'title': 'Hướng dẫn sử dụng',
        'desc': isStudent
            ? 'Nhập mã phòng do GV cung cấp để vào thi ngay mà không cần tài khoản nâng cao.'
            : 'Bạn có thể giới hạn thời gian làm bài & đặt mật khẩu bảo mật cho từng phòng.',
      },
    ];

    return isMobile
        ? Column(
            children: infoCards
                .map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _buildInfoCard(c['icon']!, c['title']!, c['desc']!),
                    ))
                .toList(),
          )
        : Row(
            children: infoCards
                .map((c) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildInfoCard(c['icon']!, c['title']!, c['desc']!),
                      ),
                    ))
                .toList(),
          );
  }

  Widget _buildInfoCard(String icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEAFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM UTILITY BAR ---
  Widget _buildBottomUtilityBar(BuildContext context, AuthProvider authProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Cài Đặt Tài Khoản'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
        ),
        TextButton.icon(
          onPressed: () async {
            await authProvider.signOut();
            if (context.mounted) {
              context.go('/greeting');
            }
          },
          icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
          label: const Text('Đăng Xuất', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}
