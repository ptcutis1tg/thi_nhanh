import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/visual_math_block.dart';
import 'package:onthi_community/core/utils/visual_math_compiler.dart';

void main() {
  group('VisualMathCompiler Tests', () {
    test('compiles fraction segment to LaTeX', () {
      final block = MathBlockSegment(
        id: '1',
        type: MathBlockType.fraction,
        slots: {'num': '2x + 1', 'den': 'x - 3'},
      );
      final latex = VisualMathCompiler.compile([
        TextContentSegment('Cho hàm số '),
        block,
        TextContentSegment('. Tìm tập xác định.'),
      ]);
      expect(latex, r'Cho hàm số \frac{2x + 1}{x - 3}. Tìm tập xác định.');
    });

    test('compiles square root and power segments', () {
      final sqrtBlock = MathBlockSegment(
        id: '2',
        type: MathBlockType.sqrt,
        slots: {'radicand': 'x^2 + 1'},
      );
      final powerBlock = MathBlockSegment(
        id: '3',
        type: MathBlockType.power,
        slots: {'base': 'x', 'exp': '3'},
      );
      final latex = VisualMathCompiler.compile([sqrtBlock, TextContentSegment(' + '), powerBlock]);
      expect(latex, r'\sqrt{x^2 + 1} + {x}^{3}');
    });

    test('compiles integral and limit segments', () {
      final integralBlock = MathBlockSegment(
        id: '4',
        type: MathBlockType.integral,
        slots: {'lower': '0', 'upper': '1', 'expr': '2x'},
      );
      expect(integralBlock.toLatex(), r'\int_{0}^{1} {2x} \, dx');

      final limitBlock = MathBlockSegment(
        id: '5',
        type: MathBlockType.limit,
        slots: {'to': '0', 'expr': r'\frac{\sin x}{x}'},
      );
      expect(limitBlock.toLatex(), r'\lim_{x \to 0} {\frac{\sin x}{x}}');
    });

    test('compiles empty slots with placeholders without crashing', () {
      final emptyFraction = MathBlockSegment(id: '6', type: MathBlockType.fraction);
      expect(emptyFraction.toLatex(), r'\frac{\square}{\square}');
    });

    test('parses LaTeX containing fraction and root back into segments', () {
      const input = r'Tính \frac{1}{2} + \sqrt{4}';
      final segments = VisualMathCompiler.parse(input);
      expect(segments.length, 4);
      expect(segments[0], isA<TextContentSegment>());
      expect((segments[0] as TextContentSegment).text, 'Tính ');
      expect(segments[1], isA<MathBlockSegment>());
      final fraction = segments[1] as MathBlockSegment;
      expect(fraction.type, MathBlockType.fraction);
      expect(fraction.slots['num'], '1');
      expect(fraction.slots['den'], '2');
      expect((segments[2] as TextContentSegment).text, ' + ');
      expect(segments[3], isA<MathBlockSegment>());
      final sqrt = segments[3] as MathBlockSegment;
      expect(sqrt.type, MathBlockType.sqrt);
      expect(sqrt.slots['radicand'], '4');
    });
  });
}
