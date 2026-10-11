import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EditExamInfoDialog extends StatefulWidget {
  final String initialTitle;
  final String initialSubject;
  final int initialDurationMinutes;
  final void Function(String newTitle, String newSubject, int newDurationMinutes) onSave;

  const EditExamInfoDialog({
    super.key,
    required this.initialTitle,
    required this.initialSubject,
    required this.initialDurationMinutes,
    required this.onSave,
  });

  @override
  State<EditExamInfoDialog> createState() => _EditExamInfoDialogState();
}

class _EditExamInfoDialogState extends State<EditExamInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late String _selectedSubject;

  static const List<String> subjects = [
    'none',
    'Toán',
    'Ngữ văn',
    'Tiếng Anh',
    'Vật lý',
    'Hóa học',
    'Sinh học',
    'Lịch sử',
    'Địa lý',
    'Giáo dục công dân',
    'Tin học',
    'Công nghệ',
    'Khoa học tự nhiên',
    'Lịch sử & Địa lý',
    'Ngoại ngữ khác',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _durationController = TextEditingController(text: widget.initialDurationMinutes.toString());
    _selectedSubject = widget.initialSubject.isEmpty ? 'none' : widget.initialSubject;
    if (!subjects.contains(_selectedSubject)) {
      _selectedSubject = 'none';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final newTitle = _titleController.text.trim();
      final newDuration = int.tryParse(_durationController.text.trim()) ?? widget.initialDurationMinutes;
      widget.onSave(newTitle, _selectedSubject, newDuration);
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Chỉnh sửa thông tin đề thi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('edit-exam-title'),
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Tên đề thi *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.inputRadius)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Tên đề thi phải có ít nhất 3 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('edit-exam-subject'),
                  initialValue: _selectedSubject,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Môn học',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.inputRadius)),
                  ),
                  items: subjects.map((sub) {
                    return DropdownMenuItem(
                      value: sub,
                      child: Text(sub == 'none' ? 'Không phân loại (none)' : sub),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSubject = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('edit-exam-duration'),
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Thời lượng (phút) *',
                    suffixText: 'phút',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.inputRadius)),
                  ),
                  validator: (value) {
                    final d = int.tryParse(value ?? '');
                    if (d == null || d < 1 || d > 360) {
                      return 'Thời lượng từ 1 đến 360 phút';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      key: const Key('edit-exam-save'),
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Cập nhật'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
