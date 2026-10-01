import 'package:flutter/material.dart';
import '../../../core/models/question_draft.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bulk_import_parser.dart';

class QuickBulkImportDialog extends StatefulWidget {
  const QuickBulkImportDialog({super.key, required this.onImport});

  final ValueChanged<List<QuestionDraft>> onImport;

  @override
  State<QuickBulkImportDialog> createState() => _QuickBulkImportDialogState();
}

class _QuickBulkImportDialogState extends State<QuickBulkImportDialog> {
  final _textController = TextEditingController();
  List<QuestionDraft> _previewList = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {
      _previewList = BulkImportParser.parse(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.content_paste_go_rounded, color: AppTheme.primary, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Nhập nhanh câu hỏi từ văn bản',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Hướng dẫn: Dán nội dung câu hỏi bắt đầu bằng "Câu 1:", các phương án "A.", "B.", "C.", "D.". '
                  'Thêm dấu sao (*) trước đáp án đúng (ví dụ: *A. Đúng). Hỗ trợ giữ nguyên công thức \$x^2 + 1\$.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    hintText: 'Dán đề thi của bạn vào đây...\n\nVí dụ:\nCâu 1: Thủ đô của Việt Nam là gì?\n*A. Hà Nội\nB. TP. Hồ Chí Minh\nC. Đà Nẵng\nD. Cần Thơ\nLời giải: Hà Nội là thủ đô của nước CHXHCN Việt Nam.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _previewList.isNotEmpty ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Đã nhận diện: ${_previewList.length} câu hỏi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _previewList.isNotEmpty ? AppTheme.success : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _previewList.isEmpty
                        ? null
                        : () {
                            widget.onImport(_previewList);
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.check),
                    label: Text('Nhập ${_previewList.length} câu vào đề'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
