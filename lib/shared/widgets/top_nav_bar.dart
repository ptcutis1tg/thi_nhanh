import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/repositories/room_repository.dart';
import '../../core/services/developer_mode_service.dart';
import '../../core/utils/app_error_reporter.dart';
import '../../core/utils/avatar_helper.dart';
import '../../screens/room/widgets/join_room_guest_dialog.dart';

class TopNavBar extends StatefulWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  static const Set<String> _coreTabRoutes = {
    '/home',
    '/',
    '/search',
    '/teacher_exams',
    '/create_room',
    '/student/history',
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final avatarUrl = authProvider.userAvatarUrl;
    final avatarImage = parseAvatarImage(avatarUrl);

    String currentLocation = '';
    try {
      currentLocation = GoRouterState.of(context).matchedLocation;
    } catch (_) {}
    final isCoreTab = _coreTabRoutes.contains(currentLocation) || currentLocation.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1100;
        final isVeryCompact = constraints.maxWidth < 850;
        final isMobile = constraints.maxWidth < 600;

        return Container(
          height: isMobile ? 58 : 72,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : (isCompact ? 16 : 28)),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: const Border(
              bottom: BorderSide(color: AppTheme.border, width: 1),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Back button (if on sub-screen on mobile) or Logo & Title
              if (isMobile && !isCoreTab) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain, size: 22),
                      tooltip: 'Quay lại',
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => context.go('/home'),
                      child: const Text(
                        'Thi Nhanh',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Logo & Title
                InkWell(
                  onTap: () => context.go('/home'),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isMobile ? 32 : 36,
                        height: isMobile ? 32 : 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x336557E8),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: isMobile ? 18 : 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Thi Nhanh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Middle Menu items (Only on desktop / tablet)
              if (!isMobile)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        _buildNavItem(context, 'Home', '/home', isActive: currentLocation == '/home', isCompact: isCompact),
                        _buildNavItem(context, 'Tìm kiếm', '/search', isActive: currentLocation == '/search', isCompact: isCompact),
                        _buildNavItem(context, 'Quản lí đề', '/teacher_exams', isActive: currentLocation == '/teacher_exams', isCompact: isCompact),
                        _buildNavItem(context, 'Tạo phòng thi', '/create_room', isActive: currentLocation == '/create_room', isCompact: isCompact),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),

              // Right Profile & Quick Room Input
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMobile) ...[
                    IconButton(
                      tooltip: 'Vào phòng thi nhanh',
                      icon: const Icon(Icons.pin_outlined, color: AppTheme.primary, size: 22),
                      onPressed: () => _showQuickJoinModal(context),
                    ),
                  ] else if (!isVeryCompact) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isCompact ? 135 : 170),
                      child: TextField(
                        controller: _roomCodeController,
                        onSubmitted: (code) => _handleQuickJoinRoom(context, code),
                        style: AppTheme.firaCodeStyle.copyWith(
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã PT...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textPlaceholder),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                          suffixIcon: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _handleQuickJoinRoom(context, _roomCodeController.text),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                margin: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  if (!isMobile)
                    IconButton(
                      tooltip: 'Hướng dẫn sử dụng',
                      onPressed: () => _showQuickGuide(context),
                      icon: const Icon(Icons.help_outline_rounded, color: AppTheme.primary, size: 22),
                    ),
                  const SizedBox(width: 6),
                  if (!authProvider.isAuthenticated)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: isMobile
                          ? IconButton(
                              onPressed: () => context.go('/greeting'),
                              icon: const Icon(Icons.login_rounded, color: AppTheme.primary),
                              tooltip: 'Đăng nhập',
                            )
                          : ElevatedButton.icon(
                              onPressed: () => context.go('/greeting'),
                              icon: const Icon(Icons.login_rounded, size: 16),
                              label: const Text(
                                'Đăng nhập',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                              ),
                            ),
                    )
                  else
                    PopupMenuButton<String>(
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tooltip: 'Tài khoản',
                      onSelected: (value) async {
                        if (value == 'profile') {
                          context.go('/profile');
                        } else if (value == 'history') {
                          context.go('/student/history');
                        } else if (value == 'created_rooms') {
                          context.go('/teacher/rooms');
                        } else if (value == 'logout') {
                          await authProvider.signOut();
                          if (context.mounted) context.go('/greeting');
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.primary),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Hồ sơ cá nhân', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: Row(
                            children: [
                              Icon(Icons.history_edu_rounded, size: 20, color: AppTheme.primary),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Lịch sử làm bài', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'created_rooms',
                          child: Row(
                            children: [
                              Icon(Icons.meeting_room_outlined, size: 20, color: AppTheme.primary),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Phòng thi đã tạo', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 20, color: AppTheme.error),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Đăng xuất', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryLight, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: AppTheme.border,
                          backgroundImage: avatarImage,
                          onBackgroundImageError: avatarImage != null ? (e, s) {} : null,
                          child: avatarImage == null
                              ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 18)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickJoinModal(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.meeting_room_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Vào phòng thi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã PIN phòng thi để tham gia ngay:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTheme.firaCodeStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'VD: PT067664...',
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (val) {
                Navigator.pop(dialogCtx);
                _handleQuickJoinRoom(context, val);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text;
              Navigator.pop(dialogCtx);
              _handleQuickJoinRoom(context, code);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }

  void _showGuestRestrictedDialog(BuildContext context, String featureName) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Yêu cầu đăng nhập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Tính năng "$featureName" yêu cầu đăng nhập để lưu trữ dữ liệu cá nhân của bạn. Bạn có muốn đăng nhập hoặc tạo tài khoản ngay bây giờ không?',
          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Để sau', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.go('/greeting');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Đăng nhập ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route, {bool isActive = false, bool isCompact = false}) {
    final requiresAuth = route == '/create_exam' || route == '/teacher_exams' || route == '/create_room';

    return InkWell(
      onTap: () {
        if (!isActive) {
          final isAuth = context.read<AuthProvider>().isAuthenticated;
          if (requiresAuth && !isAuth) {
            _showGuestRestrictedDialog(context, title);
            return;
          }
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: isCompact ? 3 : 6),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.surfaceLavender : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: isActive
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.25), width: 1.2)
              : Border.all(color: Colors.transparent, width: 1.2),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showQuickGuide(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Hướng dẫn nhanh'),
          ],
        ),
        content: const SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideItem(
                icon: Icons.menu_book_outlined,
                title: 'Đề tự luyện',
                description: 'Bạn có thể làm bất cứ lúc nào. Đáp án được tự lưu và xem kết quả ngay sau khi nộp bài.',
              ),
              SizedBox(height: 18),
              _GuideItem(
                icon: Icons.groups_outlined,
                title: 'Phòng thi trực tiếp',
                description: 'Bạn vào bằng mã hoặc liên kết giáo viên gửi. Bài thi chỉ bắt đầu khi giáo viên mở phòng và điểm được công bố khi phòng kết thúc.',
              ),
              SizedBox(height: 18),
              _GuideItem(
                icon: Icons.switch_account_outlined,
                title: 'Đổi vai trò',
                description: 'Mở hồ sơ ở góc phải để chọn Học sinh hoặc Giáo viên. Giáo viên mới thấy mục tạo đề và tạo phòng thi.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuickJoinRoom(BuildContext context, String rawCode) async {
    final trimmedRaw = rawCode.trim();
    if (trimmedRaw.isEmpty) return;

    // Kiểm tra mã bí mật kích hoạt chế độ nhà phát triển (18366767, 67676767)
    DeveloperModeService? devService;
    try {
      devService = context.read<DeveloperModeService>();
    } catch (_) {
      devService = null;
    }

    if (devService != null) {
      try {
        final isSecret = await devService.handleRoomCode(trimmedRaw);
        if (isSecret) {
          _roomCodeController.clear();
          return;
        }
      } catch (_) {}
    }

    final code = AppErrorReporter.normalizeRoomCode(rawCode);
    if (code.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    RoomRepository? roomRepo;
    try {
      roomRepo = context.read<RoomRepository>();
    } catch (_) {
      roomRepo = null;
    }

    if (roomRepo == null) return;

    if (authProvider.isAuthenticated) {
      try {
        final hostedRoomId = await roomRepo.findHostedRoomId(code);
        if (hostedRoomId != null && context.mounted) {
          _roomCodeController.clear();
          context.go('/teacher_waiting_room?roomId=$hostedRoomId');
          return;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

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
              _roomCodeController.clear();
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
          _roomCodeController.clear();
          context.go(
            '/student_waiting_room?roomId=${result.roomId}&participantId=${result.participantId}',
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        final errorMsg = AppErrorReporter.formatErrorMessage(e, roomCode: rawCode.trim());
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
                  _roomCodeController.clear();
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
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textMain)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
            ]),
          ),
        ],
      );
}
