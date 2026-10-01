import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class VisualSlotInput extends StatefulWidget {
  const VisualSlotInput({
    super.key,
    required this.initialValue,
    required this.placeholder,
    required this.onChanged,
    this.minWidth = 38,
    this.fontSize = 14,
    this.autofocus = false,
  });

  final String initialValue;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final double minWidth;
  final double fontSize;
  final bool autofocus;

  @override
  State<VisualSlotInput> createState() => _VisualSlotInputState();
}

class _VisualSlotInputState extends State<VisualSlotInput> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(VisualSlotInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusNode,
      builder: (context, _) {
        final isFocused = _focusNode.hasFocus;
        final textLength = _controller.text.length;
        final dynamicWidth = (textLength * (widget.fontSize * 0.65) + 20).clamp(widget.minWidth, 200.0);

        return Container(
          width: dynamicWidth,
          height: widget.fontSize + 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isFocused ? Colors.white : AppTheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isFocused ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.4),
              width: isFocused ? 1.8 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                fontSize: widget.fontSize * 0.85,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
            onChanged: (val) {
              setState(() {});
              widget.onChanged(val);
            },
          ),
        );
      },
    );
  }
}
