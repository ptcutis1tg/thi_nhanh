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

    // A Wrap centers a formula against a multi-line Text child.  That makes a
    // formula from a later logical line appear beside an earlier line. Split
    // the question into rows first, then compose text and math inside each
    // individual row.
    final lines = _splitTopLevelLines(text);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          if (line.isEmpty)
            SizedBox(
              height: (defaultStyle.fontSize ?? 16) *
                  (defaultStyle.height ?? 1.2),
            )
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: _parseMixedContent(line),
            ),
      ],
    );
  }

  bool _looksLikeRawLatex(String value) {
    return RegExp(r'\\(?:begin|end|frac|sqrt|sum|int|lim|vec|widehat|log|overset|mathrm)\b')
        .hasMatch(value);
  }

  List<String> _splitTopLevelLines(String source) {
    final lines = <String>[];
    final buffer = StringBuffer();
    var isInsideMath = false;

    for (var index = 0; index < source.length; index++) {
      final character = source[index];
      final isEscaped = index > 0 && source.codeUnitAt(index - 1) == 0x5C;

      if (character == r'$' && !isEscaped) {
        final isDoubleDelimiter =
            index + 1 < source.length && source[index + 1] == r'$';
        buffer.write(character);
        if (isDoubleDelimiter) {
          buffer.write(r'$');
          index++;
        }
        isInsideMath = !isInsideMath;
      } else if (character == '\n' && !isInsideMath) {
        lines.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }

    lines.add(buffer.toString());
    return lines;
  }

  List<Widget> _parseMixedContent(String raw) {
    final widgets = <Widget>[];
    final defaultStyle =
        textStyle ?? TextStyle(fontSize: 16, color: color ?? Colors.black87);

    // Regex to capture $$...$$ (block) or $...$ (inline)
    final pattern = RegExp(r'(\$\$([\s\S]*?)\$\$|\$([\s\S]*?)\$)');
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
