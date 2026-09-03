import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final avatarUrl = authProvider.userAvatarUrl;

    ImageProvider? avatarImage;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        final base64Str = avatarUrl.contains(',') ? avatarUrl.split(',').last : avatarUrl;
        avatarImage = MemoryImage(base64Decode(base64Str));
      } catch (e) {
        debugPrint('Lỗi giải mã avatar TopNavBar: $e');
      }
    }

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
          Row(
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
              const SizedBox(width: 12),
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
          
          // Menu items
          Builder(
            builder: (context) {
              String currentLocation = '';
              try {
                currentLocation = GoRouterState.of(context).matchedLocation;
              } catch (_) {}
              return Row(
                children: [
                  _buildNavItem(context, 'Home', '/home', isActive: currentLocation == '/home'),
                  const SizedBox(width: 32),
                  _buildNavItem(context, 'Tìm kiếm', '/search', isActive: currentLocation == '/search'),
                  if (authProvider.isTeacher) ...[
                    const SizedBox(width: 32),
                    _buildNavItem(context, 'Tạo đề thi', '/create_exam', isActive: currentLocation == '/create_exam'),
                    const SizedBox(width: 32),
                    _buildNavItem(context, 'Quản lý đề', '/teacher_exams', isActive: currentLocation == '/teacher_exams'),
                    const SizedBox(width: 32),
                    _buildNavItem(context, 'Tạo phòng thi', '/create_room', isActive: currentLocation == '/create_room'),
                  ],
                ],
              );
            },
          ),
          
          // Right Profile Avatar Button
          Row(
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhập mã PT...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    suffixIcon: const Icon(Icons.arrow_forward, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Hướng dẫn sử dụng',
                onPressed: () => _showQuickGuide(context),
                icon: const Icon(Icons.help_outline_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  context.go('/profile');
                },
                borderRadius: BorderRadius.circular(100),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: AppTheme.border,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(Icons.person, color: AppTheme.textSecondary)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route, {bool isActive = false}) {
    return InkWell(
      onTap: () {
        if (!isActive) {
          context.go(route);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: isActive ? const Border(bottom: BorderSide(color: AppTheme.primary, width: 2)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
