import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/visual_math_block.dart';
import '../../../core/models/scientific_shortcut.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/visual_math_compiler.dart';
import 'visual_math_block_widget.dart';
import 'scientific_text_field.dart';

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
    this.shortcutCategory = ScientificCategory.math,
    this.shortcuts = const [],
    this.onFocusTarget,
  });

  final String initialLatex;
  final ValueChanged<String> onChanged;
  final InlineVisualMathEditorController? controller;
  final ScientificCategory shortcutCategory;
  final List<ScientificShortcut> shortcuts;
  final ValueChanged<ScientificInputTarget>? onFocusTarget;

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

  void _applyShortcut(
    int segmentIndex,
    ScientificShortcut shortcut,
    int commandStart,
    int commandEnd,
  ) {
    if (shortcut.blockType != null) {
      _insertBlockAt(
        segmentIndex,
        shortcut.blockType!,
        commandStart,
        commandEnd,
      );
      return;
    }
    final segment = _segments[segmentIndex] as TextContentSegment;
    final before = segment.text.substring(0, commandStart);
    final after = segment.text.substring(commandEnd);
    setState(() {
      segment.text = '$before${shortcut.template ?? ''}$after';
      _rawLatexController.text = VisualMathCompiler.compile(_segments);
    });
    _notifyChange();
  }

  void _insertBlockAt(
    int segmentIndex,
    MathBlockType type,
    int selectionStart,
    int selectionEnd,
  ) {
    final segment = _segments[segmentIndex] as TextContentSegment;
    final safeStart = selectionStart.clamp(0, segment.text.length);
    final safeEnd = selectionEnd.clamp(safeStart, segment.text.length);
    final before = segment.text.substring(0, safeStart);
    final after = segment.text.substring(safeEnd);
    setState(() {
      segment.text = before;
      _segments.insert(
        segmentIndex + 1,
        MathBlockSegment(
          id: 'mb_${DateTime.now().microsecondsSinceEpoch}',
          type: type,
        ),
      );
      _segments.insert(
        segmentIndex + 2,
        TextContentSegment(after.isEmpty ? ' ' : after),
      );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _isVisualMode
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isVisualMode ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dashboard_customize_outlined,
                      size: 14,
                      color: _isVisualMode
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Khối trực quan [ ]',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isVisualMode
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _isVisualMode
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: !_isVisualMode
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: !_isVisualMode ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 14,
                      color: !_isVisualMode
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mã nguồn LaTeX',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isVisualMode
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: !_isVisualMode
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
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
          ScientificTextField(
            key: const Key('raw-latex-scientific-field'),
            initialValue: _rawLatexController.text,
            maxLines: 4,
            category: widget.shortcutCategory,
            shortcuts: widget.shortcuts,
            fieldLabel: 'Mã nguồn LaTeX',
            onFocused: widget.onFocusTarget,
            decoration: const InputDecoration(
              hintText: r'Nhập công thức dạng \frac{a}{b} hoặc văn bản...',
            ),
            onChanged: (val) {
              _rawLatexController.text = val;
              _notifyChange();
            },
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
                    _buildTextSegmentWidget(
                      i,
                      _segments[i] as TextContentSegment,
                    )
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
    return _TextSegmentField(
      key: Key('inline-math-text-segment-$index'),
      initialText: seg.text,
      hintText: _segments.length <= 1
          ? 'Nhập nội dung câu hỏi, công thức toán...'
          : '',
      onChanged: (val) {
        seg.text = val;
        _notifyChange();
      },
      shortcuts: widget.shortcuts,
      category: widget.shortcutCategory,
      onAcceptShortcut: (shortcut, start, end) =>
          _applyShortcut(index, shortcut, start, end),
      onFocused: widget.onFocusTarget,
      onInsertBlock: (type, start, end) =>
          _insertBlockAt(index, type, start, end),
    );
  }
}

class _TextSegmentField extends StatefulWidget {
  const _TextSegmentField({
    super.key,
    required this.initialText,
    required this.hintText,
    required this.onChanged,
    required this.shortcuts,
    required this.category,
    required this.onAcceptShortcut,
    required this.onInsertBlock,
    this.onFocused,
  });

  final String initialText;
  final String hintText;
  final ValueChanged<String> onChanged;
  final List<ScientificShortcut> shortcuts;
  final ScientificCategory category;
  final void Function(ScientificShortcut shortcut, int start, int end)
  onAcceptShortcut;
  final void Function(MathBlockType type, int start, int end) onInsertBlock;
  final ValueChanged<ScientificInputTarget>? onFocused;

  @override
  State<_TextSegmentField> createState() => _TextSegmentFieldState();
}

class _TextSegmentFieldState extends State<_TextSegmentField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  ScientificShortcut? _suggestion;
  int _commandStart = -1;
  int _commandEnd = -1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent)
      ..addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant _TextSegmentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != _controller.text &&
        widget.initialText != oldWidget.initialText) {
      _controller.value = TextEditingValue(
        text: widget.initialText,
        selection: TextSelection.collapsed(offset: widget.initialText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus) return;
    widget.onFocused?.call(
      ScientificInputTarget(
        label: 'Nội dung câu hỏi',
        insertText: _insertText,
        insertBlock: (type) {
          final selection = _controller.selection.isValid
              ? _controller.selection
              : TextSelection.collapsed(offset: _controller.text.length);
          widget.onInsertBlock(type, selection.start, selection.end);
        },
      ),
    );
  }

  void _insertText(String text, int selectionOffset, int selectionLength) {
    final selection = _controller.selection.isValid
        ? _controller.selection
        : TextSelection.collapsed(offset: _controller.text.length);
    final start = selection.start.clamp(0, _controller.text.length);
    final end = selection.end.clamp(start, _controller.text.length);
    final updated = _controller.text.replaceRange(start, end, text);
    final caret = (start + text.length - selectionLength).clamp(
      start,
      updated.length,
    );
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: caret),
    );
    widget.onChanged(updated);
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _suggestion == null) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final suggestion = _suggestion!;
      final start = _commandStart;
      final end = _commandEnd;
      setState(() => _suggestion = null);
      widget.onAcceptShortcut(suggestion, start, end);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _suggestion = null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleChanged(String value) {
    widget.onChanged(value);
    final caret = _controller.selection.baseOffset;
    ScientificShortcut? match;
    var start = -1;
    if (caret >= 0) {
      for (final shortcut in widget.shortcuts) {
        final candidateStart = caret - shortcut.command.length;
        if (candidateStart >= 0 &&
            value.substring(candidateStart, caret) == shortcut.command &&
            (candidateStart == 0 || value[candidateStart - 1].trim().isEmpty)) {
          match = shortcut;
          start = candidateStart;
          break;
        }
      }
    }
    if (match != _suggestion || start != _commandStart) {
      setState(() {
        _suggestion = match;
        _commandStart = start;
        _commandEnd = caret;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80),
          child: IntrinsicWidth(
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              maxLines: null,
              style: const TextStyle(fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                border: InputBorder.none,
                hintText: widget.hintText,
              ),
              onChanged: _handleChanged,
            ),
          ),
        ),
        if (_suggestion != null)
          Container(
            key: const Key('scientific-shortcut-suggestion'),
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLavender,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.category.label} · ${_suggestion!.command} · ${_suggestion!.label}  —  Tab/Enter để chèn',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
