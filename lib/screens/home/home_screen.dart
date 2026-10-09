import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/repositories/room_repository.dart';
import '../room/widgets/join_room_guest_dialog.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/developer_mode_service.dart';
import '../../core/utils/app_error_reporter.dart';
import '../../core/utils/avatar_helper.dart';
import '../../shared/widgets/exam_card.dart';

class HomeScreen extends StatefulWidget {
  final String? initialActiveAttemptId;
  final String? initialActiveExamId;
  final String? initialActiveRoomId;
  final String? initialActiveLiveRoomCode;
  final String? initialActiveLiveRoomId;
  final String? initialActiveLiveRoomStatus;

  const HomeScreen({
    super.key,
    this.initialActiveAttemptId,
    this.initialActiveExamId,
    this.initialActiveRoomId,
    this.initialActiveLiveRoomCode,
    this.initialActiveLiveRoomId,
    this.initialActiveLiveRoomStatus,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _joinRoomController = TextEditingController();
  late AnimationController _pulseController;

  String _workspaceMode = 'learning'; // 'learning' | 'authoring'
  bool _isLoadingStats = true;
  StudentProfileData _studentStats = StudentProfileData.empty();
  TeacherProfileData _teacherStats = TeacherProfileData.empty();

  String? _activeAttemptId;
  String? _activeExamId;
  String? _activeRoomId;
  int _inProgressCount = 0;
  int _totalUnfinishedCount = 0;
  String? _activeLiveRoomCode;
  String? _activeLiveRoomId;
  String? _activeLiveRoomStatus;

  @override
  void initState() {
    super.initState();
    _activeAttemptId = widget.initialActiveAttemptId;
    _activeExamId = widget.initialActiveExamId;
    _activeRoomId = widget.initialActiveRoomId;
    _activeLiveRoomCode = widget.initialActiveLiveRoomCode;
    _activeLiveRoomId = widget.initialActiveLiveRoomId;
    _activeLiveRoomStatus = widget.initialActiveLiveRoomStatus;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadWorkspaceMode();
    _loadDashboardData();
  }

  Future<void> _loadWorkspaceMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('active_workspace_mode');
      if (mode != null && mounted) {
        setState(() => _workspaceMode = mode);
      }
    } catch (_) {}
  }

  Future<void> _setWorkspaceMode(String mode) async {
    if (_workspaceMode == mode) return;
    setState(() => _workspaceMode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_workspace_mode', mode);
    } catch (_) {}
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
    final teacherDataFuture = ProfileService.fetchTeacherDataSecure(
      userId: authProvider.user?.id,
      userEmail: authProvider.userEmail,
      userName: authProvider.userName,
    );
    final activeAttemptFuture = ProfileService.fetchActiveAttempt(
      userId: authProvider.user?.id,
      userEmail: authProvider.userEmail,
    );
    final activeLiveRoomFuture = ProfileService.fetchActiveLiveRoom(
      userId: authProvider.user?.id,
      userEmail: authProvider.userEmail,
      userName: authProvider.userName,
    );

    final results = await Future.wait([
      studentDataFuture,
      teacherDataFuture,
      activeAttemptFuture,
      activeLiveRoomFuture,
    ]);

    if (mounted) {
      final activeAttempt = results[2] as Map<String, dynamic>?;
      final activeLiveRoom = results[3] as Map<String, String?>?;

      setState(() {
        _studentStats = results[0] as StudentProfileData;
        _teacherStats = results[1] as TeacherProfileData;
        if (widget.initialActiveAttemptId == null && activeAttempt != null) {
          _activeAttemptId = activeAttempt['attemptId']?.toString();
          _activeExamId = activeAttempt['examId']?.toString();
          _activeRoomId = activeAttempt['roomId']?.toString();
          _inProgressCount = (activeAttempt['inProgressCount'] as num?)?.toInt() ?? 0;
          _totalUnfinishedCount = (activeAttempt['totalUnfinishedCount'] as num?)?.toInt() ?? 0;
        }
        if (_totalUnfinishedCount == 0 && _studentStats.inProgressTests.isNotEmpty) {
          _totalUnfinishedCount = _studentStats.inProgressTests.length;
          _inProgressCount = _studentStats.inProgressTests.where((t) => !t.isExpired).length;
        }
        if (widget.initialActiveLiveRoomCode == null && activeLiveRoom != null) {
          _activeLiveRoomCode = activeLiveRoom['code'];
          _activeLiveRoomId = activeLiveRoom['roomId'];
          _activeLiveRoomStatus = activeLiveRoom['status'];
        }
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

  Future<void> _handleJoinRoom() async {
    final rawCode = _joinRoomController.text.trim();
    if (rawCode.isEmpty) {
      AppErrorReporter.showErrorSnackBar(context, 'Vui lòng nhập mã phòng');
      return;
    }

    // Kiểm tra mã bí mật kích hoạt chế độ nhà phát triển (18366767, 67676767)
    DeveloperModeService? devService;
    try {
      devService = context.read<DeveloperModeService>();
    } catch (_) {
      devService = null;
    }

    if (devService != null) {
      try {
        final isSecret = await devService.handleRoomCode(rawCode);
        if (isSecret) {
          _joinRoomController.clear();
          return;
        }
      } catch (_) {}
    }

    final code = AppErrorReporter.normalizeRoomCode(rawCode);
    if (!mounted) return;

    AuthProvider? authProvider;
    try {
      authProvider = context.read<AuthProvider>();
    } catch (_) {
      authProvider = null;
    }

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

    // Kiểm tra thông minh: Nếu tài khoản hiện tại là chủ tạo phòng -> điều hướng vào TeacherWaitingRoom
    try {
      final hostedRoomId = await roomRepo.findHostedRoomId(code);
      if (hostedRoomId != null && mounted) {
        _joinRoomController.clear();
        context.go('/teacher_waiting_room?roomId=$hostedRoomId');
        return;
      }
    } catch (_) {}

    if (!mounted) return;

    final isAuth = authProvider?.isAuthenticated ?? false;
    if (!isAuth) {
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
            if (mounted) {
              _joinRoomController.clear();
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
        if (mounted) {
          _joinRoomController.clear();
          context.go(
            '/student_waiting_room?roomId=${result.roomId}&participantId=${result.participantId}',
          );
        }
      } catch (e) {
        if (!mounted) return;
        final errorMsg = AppErrorReporter.formatErrorMessage(e, roomCode: rawCode);
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
                if (mounted) {
                  _joinRoomController.clear();
                  context.go(
                    '/student_waiting_room?roomId=${result.roomId}&participantId=${result.participantId}',
                  );
                }
              },
            ),
          );
        } else {
          AppErrorReporter.showErrorSnackBar(context, errorMsg, error: e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isStudent = _workspaceMode == 'learning';
    final avatarUrl = authProvider.userAvatarUrl;
    final avatarImage = parseAvatarImage(avatarUrl);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC), // Stitch clean paper background
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
                // 1. HERO BANNER (Stitch Violet Gradient + User Profile + Embedded Capsule Mode Switcher)
                _buildHeroBanner(context, authProvider, avatarImage, isMobile),

                const SizedBox(height: 24),

                // 2. SMART NAVIGATION GRID (Stitch Screen 2: Active Attempt Card & Live Room Card with Quick Room Entry)
                _buildSmartNavGrid(context, isMobile),

                const SizedBox(height: 28),

                // 3. SUBJECT CHIPS SECTION (Student Mode)
                if (isStudent) ...[
                  _buildSubjectChipsSection(context),
                  const SizedBox(height: 28),
                ],

                // 4. QUICK STATS BAR (REAL SUPABASE DATA)
                _buildQuickStatsBar(isStudent, isMobile),

                const SizedBox(height: 32),

                // 5. MAIN SECTION TITLE
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
                      isStudent ? 'Chế độ Học tập & Thi thử' : 'Chế độ Soạn đề & Quản lý',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. MAIN FEATURE CARDS GRID (6 Gamified Cards)
                _buildFeatureCardsGrid(context, isStudent, isMobile),

                const SizedBox(height: 40),

                // 7. RECENT ACTIVITY SECTION (REAL SUPABASE DATA)
                _buildRecentSection(context, isStudent),

                const SizedBox(height: 40),

                // 8. NOTIFICATIONS & GUIDES SECTION
                _buildInfoAndHelpSection(context, isStudent, isMobile),

                const SizedBox(height: 32),

                // 9. BOTTOM UTILITY BAR
                _buildBottomUtilityBar(context, authProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. HERO BANNER (STITCH DEEP VIOLET GRADIENT & EMBEDDED WORKSPACE CAPSULE) ---
  Widget _buildHeroBanner(
    BuildContext context,
    AuthProvider authProvider,
    ImageProvider? avatarImage,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6557E8), // Stitch Primary Violet
            Color(0xFF4C3BCE), // Deep Violet
            Color(0xFF3828A8), // Rich Indigo Violet
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x336557E8),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoRow(authProvider, avatarImage),
                const SizedBox(height: 18),
                _buildWorkspaceModeSwitcher(isMobile),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildUserInfoRow(authProvider, avatarImage),
                ),
                const SizedBox(width: 24),
                _buildWorkspaceModeSwitcher(isMobile),
              ],
            ),
    );
  }

  Widget _buildUserInfoRow(AuthProvider authProvider, ImageProvider? avatarImage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: avatarImage,
            onBackgroundImageError: avatarImage != null ? (e, s) {} : null,
            child: avatarImage == null
                ? const Icon(Icons.person, size: 30, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xin chào, ${authProvider.userName} 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Tài khoản Toàn quyền',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- EMBEDDED WORKSPACE MODE SWITCHER (CAPSULE PILL) ---
  Widget _buildWorkspaceModeSwitcher(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _buildCapsuleTab(
            mode: 'learning',
            title: '🎓 Học tập & Thi thử',
            isSelected: _workspaceMode == 'learning',
            isMobile: isMobile,
          ),
          const SizedBox(width: 4),
          _buildCapsuleTab(
            mode: 'authoring',
            title: '📝 Soạn đề & Quản lý',
            isSelected: _workspaceMode == 'authoring',
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleTab({
    required String mode,
    required String title,
    required bool isSelected,
    required bool isMobile,
  }) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 18,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.9),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return isMobile
        ? Expanded(
            child: InkWell(
              onTap: () => _setWorkspaceMode(mode),
              borderRadius: BorderRadius.circular(100),
              child: content,
            ),
          )
        : InkWell(
            onTap: () => _setWorkspaceMode(mode),
            borderRadius: BorderRadius.circular(100),
            child: content,
          );
  }

  // --- 2. SMART NAVIGATION GRID (STITCH SCREEN 2: 2 CARDS) ---
  Widget _buildSmartNavGrid(BuildContext context, bool isMobile) {
    return isMobile
        ? Column(
            children: [
              _buildActiveAttemptCard(context),
              const SizedBox(height: 16),
              _buildLiveRoomCard(context),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildActiveAttemptCard(context)),
              const SizedBox(width: 20),
              Expanded(child: _buildLiveRoomCard(context)),
            ],
          );
  }

  Widget _buildActiveAttemptCard(BuildContext context) {
    final unfinishedCount = _totalUnfinishedCount > 0
        ? _totalUnfinishedCount
        : (_activeAttemptId != null && _activeAttemptId!.isNotEmpty ? 1 : 0);
    final hasActive = unfinishedCount > 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasActive ? const Color(0xFFFDE68A) : AppTheme.border,
          width: hasActive ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasActive ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: hasActive ? const Color(0xFFD97706) : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasActive
                          ? 'BÀI THI CHƯA HOÀN TẤT ($unfinishedCount)'
                          : 'TIẾN ĐỘ HỌC TẬP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasActive ? const Color(0xFFB45309) : AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActive)
                ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.15).animate(_pulseController),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasActive
                ? (unfinishedCount > 1
                    ? 'Bạn đang có $unfinishedCount bài thi chưa nộp'
                    : 'Bạn đang có bài thi chưa nộp')
                : 'Không có bài thi dở dang',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasActive
                ? 'Hệ thống đã tự động lưu lại tiến trình bài làm. Bạn có thể xem danh sách và tiếp tục bất cứ lúc nào.'
                : 'Mọi tiến trình thi sẽ tự động được lưu nháp để bạn có thể làm tiếp bất cứ lúc nào.',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _onCardTap('Bài Đang Làm', '/student/history?tab=in_progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasActive ? const Color(0xFFD97706) : AppTheme.surfaceLavender,
                foregroundColor: hasActive ? Colors.white : AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: hasActive ? BorderSide.none : const BorderSide(color: Color(0xFFE9E4FA)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasActive ? 'Xem bài dở dang' : 'Khám phá đề thi',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRoomCard(BuildContext context) {
    final hasActiveRoom = _activeLiveRoomCode != null && _activeLiveRoomCode!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasActiveRoom ? const Color(0xFFA7F3D0) : AppTheme.border,
          width: hasActiveRoom ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasActiveRoom ? const Color(0xFFD1FAE5) : const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasActiveRoom ? Icons.sensors_rounded : Icons.meeting_room_outlined,
                      size: 14,
                      color: hasActiveRoom ? const Color(0xFF059669) : AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasActiveRoom ? 'PHÒNG THI ĐANG MỞ' : 'PHÒNG THI TRỰC TIẾP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasActiveRoom ? const Color(0xFF047857) : AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveRoom)
                ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.15).animate(_pulseController),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasActiveRoom ? 'Phòng thi $_activeLiveRoomCode đang trực tiếp' : 'Vào phòng thi nhanh với mã PIN',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasActiveRoom
                ? 'Giáo viên đang mở phòng thi. Nhập mã phòng hoặc bấm để tham gia phòng chờ.'
                : 'Nhập mã phòng do Thầy/Cô cung cấp để vào phòng thi trực tiếp.',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _buildQuickRoomInput(),
        ],
      ),
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
          const SizedBox(width: 14),
          const Icon(Icons.tag_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _joinRoomController,
              onSubmitted: (_) => _handleJoinRoom(),
              style: const TextStyle(
                fontFamily: 'FiraCode',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
              ),
              decoration: const InputDecoration(
                hintText: 'Nhập mã phòng PTxxxxxx...',
                hintStyle: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _handleJoinRoom,
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

  // --- 3. SUBJECT CHIPS SECTION ---
  Widget _buildSubjectChipsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📚 Danh Mục Môn Học',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
              ),
            ),
            Text(
              '8 Môn Chuẩn GDPT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSubjectChipsRow(context),
      ],
    );
  }

  Widget _buildSubjectChipsRow(BuildContext context) {
    final subjects = [
      {'name': 'Toán học', 'icon': '🧮'},
      {'name': 'Vật lý', 'icon': '⚛️'},
      {'name': 'Hóa học', 'icon': '🧪'},
      {'name': 'Tiếng Anh', 'icon': '🌐'},
      {'name': 'Sinh học', 'icon': '🧬'},
      {'name': 'Lịch sử', 'icon': '🏛️'},
      {'name': 'Địa lý', 'icon': '🗺️'},
      {'name': 'Ngữ văn', 'icon': '📚'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: subjects.map((sub) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => context.go('/search?subject=${Uri.encodeComponent(sub['name']!)}'),
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sub['icon']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      sub['name']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- 4. QUICK STATS BAR (REAL DATA) ---
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

  // --- 5. FEATURE CARDS GRID ---
  Widget _buildFeatureCardsGrid(BuildContext context, bool isStudent, bool isMobile) {
    final List<Map<String, dynamic>> items = isStudent
        ? [
            {
              'title': 'Tìm Đề Luyện Tập',
              'desc': 'Khám phá hàng ngàn đề trắc nghiệm chuẩn cấu trúc',
              'icon': Icons.search_rounded,
              'gradient': const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              'route': '/search',
              'isLive': false,
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
              'desc': _activeLiveRoomCode != null
                  ? 'Phòng $_activeLiveRoomCode đang mở - Bấm để giám sát'
                  : 'Theo dõi tiến độ làm bài trực tiếp của Học sinh',
              'icon': Icons.sensors_rounded,
              'gradient': const [Color(0xFFDC2626), Color(0xFFB91C1C)],
              'route': '/teacher_waiting_room',
              'isLive': _activeLiveRoomCode != null,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (isMobile) {
          crossAxisCount = 1;
          childAspectRatio = 2.4;
        } else if (items.length == 4) {
          if (constraints.maxWidth >= 950) {
            crossAxisCount = 4;
            childAspectRatio = 1.35;
          } else {
            crossAxisCount = 2;
            childAspectRatio = 1.9;
          }
        } else {
          crossAxisCount = 3;
          childAspectRatio = 1.6;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: childAspectRatio,
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
      },
    );
  }

  void _onCardTap(String title, String defaultRoute) {
    if (title == 'Bài Đang Làm') {
      final unfinishedCount = _totalUnfinishedCount > 0
          ? _totalUnfinishedCount
          : (_activeAttemptId != null && _activeAttemptId!.isNotEmpty ? 1 : 0);
      if (unfinishedCount > 0) {
        context.go('/student/history?tab=in_progress');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có bài thi nào đang làm dở dang. Chuyển sang tìm đề luyện tập.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/search');
      }
      return;
    }

    if (title == 'Phòng Đang Diễn Ra') {
      if (_activeLiveRoomCode != null && _activeLiveRoomCode!.isNotEmpty) {
        if (_activeLiveRoomStatus == 'waiting' && _activeLiveRoomId != null) {
          context.go('/teacher_waiting_room?roomId=$_activeLiveRoomId');
        } else {
          context.go('/live_dashboard?code=$_activeLiveRoomCode');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hiện không có phòng thi nào đang diễn ra. Chuyển sang tạo phòng mới.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/create_room');
      }
      return;
    }

    context.go(defaultRoute);
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
        onTap: () => _onCardTap(title, route),
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

  // --- 6. RECENT SECTION (REAL SUPABASE DATA) ---
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
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
                      onTap: () => context.go('/result?attemptId=${Uri.encodeComponent(t.id)}'),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
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
                      onTap: () => context.go('/teacher_waiting_room?roomId=${Uri.encodeComponent(r.id)}'),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    }
  }

  // --- 7. INFORMATION & HELP CARDS ---
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

  // --- 8. BOTTOM UTILITY BAR ---
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
