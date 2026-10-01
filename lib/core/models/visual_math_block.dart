enum MathBlockType {
  fraction,
  sqrt,
  nroot,
  power,
  subscript,
  integral,
  limit,
  logarithm,
  summation,
  vector,
  angle;

  String get label {
    switch (this) {
      case MathBlockType.fraction:
        return 'Phân số';
      case MathBlockType.sqrt:
        return 'Căn bậc 2';
      case MathBlockType.nroot:
        return 'Căn bậc n';
      case MathBlockType.power:
        return 'Số mũ';
      case MathBlockType.subscript:
        return 'Chỉ số';
      case MathBlockType.integral:
        return 'Tích phân';
      case MathBlockType.limit:
        return 'Giới hạn';
      case MathBlockType.logarithm:
        return 'Logarit';
      case MathBlockType.summation:
        return 'Tổng Sigma';
      case MathBlockType.vector:
        return 'Vectơ';
      case MathBlockType.angle:
        return 'Góc';
    }
  }

  List<SlotDefinition> get slotDefinitions {
    switch (this) {
      case MathBlockType.fraction:
        return const [
          SlotDefinition(key: 'num', label: 'Tử số', placeholder: 'tử'),
          SlotDefinition(key: 'den', label: 'Mẫu số', placeholder: 'mẫu'),
        ];
      case MathBlockType.sqrt:
        return const [
          SlotDefinition(key: 'radicand', label: 'Biểu thức', placeholder: 'biểu thức'),
        ];
      case MathBlockType.nroot:
        return const [
          SlotDefinition(key: 'index', label: 'Bậc', placeholder: 'n', defaultWidth: 32),
          SlotDefinition(key: 'radicand', label: 'Biểu thức', placeholder: 'biểu thức'),
        ];
      case MathBlockType.power:
        return const [
          SlotDefinition(key: 'base', label: 'Cơ số', placeholder: 'x'),
          SlotDefinition(key: 'exp', label: 'Số mũ', placeholder: 'mũ', defaultWidth: 36),
        ];
      case MathBlockType.subscript:
        return const [
          SlotDefinition(key: 'base', label: 'Ký hiệu', placeholder: 'x'),
          SlotDefinition(key: 'sub', label: 'Chỉ số', placeholder: 'i', defaultWidth: 36),
        ];
      case MathBlockType.integral:
        return const [
          SlotDefinition(key: 'lower', label: 'Cận dưới', placeholder: 'a', defaultWidth: 32),
          SlotDefinition(key: 'upper', label: 'Cận trên', placeholder: 'b', defaultWidth: 32),
          SlotDefinition(key: 'expr', label: 'Hàm số', placeholder: 'f(x)'),
        ];
      case MathBlockType.limit:
        return const [
          SlotDefinition(key: 'to', label: 'Tiến tới', placeholder: 'x₀', defaultWidth: 36),
          SlotDefinition(key: 'expr', label: 'Biểu thức', placeholder: 'f(x)'),
        ];
      case MathBlockType.logarithm:
        return const [
          SlotDefinition(key: 'base', label: 'Cơ số', placeholder: 'a', defaultWidth: 36),
          SlotDefinition(key: 'arg', label: 'Biểu thức', placeholder: 'b'),
        ];
      case MathBlockType.summation:
        return const [
          SlotDefinition(key: 'from', label: 'Từ', placeholder: 'i=1', defaultWidth: 40),
          SlotDefinition(key: 'to', label: 'Đến', placeholder: 'n', defaultWidth: 36),
          SlotDefinition(key: 'expr', label: 'Biểu thức', placeholder: 'f(i)'),
        ];
      case MathBlockType.vector:
        return const [
          SlotDefinition(key: 'name', label: 'Tên', placeholder: 'v'),
        ];
      case MathBlockType.angle:
        return const [
          SlotDefinition(key: 'name', label: 'Tên góc', placeholder: 'ABC'),
        ];
    }
  }

  String compileToLatex(Map<String, String> slots) {
    String slot(String k) {
      final v = slots[k]?.trim();
      return (v == null || v.isEmpty) ? r'\square' : v;
    }

    switch (this) {
      case MathBlockType.fraction:
        return '\\frac{${slot('num')}}{${slot('den')}}';
      case MathBlockType.sqrt:
        return '\\sqrt{${slot('radicand')}}';
      case MathBlockType.nroot:
        return '\\sqrt[${slot('index')}]{${slot('radicand')}}';
      case MathBlockType.power:
        return '{${slot('base')}}^{${slot('exp')}}';
      case MathBlockType.subscript:
        return '{${slot('base')}}_{${slot('sub')}}';
      case MathBlockType.integral:
        return '\\int_{${slot('lower')}}^{${slot('upper')}} {${slot('expr')}} \\, dx';
      case MathBlockType.limit:
        return '\\lim_{x \\to ${slot('to')}} {${slot('expr')}}';
      case MathBlockType.logarithm:
        return '\\log_{${slot('base')}}({${slot('arg')}})';
      case MathBlockType.summation:
        return '\\sum_{${slot('from')}}^{${slot('to')}} {${slot('expr')}}';
      case MathBlockType.vector:
        return '\\vec{${slot('name')}}';
      case MathBlockType.angle:
        return '\\widehat{${slot('name')}}';
    }
  }
}

class SlotDefinition {
  final String key;
  final String label;
  final String placeholder;
  final double defaultWidth;

  const SlotDefinition({
    required this.key,
    required this.label,
    required this.placeholder,
    this.defaultWidth = 48,
  });
}

sealed class QuestionContentSegment {
  String toLatex();
}

class TextContentSegment extends QuestionContentSegment {
  String text;
  TextContentSegment(this.text);

  @override
  String toLatex() => text;
}

class MathBlockSegment extends QuestionContentSegment {
  final String id;
  final MathBlockType type;
  final Map<String, String> slots;

  MathBlockSegment({
    required this.id,
    required this.type,
    Map<String, String>? slots,
  }) : slots = slots != null ? Map<String, String>.from(slots) : <String, String>{};

  @override
  String toLatex() => type.compileToLatex(slots);

  MathBlockSegment copy() {
    return MathBlockSegment(
      id: id,
      type: type,
      slots: Map<String, String>.from(slots),
    );
  }
}
