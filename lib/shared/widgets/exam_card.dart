import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_interactive_hover_card.dart';

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
    
    return AppInteractiveHoverCard(
      borderRadius: 16,
      backgroundColor: const Color(0xF2FFFFFF),
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 280,
        height: 160,
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
                    color: isExam ? AppTheme.primaryContainer : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isExam ? 'Đề thi' : 'Phòng thi',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isExam ? AppTheme.primaryDark : const Color(0xFFB45309),
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
