import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/avatar_helper.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final avatarUrl = authProvider.userAvatarUrl;

    final avatarImage = parseAvatarImage(avatarUrl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1100;
        final isVeryCompact = constraints.maxWidth < 850;

        return Container(
          height: 72,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 28),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Title
              InkWell(
                onTap: () => context.go('/home'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Thi Nhanh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items (All 5 core features available for all users)
              Expanded(
                child: Builder(
                  builder: (context) {
                    String currentLocation = '';
                    try {
                      currentLocation = GoRouterState.of(context).matchedLocation;
                    } catch (_) {}

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 8),
                          _buildNavItem(context, 'Home', '/home', isActive: currentLocation == '/home', isCompact: isCompact),
                          _buildNavItem(context, 'Tìm kiếm', '/search', isActive: currentLocation == '/search', isCompact: isCompact),
                          _buildNavItem(context, 'Tạo đề thi', '/create_exam', isActive: currentLocation == '/create_exam', isCompact: isCompact),
                          _buildNavItem(context, 'Đề của tôi', '/teacher_exams', isActive: currentLocation == '/teacher_exams', isCompact: isCompact),
                          _buildNavItem(context, 'Tạo phòng thi', '/create_room', isActive: currentLocation == '/create_room', isCompact: isCompact),
                          const SizedBox(width: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Right Profile & Quick Room Input
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isVeryCompact)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isCompact ? 130 : 160),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Nhập mã PT...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          suffixIcon: const Icon(Icons.arrow_forward, size: 16),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Hướng dẫn sử dụng',
                    onPressed: () => _showQuickGuide(context),
                    icon: const Icon(Icons.help_outline_rounded, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      context.go('/profile');
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.border,
                      backgroundImage: avatarImage,
                      onBackgroundImageError: avatarImage != null ? (e, s) {} : null,
                      child: avatarImage == null
                          ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 18)
                          : null,
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

  Widget _buildNavItem(BuildContext context, String title, String route, {bool isActive = false, bool isCompact = false}) {
    return InkWell(
      onTap: () {
        if (!isActive) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: 6),
        decoration: BoxDecoration(
          border: isActive ? const Border(bottom: BorderSide(color: AppTheme.primary, width: 2)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: isCompact ? 14 : 15,
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
