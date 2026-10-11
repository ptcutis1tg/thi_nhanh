import 'package:flutter/material.dart';

import '../../../core/models/question_content_lines.dart';
import '../../../core/models/scientific_shortcut.dart';
import '../../../core/models/visual_math_block.dart';
import '../../../core/theme/app_theme.dart';
import 'inline_visual_math_editor.dart';
import 'scientific_text_field.dart';

class MultiLineQuestionEditorController {
  _MultiLineQuestionEditorState? _state;

  void insertMathBlock(MathBlockType type) => _state?._insertMathBlock(type);
}

class MultiLineQuestionEditor extends StatefulWidget {
  const MultiLineQuestionEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.controller,
    this.shortcutCategory = ScientificCategory.math,
    this.shortcuts = const [],
    this.onFocusTarget,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final MultiLineQuestionEditorController? controller;
  final ScientificCategory shortcutCategory;
  final List<ScientificShortcut> shortcuts;
  final ValueChanged<ScientificInputTarget>? onFocusTarget;

  @override
  State<MultiLineQuestionEditor> createState() =>
      _MultiLineQuestionEditorState();
}

class _QuestionLine {
  _QuestionLine(this.id, this.value)
    : controller = InlineVisualMathEditorController();

  final int id;
  String value;
  final InlineVisualMathEditorController controller;
}

class _MultiLineQuestionEditorState extends State<MultiLineQuestionEditor> {
  late List<_QuestionLine> _lines;
  late TextEditingController _rawLatexController;
  var _isRawLatexMode = false;
  var _nextId = 0;
  int? _activeLineId;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _lines = _createLines(widget.initialValue);
    _rawLatexController = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant MultiLineQuestionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?._state = this;
    final current = _isRawLatexMode
        ? _rawLatexController.text
        : QuestionContentLines.compile(_lines.map((line) => line.value));
    if (widget.initialValue != current) {
      _lines = _createLines(widget.initialValue);
      _rawLatexController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _rawLatexController.dispose();
    super.dispose();
  }

  List<_QuestionLine> _createLines(String source) => QuestionContentLines.parse(
    source,
  ).map((value) => _QuestionLine(_nextId++, value)).toList();

  void _notifyChanged() {
    widget.onChanged(
      QuestionContentLines.compile(_lines.map((line) => line.value)),
    );
  }

  void _addLine() {
    setState(() {
      final line = _QuestionLine(_nextId++, '');
      _lines.add(line);
      _activeLineId = line.id;
    });
    _notifyChanged();
  }

  void _switchMode(bool rawLatex) {
    if (_isRawLatexMode == rawLatex) return;
    setState(() {
      if (rawLatex) {
        _rawLatexController.text = QuestionContentLines.compile(
          _lines.map((line) => line.value),
        );
      } else {
        _lines = _createLines(_rawLatexController.text);
      }
      _isRawLatexMode = rawLatex;
    });
  }

  void _removeLine(int index) {
    setState(() {
      if (_lines.length == 1) {
        _lines.first.value = '';
      } else {
        _lines.removeAt(index);
      }
      _activeLineId = _lines.last.id;
    });
    _notifyChanged();
  }

  void _moveLine(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _lines.length) return;
    setState(() {
      final line = _lines.removeAt(index);
      _lines.insert(target, line);
    });
    _notifyChanged();
  }

  void _insertMathBlock(MathBlockType type) {
    final active = _lines.where((line) => line.id == _activeLineId).firstOrNull;
    (active ?? _lines.last).controller.insertMathBlock(type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModeSwitcher(),
        const SizedBox(height: 10),
        if (_isRawLatexMode)
          ScientificTextField(
            key: const Key('question-raw-latex-field'),
            initialValue: _rawLatexController.text,
            maxLines: 12,
            category: widget.shortcutCategory,
            shortcuts: widget.shortcuts,
            fieldLabel: 'Mã nguồn LaTeX câu hỏi',
            onFocused: widget.onFocusTarget,
            decoration: const InputDecoration(
              hintText:
                  r'Ví dụ: $\frac{a}{b}$ hoặc \begin{pmatrix} ... \end{pmatrix}',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _rawLatexController.text = value;
              widget.onChanged(value);
            },
          )
        else ...[
          for (var index = 0; index < _lines.length; index++) ...[
            _buildLine(index),
            if (index < _lines.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('add-question-content-line'),
            onPressed: _addLine,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm dòng'),
          ),
        ],
      ],
    );
  }

  Widget _buildModeSwitcher() {
    return Row(
      children: [
        _ModeButton(
          icon: Icons.dashboard_customize_outlined,
          label: 'Khối trực quan [ ]',
          selected: !_isRawLatexMode,
          onTap: () => _switchMode(false),
        ),
        const SizedBox(width: 8),
        _ModeButton(
          icon: Icons.code_rounded,
          label: 'Mã nguồn LaTeX',
          selected: _isRawLatexMode,
          onTap: () => _switchMode(true),
        ),
      ],
    );
  }

  Widget _buildLine(int index) {
    final line = _lines[index];
    return Container(
      key: ValueKey('question-content-line-${line.id}'),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: line.id == _activeLineId
              ? AppTheme.primary.withValues(alpha: 0.55)
              : AppTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 8),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: InlineVisualMathEditor(
              key: ValueKey('line-editor-${line.id}'),
              initialLatex: line.value,
              controller: line.controller,
              compact: true,
              showEditorFrame: false,
              textMaxLines: 1,
              shortcutCategory: widget.shortcutCategory,
              shortcuts: widget.shortcuts,
              onFocusTarget: (target) {
                if (_activeLineId != line.id) {
                  setState(() => _activeLineId = line.id);
                }
                widget.onFocusTarget?.call(target);
              },
              onChanged: (value) {
                line.value = value;
                _activeLineId = line.id;
                _notifyChanged();
              },
            ),
          ),
          IconButton(
            tooltip: 'Xóa dòng',
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeLine(index),
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
