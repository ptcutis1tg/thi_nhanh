import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MobileBottomNavBar extends StatelessWidget {
  const MobileBottomNavBar({super.key});

  static const List<_NavItem> _items = [
    _NavItem(
      route: '/home',
      icon: Icons.home_rounded,
      tooltip: 'Trang chủ',
    ),
    _NavItem(
      route: '/search',
      icon: Icons.search_rounded,
      tooltip: 'Tìm đề',
    ),
    _NavItem(
      route: '/teacher_exams',
      icon: Icons.menu_book_rounded,
      tooltip: 'Quản lý đề',
    ),
    _NavItem(
      route: '/create_room',
      icon: Icons.add_circle_outline_rounded,
      tooltip: 'Tạo phòng thi',
    ),
    _NavItem(
      route: '/student/history',
      icon: Icons.history_rounded,
      tooltip: 'Lịch sử',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    String currentLocation = '';
    try {
      currentLocation = GoRouterState.of(context).matchedLocation;
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.map((item) {
              final isActive = currentLocation == item.route ||
                  (item.route == '/home' && (currentLocation.isEmpty || currentLocation == '/'));

              return Expanded(
                child: Center(
                  child: Tooltip(
                    message: item.tooltip,
                    child: InkWell(
                      onTap: () {
                        if (!isActive) {
                          context.go(item.route);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.surfaceLavender : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          item.icon,
                          size: 24,
                          color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String tooltip;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.tooltip,
  });
}
