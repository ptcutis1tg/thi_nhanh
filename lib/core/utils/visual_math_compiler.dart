import '../models/visual_math_block.dart';

class VisualMathCompiler {
  static String compile(List<QuestionContentSegment> segments) {
    final buffer = StringBuffer();
    for (final seg in segments) {
      buffer.write(seg.toLatex());
    }
    return buffer.toString();
  }

  static List<QuestionContentSegment> parse(String rawText) {
    if (rawText.isEmpty) return [TextContentSegment('')];

    final segments = <QuestionContentSegment>[];
    int idCounter = 0;

    // Regular expressions matching LaTeX patterns
    final fractionRegex = RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}');
    final sqrtRegex = RegExp(r'\\sqrt\{([^}]+)\}');
    final nrootRegex = RegExp(r'\\sqrt\[([^\]]+)\]\{([^}]+)\}');
    final integralRegex = RegExp(r'\\int_\{([^}]+)\}\^\{([^}]+)\}\s*\{([^}]+)\}\s*\\,\s*dx');
    final limitRegex = RegExp(r'\\lim_\{x\s*\\to\s*([^}]+)\}\s*\{([^}]+)\}');

    int index = 0;
    while (index < rawText.length) {
      final substring = rawText.substring(index);

      // Check fraction
      final fracMatch = fractionRegex.matchAsPrefix(substring);
      if (fracMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.fraction,
          slots: {
            'num': fracMatch.group(1) == r'\square' ? '' : (fracMatch.group(1) ?? ''),
            'den': fracMatch.group(2) == r'\square' ? '' : (fracMatch.group(2) ?? ''),
          },
        ));
        index += fracMatch.end;
        continue;
      }

      // Check nroot
      final nrootMatch = nrootRegex.matchAsPrefix(substring);
      if (nrootMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.nroot,
          slots: {
            'index': nrootMatch.group(1) == r'\square' ? '' : (nrootMatch.group(1) ?? ''),
            'radicand': nrootMatch.group(2) == r'\square' ? '' : (nrootMatch.group(2) ?? ''),
          },
        ));
        index += nrootMatch.end;
        continue;
      }

      // Check sqrt
      final sqrtMatch = sqrtRegex.matchAsPrefix(substring);
      if (sqrtMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.sqrt,
          slots: {
            'radicand': sqrtMatch.group(1) == r'\square' ? '' : (sqrtMatch.group(1) ?? ''),
          },
        ));
        index += sqrtMatch.end;
        continue;
      }

      // Check integral
      final intMatch = integralRegex.matchAsPrefix(substring);
      if (intMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.integral,
          slots: {
            'lower': intMatch.group(1) ?? '',
            'upper': intMatch.group(2) ?? '',
            'expr': intMatch.group(3) ?? '',
          },
        ));
        index += intMatch.end;
        continue;
      }

      // Check limit
      final limMatch = limitRegex.matchAsPrefix(substring);
      if (limMatch != null) {
        segments.add(MathBlockSegment(
          id: 'mb_${++idCounter}',
          type: MathBlockType.limit,
          slots: {
            'to': limMatch.group(1) ?? '',
            'expr': limMatch.group(2) ?? '',
          },
        ));
        index += limMatch.end;
        continue;
      }

      // Read plain character into trailing TextContentSegment
      if (segments.isNotEmpty && segments.last is TextContentSegment) {
        (segments.last as TextContentSegment).text += rawText[index];
      } else {
        segments.add(TextContentSegment(rawText[index]));
      }
      index++;
    }

    if (segments.isEmpty) {
      segments.add(TextContentSegment(''));
    }
    return segments;
  }
}
