import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GooglePaginationBar extends StatelessWidget {
  const GooglePaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  static List<dynamic> computePageNumbers({
    required int currentPage,
    required int totalPages,
  }) {
    if (totalPages <= 1) return [1];
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }

    if (currentPage <= 4) {
      return [1, 2, 3, 4, 5, '...', totalPages];
    }

    if (currentPage >= totalPages - 3) {
      return [
        1,
        '...',
        totalPages - 4,
        totalPages - 3,
        totalPages - 2,
        totalPages - 1,
        totalPages,
      ];
    }

    return [
      1,
      '...',
      currentPage - 1,
      currentPage,
      currentPage + 1,
      '...',
      totalPages,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = computePageNumbers(currentPage: currentPage, totalPages: totalPages);
    final hasPrev = currentPage > 1;
    final hasNext = currentPage < totalPages;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút "Trước"
              _NavButton(
                icon: Icons.chevron_left_rounded,
                label: 'Trước',
                isEnabled: hasPrev,
                onTap: hasPrev ? () => onPageChanged(currentPage - 1) : null,
              ),
              const SizedBox(width: 8),

              // Dải số trang
              ...pages.map((item) {
                if (item is int) {
                  final isCurrent = item == currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => onPageChanged(item),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isCurrent
                              ? null
                              : Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$item',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? Colors.white : AppTheme.textMain,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                }
              }),

              const SizedBox(width: 8),
              // Nút "Tiếp"
              _NavButton(
                icon: Icons.chevron_right_rounded,
                label: 'Tiếp',
                isEnabled: hasNext,
                isRightIcon: true,
                onTap: hasNext ? () => onPageChanged(currentPage + 1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onTap,
    this.isRightIcon = false,
  });

  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback? onTap;
  final bool isRightIcon;

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.4);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled ? AppTheme.primary.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          ),
          color: isEnabled ? AppTheme.primary.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRightIcon) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (isRightIcon) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
