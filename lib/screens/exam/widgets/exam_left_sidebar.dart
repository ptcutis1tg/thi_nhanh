import 'package:flutter/material.dart';
import '../../../core/models/question_draft.dart';
import '../../../core/theme/app_theme.dart';

class ExamLeftSidebar extends StatelessWidget {
  const ExamLeftSidebar({
    super.key,
    required this.questions,
    required this.activeIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onDuplicate,
    required this.onDelete,
    required this.onReorder,
    required this.onOpenBulkImport,
  });

  final List<QuestionDraft> questions;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<int> onDuplicate;
  final ValueChanged<int> onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onOpenBulkImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DANH SÁCH CÂU HỎI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${questions.length} câu hỏi',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Nhập nhanh từ văn bản',
                  onPressed: onOpenBulkImport,
                  icon: const Icon(Icons.playlist_add_rounded, color: AppTheme.primary, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Reorderable Question List
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: questions.length,
              onReorder: (oldIdx, newIdx) {
                if (newIdx > oldIdx) newIdx -= 1;
                onReorder(oldIdx, newIdx);
              },
              itemBuilder: (context, index) {
                final q = questions[index];
                final active = index == activeIndex;
                final previewTitle = q.body.trim().isEmpty ? 'Câu hỏi số ${index + 1}' : q.body.trim();

                return Container(
                  key: ValueKey('question-item-${q.id}-$index'),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
                    border: Border.all(
                      color: active ? AppTheme.primary : AppTheme.border,
                      width: active ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSelect(index),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            // Drag handle
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_indicator, size: 18, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            // Number badge
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: active ? AppTheme.primary : AppTheme.border,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: active ? Colors.white : AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Title & Type badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    previewTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                      color: active ? AppTheme.primary : AppTheme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          q.type.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (q.timeLimitSeconds != null)
                                        Text(
                                          '${q.timeLimitSeconds}s',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.warning),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Quick Action buttons
                            IconButton(
                              tooltip: 'Nhân bản câu này',
                              onPressed: () => onDuplicate(index),
                              icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'Xóa câu này',
                              onPressed: questions.length <= 1 ? null : () => onDelete(index),
                              icon: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: questions.length <= 1 ? Colors.grey.shade300 : AppTheme.error,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Add Question button
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              key: const Key('add-question'),
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm câu hỏi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
