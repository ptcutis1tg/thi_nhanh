import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/scientific_shortcut.dart';
import '../../../core/models/visual_math_block.dart';
import '../../../core/theme/app_theme.dart';

class ScientificInputTarget {
  const ScientificInputTarget({
    required this.label,
    required this.insertText,
    required this.insertBlock,
  });

  final String label;
  final void Function(String text, int selectionOffset, int selectionLength)
  insertText;
  final ValueChanged<MathBlockType> insertBlock;
}

class ScientificTextField extends StatefulWidget {
  const ScientificTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.category,
    required this.shortcuts,
    required this.fieldLabel,
    this.onFocused,
    this.decoration,
    this.maxLines = 1,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final ScientificCategory category;
  final List<ScientificShortcut> shortcuts;
  final String fieldLabel;
  final ValueChanged<ScientificInputTarget>? onFocused;
  final InputDecoration? decoration;
  final int? maxLines;

  @override
  State<ScientificTextField> createState() => _ScientificTextFieldState();
}

class _ScientificTextFieldState extends State<ScientificTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  ScientificShortcut? _suggestion;
  int _commandStart = -1;
  int _commandEnd = -1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent)
      ..addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant ScientificTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus) return;
    widget.onFocused?.call(
      ScientificInputTarget(
        label: widget.fieldLabel,
        insertText: _insertText,
        insertBlock: (type) => _insertText(
          '\$${MathBlockSegment(id: 'inline', type: type).toLatex()}\$',
          0,
          0,
        ),
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
    final preferred = start + text.length - selectionLength;
    final caret = preferred.clamp(start, updated.length);
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
      final shortcut = _suggestion!;
      final replacement = shortcut.blockType == null
          ? shortcut.template ?? ''
          : '\$${MathBlockSegment(id: 'shortcut', type: shortcut.blockType!).toLatex()}\$';
      final updated = _controller.text.replaceRange(
        _commandStart,
        _commandEnd,
        replacement,
      );
      final caret = _commandStart + replacement.length;
      _controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: caret),
      );
      widget.onChanged(updated);
      setState(() => _suggestion = null);
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          onChanged: _handleChanged,
          decoration: widget.decoration,
        ),
        if (_suggestion != null)
          Container(
            key: const Key('scientific-field-shortcut-suggestion'),
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLavender,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '${widget.category.label} · ${_suggestion!.command} · ${_suggestion!.label} — Tab/Enter để chèn',
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
