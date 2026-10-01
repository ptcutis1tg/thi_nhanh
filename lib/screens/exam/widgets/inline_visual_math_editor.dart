import 'package:flutter/material.dart';
import '../../../core/models/visual_math_block.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/visual_math_compiler.dart';
import 'visual_math_block_widget.dart';

class InlineVisualMathEditorController {
  _InlineVisualMathEditorState? _state;

  void insertMathBlock(MathBlockType type) {
    _state?.insertMathBlock(type);
  }
}

class InlineVisualMathEditor extends StatefulWidget {
  const InlineVisualMathEditor({
    super.key,
    required this.initialLatex,
    required this.onChanged,
    this.controller,
  });

  final String initialLatex;
  final ValueChanged<String> onChanged;
  final InlineVisualMathEditorController? controller;

  @override
  State<InlineVisualMathEditor> createState() => _InlineVisualMathEditorState();
}

class _InlineVisualMathEditorState extends State<InlineVisualMathEditor> {
  bool _isVisualMode = true;
  late List<QuestionContentSegment> _segments;
  late TextEditingController _rawLatexController;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _segments = VisualMathCompiler.parse(widget.initialLatex);
    _rawLatexController = TextEditingController(text: widget.initialLatex);
  }

  @override
  void didUpdateWidget(InlineVisualMathEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      widget.controller!._state = this;
    }
    if (oldWidget.initialLatex != widget.initialLatex) {
      final currentCompiled = VisualMathCompiler.compile(_segments);
      if (widget.initialLatex != currentCompiled) {
        _segments = VisualMathCompiler.parse(widget.initialLatex);
        _rawLatexController.text = widget.initialLatex;
      }
    }
  }

  @override
  void dispose() {
    _rawLatexController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final latex = _isVisualMode
        ? VisualMathCompiler.compile(_segments)
        : _rawLatexController.text;
    widget.onChanged(latex);
  }

  void insertMathBlock(MathBlockType type) {
    setState(() {
      final newBlock = MathBlockSegment(
        id: 'mb_${DateTime.now().microsecondsSinceEpoch}',
        type: type,
      );
      _segments.add(newBlock);
      _segments.add(TextContentSegment(' '));
      _rawLatexController.text = VisualMathCompiler.compile(_segments);
    });
    _notifyChange();
  }

  void _switchMode(bool toVisual) {
    if (_isVisualMode == toVisual) return;
    setState(() {
      if (toVisual) {
        // Sync raw LaTeX back into segments
        _segments = VisualMathCompiler.parse(_rawLatexController.text);
      } else {
        // Sync segments to raw LaTeX
        _rawLatexController.text = VisualMathCompiler.compile(_segments);
      }
      _isVisualMode = toVisual;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Switcher Header
        Row(
          children: [
            InkWell(
              onTap: () => _switchMode(true),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isVisualMode ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isVisualMode ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dashboard_customize_outlined, size: 14, color: _isVisualMode ? AppTheme.primary : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Khối trực quan [ ]',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isVisualMode ? FontWeight.bold : FontWeight.w500,
                        color: _isVisualMode ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _switchMode(false),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: !_isVisualMode ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: !_isVisualMode ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code_rounded, size: 14, color: !_isVisualMode ? AppTheme.primary : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Mã nguồn LaTeX',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isVisualMode ? FontWeight.bold : FontWeight.w500,
                        color: !_isVisualMode ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Editor Body
        if (!_isVisualMode)
          TextFormField(
            controller: _rawLatexController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: r'Nhập công thức dạng \frac{a}{b} hoặc văn bản...',
            ),
            onChanged: (val) => _notifyChange(),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < _segments.length; i++)
                  if (_segments[i] is TextContentSegment)
                    _buildTextSegmentWidget(i, _segments[i] as TextContentSegment)
                  else if (_segments[i] is MathBlockSegment)
                    VisualMathBlockWidget(
                      key: ValueKey((_segments[i] as MathBlockSegment).id),
                      block: _segments[i] as MathBlockSegment,
                      onSlotChanged: (k, v) {
                        (_segments[i] as MathBlockSegment).slots[k] = v;
                        _notifyChange();
                      },
                      onDelete: () {
                        setState(() {
                          _segments.removeAt(i);
                        });
                        _notifyChange();
                      },
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextSegmentWidget(int index, TextContentSegment seg) {
    return IntrinsicWidth(
      child: TextField(
        controller: TextEditingController(text: seg.text)..selection = TextSelection.collapsed(offset: seg.text.length),
        style: const TextStyle(fontSize: 15, height: 1.5),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
          hintText: _segments.length <= 1 ? 'Nhập nội dung đề bài...' : '',
        ),
        onChanged: (val) {
          seg.text = val;
          _notifyChange();
        },
      ),
    );
  }
}
