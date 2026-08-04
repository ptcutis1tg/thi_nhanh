import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 64, color: AppTheme.border),
          const SizedBox(height: 16),
          Text(
            'Màn hình Tìm Kiếm',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text('Đây là màn hình trống dùng để test hiệu ứng trượt tab.'),
        ],
      ),
    );
  }
}
