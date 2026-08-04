import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Thi Nhanh',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          
          // Center Navigation
          Row(
            children: [
              _buildNavItem('Home', isActive: true),
              _buildNavItem('Tìm kiếm'),
              _buildNavItem('Tạo đề thi'),
              _buildNavItem('Tạo phòng thi'),
            ],
          ),
          
          // Right Actions
          Row(
            children: [
              SizedBox(
                width: 180,
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhập mã PT... hoặc DT...',
                    hintStyle: const TextStyle(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    suffixIcon: const Icon(Icons.arrow_forward, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 21,
                backgroundColor: AppTheme.border,
                child: Icon(Icons.person, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, {bool isActive = false}) {
    return Container(
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
    );
  }
}
