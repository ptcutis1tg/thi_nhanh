import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class LatexMathView extends StatelessWidget {
  const LatexMathView({
    super.key,
    required this.text,
    this.textStyle,
    this.mathStyle = MathStyle.text,
    this.color,
  });

  final String text;
  final TextStyle? textStyle;
  final MathStyle mathStyle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final defaultStyle =
        textStyle ?? TextStyle(fontSize: 16, color: color ?? Colors.black87);

    // Raw LaTeX mode intentionally accepts commands without $ delimiters.
    // Route command-like input through the math renderer instead of exposing
    // the source as plain text.
    if (!text.contains(r'$')) {
      if (_looksLikeRawLatex(text)) {
        return Math.tex(
          text,
          mathStyle: MathStyle.display,
          textStyle: defaultStyle,
          onErrorFallback: (error) => Text(
            text,
            style: defaultStyle.copyWith(color: Colors.redAccent),
          ),
        );
      }
      return Text(
        text,
        style: defaultStyle,
      );
    }

    final spans = _parseMixedContent(text, context);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: spans,
    );
  }

  bool _looksLikeRawLatex(String value) {
    return RegExp(r'\\(?:begin|end|frac|sqrt|sum|int|lim|vec|widehat|log|overset|mathrm)\b')
        .hasMatch(value);
  }

  List<Widget> _parseMixedContent(String raw, BuildContext context) {
    final widgets = <Widget>[];
    final defaultStyle =
        textStyle ?? TextStyle(fontSize: 16, color: color ?? Colors.black87);

    // Regex to capture $$...$$ (block) or $...$ (inline)
    final pattern = RegExp(r'(\$\$(.*?)\$\$|\$(.*?)\$)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(raw)) {
      if (match.start > lastIndex) {
        final textPart = raw.substring(lastIndex, match.start);
        if (textPart.isNotEmpty) {
          widgets.add(Text(textPart, style: defaultStyle));
        }
      }

      final isBlock = match.group(1)?.startsWith(r'$$') ?? false;
      final formula = (isBlock ? match.group(2) : match.group(3)) ?? '';

      try {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Math.tex(
              formula,
              mathStyle: isBlock ? MathStyle.display : mathStyle,
              textStyle: defaultStyle,
              onErrorFallback: (err) => Text(
                match.group(0) ?? formula,
                style: defaultStyle.copyWith(color: Colors.redAccent),
              ),
            ),
          ),
        );
      } catch (_) {
        widgets.add(Text(match.group(0) ?? formula, style: defaultStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < raw.length) {
      final trailing = raw.substring(lastIndex);
      if (trailing.isNotEmpty) {
        widgets.add(Text(trailing, style: defaultStyle));
      }
    }

    return widgets;
  }
}
