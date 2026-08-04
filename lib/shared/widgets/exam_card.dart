import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ExamCardType {
  exam, // Đề thi
  room, // Phòng thi
}

class ExamCard extends StatelessWidget {
  final String title;
  final String authorName;
  final ExamCardType type;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const ExamCard({
    super.key,
    required this.title,
    required this.authorName,
    this.type = ExamCardType.exam,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExam = type == ExamCardType.exam;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Tag & More Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExam ? AppTheme.primary.withOpacity(0.1) : const Color(0xFFAD5500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isExam ? 'Đề thi' : 'Phòng thi',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isExam ? AppTheme.primary : const Color(0xFFAD5500),
                    ),
                  ),
                ),
                if (onMoreTap != null)
                  InkWell(
                    onTap: onMoreTap,
                    child: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            
            // Bottom Row: Author
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  authorName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
