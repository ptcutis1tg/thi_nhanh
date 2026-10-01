import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ScientificSnippet {
  const ScientificSnippet({
    required this.label,
    required this.tooltip,
    required this.template,
    this.selectionOffset = 0,
    this.selectionLength = 0,
    this.isLatex = true,
  });

  final String label;
  final String tooltip;
  final String template;
  final int selectionOffset;
  final int selectionLength;
  final bool isLatex;
}

class ScientificBottomToolbar extends StatefulWidget {
  const ScientificBottomToolbar({
    super.key,
    required this.onInsertSnippet,
  });

  final void Function(String template, int selectionOffset, int selectionLength) onInsertSnippet;

  @override
  State<ScientificBottomToolbar> createState() => _ScientificBottomToolbarState();
}

class _ScientificBottomToolbarState extends State<ScientificBottomToolbar> {
  int _activeCategory = 0;

  static const _categories = [
    'Toán học',
    'Vật lý',
    'Hóa học',
    'Hy Lạp',
    'Ngoại ngữ / IPA',
  ];

  static const List<ScientificSnippet> _mathSnippets = [
    ScientificSnippet(
      label: '□/□',
      tooltip: 'Phân số',
      template: r'\frac{\square}{\square}',
      selectionOffset: 6,
      selectionLength: 7,
    ),
    ScientificSnippet(
      label: '√□',
      tooltip: 'Căn bậc hai',
      template: r'\sqrt{\square}',
      selectionOffset: 6,
      selectionLength: 7,
    ),
    ScientificSnippet(
      label: 'ⁿ√□',
      tooltip: 'Căn bậc n',
      template: r'\sqrt[\square]{\square}',
      selectionOffset: 6,
      selectionLength: 7,
    ),
    ScientificSnippet(
      label: 'xⁿ',
      tooltip: 'Lũy thừa / Số mũ',
      template: r'^{\square}',
      selectionOffset: 2,
      selectionLength: 7,
    ),
    ScientificSnippet(
      label: 'xₙ',
      tooltip: 'Chỉ số dưới',
      template: r'_{\square}',
      selectionOffset: 2,
      selectionLength: 7,
    ),
    ScientificSnippet(
      label: '∫',
      tooltip: 'Tích phân',
      template: r'\int_{\square}^{\square} \square \, dx',
      selectionOffset: 5,
      selectionLength: 7,
    ),
    ScientificSnippet(
      label: 'd/dx',
      tooltip: 'Đạo hàm',
      template: r'\frac{d}{dx}(\square)',
      selectionOffset: 13,
      selectionLength: 7,
    ),
    ScientificSnippet(
      label: 'lim',
      tooltip: 'Giới hạn',
      template: r'\lim_{x \to \square} \square',
      selectionOffset: 12,
      selectionLength: 7,
    ),
    ScientificSnippet(
      label: '∑',
      tooltip: 'Tổng xích-ma',
      template: r'\sum_{i=1}^{\square} \square',
      selectionOffset: 11,
      selectionLength: 7,
    ),
    ScientificSnippet(label: '±', tooltip: 'Cộng trừ', template: r'\pm '),
    ScientificSnippet(label: '×', tooltip: 'Nhân', template: r'\times '),
    ScientificSnippet(label: '÷', tooltip: 'Chia', template: r'\div '),
    ScientificSnippet(label: '≠', tooltip: 'Khác', template: r'\neq '),
    ScientificSnippet(label: '≤', tooltip: 'Nhỏ hơn hoặc bằng', template: r'\leq '),
    ScientificSnippet(label: '≥', tooltip: 'Lớn hơn hoặc bằng', template: r'\geq '),
    ScientificSnippet(label: '≈', tooltip: 'Xấp xỉ', template: r'\approx '),
    ScientificSnippet(label: '∞', tooltip: 'Vô cực', template: r'\infty '),
    ScientificSnippet(label: '∈', tooltip: 'Thuộc', template: r'\in '),
    ScientificSnippet(label: '∉', tooltip: 'Không thuộc', template: r'\notin '),
    ScientificSnippet(label: '⊂', tooltip: 'Tập con', template: r'\subset '),
    ScientificSnippet(label: '∪', tooltip: 'Hợp', template: r'\cup '),
    ScientificSnippet(label: '∩', tooltip: 'Giao', template: r'\cap '),
    ScientificSnippet(label: 'v⃗', tooltip: 'Vector', template: r'\vec{\square}', selectionOffset: 5, selectionLength: 7),
  ];

  static const List<ScientificSnippet> _physicsSnippets = [
    ScientificSnippet(label: 'F⃗', tooltip: 'Lực F', template: r'\vec{F}'),
    ScientificSnippet(label: 'v⃗', tooltip: 'Vận tốc v', template: r'\vec{v}'),
    ScientificSnippet(label: 'a⃗', tooltip: 'Gia tốc a', template: r'\vec{a}'),
    ScientificSnippet(label: 'Δt', tooltip: 'Độ biến thiên thời gian', template: r'\Delta t'),
    ScientificSnippet(label: 'λ', tooltip: 'Bước sóng Lambda', template: r'\lambda'),
    ScientificSnippet(label: 'ω', tooltip: 'Tần số góc Omega', template: r'\omega'),
    ScientificSnippet(label: 'Ω', tooltip: 'Điện trở Ohm', template: r'\Omega'),
    ScientificSnippet(label: 'μm', tooltip: 'Micromet', template: r'\mu\text{m}'),
    ScientificSnippet(label: 'm/s²', tooltip: 'Gia tốc (m/s²)', template: r'\text{m/s}^2'),
    ScientificSnippet(label: 'rad/s', tooltip: 'Tốc độ góc (rad/s)', template: r'\text{rad/s}'),
    ScientificSnippet(label: 'kWh', tooltip: 'Kilowatt-giờ', template: r'\text{kWh}'),
  ];

  static const List<ScientificSnippet> _chemistrySnippets = [
    ScientificSnippet(label: '→', tooltip: 'Mũi tên phản ứng một chiều', template: r'\rightarrow '),
    ScientificSnippet(label: '⇄', tooltip: 'Mũi tên phản ứng thuận nghịch', template: r'\rightleftharpoons '),
    ScientificSnippet(label: '↑', tooltip: 'Chất khí bay hơi', template: r'\uparrow '),
    ScientificSnippet(label: '↓', tooltip: 'Chất kết tủa', template: r'\downarrow '),
    ScientificSnippet(label: '→ (t°)', tooltip: 'Phản ứng có nhiệt độ', template: r'\xrightarrow{t^\circ} '),
    ScientificSnippet(label: 'H₂O', tooltip: 'Nước', template: r'\text{H}_2\text{O}'),
    ScientificSnippet(label: 'CO₂', tooltip: 'Khí Carbon dioxide', template: r'\text{CO}_2'),
    ScientificSnippet(label: 'SO₄²⁻', tooltip: 'Gốc Sunfat', template: r'\text{SO}_4^{2-}'),
    ScientificSnippet(label: 'Fe³⁺', tooltip: 'Ion Sắt (III)', template: r'\text{Fe}^{3+}'),
    ScientificSnippet(label: 'OH⁻', tooltip: 'Ion Hydroxit', template: r'\text{OH}^-'),
  ];

  static const List<ScientificSnippet> _greekSnippets = [
    ScientificSnippet(label: 'α', tooltip: 'Alpha', template: r'\alpha'),
    ScientificSnippet(label: 'β', tooltip: 'Beta', template: r'\beta'),
    ScientificSnippet(label: 'γ', tooltip: 'Gamma', template: r'\gamma'),
    ScientificSnippet(label: 'δ', tooltip: 'Delta nhỏ', template: r'\delta'),
    ScientificSnippet(label: 'ε', tooltip: 'Epsilon', template: r'\epsilon'),
    ScientificSnippet(label: 'θ', tooltip: 'Theta', template: r'\theta'),
    ScientificSnippet(label: 'λ', tooltip: 'Lambda', template: r'\lambda'),
    ScientificSnippet(label: 'μ', tooltip: 'Mu', template: r'\mu'),
    ScientificSnippet(label: 'π', tooltip: 'Số Pi', template: r'\pi'),
    ScientificSnippet(label: 'ρ', tooltip: 'Rho', template: r'\rho'),
    ScientificSnippet(label: 'σ', tooltip: 'Sigma nhỏ', template: r'\sigma'),
    ScientificSnippet(label: 'τ', tooltip: 'Tau', template: r'\tau'),
    ScientificSnippet(label: 'φ', tooltip: 'Phi', template: r'\phi'),
    ScientificSnippet(label: 'ω', tooltip: 'Omega nhỏ', template: r'\omega'),
    ScientificSnippet(label: 'Δ', tooltip: 'Delta hoa', template: r'\Delta'),
    ScientificSnippet(label: 'Ω', tooltip: 'Omega hoa', template: r'\Omega'),
  ];

  static const List<ScientificSnippet> _languagesSnippets = [
    // IPA English
    ScientificSnippet(label: '/θ/', tooltip: 'Âm think', template: '/θ/', isLatex: false),
    ScientificSnippet(label: '/ð/', tooltip: 'Âm this', template: '/ð/', isLatex: false),
    ScientificSnippet(label: '/ʃ/', tooltip: 'Âm ship', template: '/ʃ/', isLatex: false),
    ScientificSnippet(label: '/ʒ/', tooltip: 'Âm vision', template: '/ʒ/', isLatex: false),
    ScientificSnippet(label: '/tʃ/', tooltip: 'Âm chair', template: '/tʃ/', isLatex: false),
    ScientificSnippet(label: '/dʒ/', tooltip: 'Âm job', template: '/dʒ/', isLatex: false),
    ScientificSnippet(label: '/ŋ/', tooltip: 'Âm sing', template: '/ŋ/', isLatex: false),
    ScientificSnippet(label: '/æ/', tooltip: 'Âm cat', template: '/æ/', isLatex: false),
    ScientificSnippet(label: '/ʌ/', tooltip: 'Âm cup', template: '/ʌ/', isLatex: false),
    ScientificSnippet(label: '/ə/', tooltip: 'Âm schwa', template: '/ə/', isLatex: false),
    ScientificSnippet(label: '/ɜː/', tooltip: 'Âm bird', template: '/ɜː/', isLatex: false),
    ScientificSnippet(label: '/ɪ/', tooltip: 'Âm sit', template: '/ɪ/', isLatex: false),
    ScientificSnippet(label: '/iː/', tooltip: 'Âm see', template: '/iː/', isLatex: false),
    ScientificSnippet(label: '/ʊ/', tooltip: 'Âm put', template: '/ʊ/', isLatex: false),
    ScientificSnippet(label: '/uː/', tooltip: 'Âm too', template: '/uː/', isLatex: false),
    // Accented letters
    ScientificSnippet(label: 'é', tooltip: 'e sắc', template: 'é', isLatex: false),
    ScientificSnippet(label: 'è', tooltip: 'e huyền', template: 'è', isLatex: false),
    ScientificSnippet(label: 'ê', tooltip: 'e mũ', template: 'ê', isLatex: false),
    ScientificSnippet(label: 'à', tooltip: 'a huyền', template: 'à', isLatex: false),
    ScientificSnippet(label: 'â', tooltip: 'a mũ', template: 'â', isLatex: false),
    ScientificSnippet(label: 'ç', tooltip: 'c móc', template: 'ç', isLatex: false),
    ScientificSnippet(label: 'ü', tooltip: 'u hai chấm', template: 'ü', isLatex: false),
    ScientificSnippet(label: 'ö', tooltip: 'o hai chấm', template: 'ö', isLatex: false),
    ScientificSnippet(label: 'ä', tooltip: 'a hai chấm', template: 'ä', isLatex: false),
    ScientificSnippet(label: 'ß', tooltip: 'Eszett', template: 'ß', isLatex: false),
    ScientificSnippet(label: 'ñ', tooltip: 'n ngã', template: 'ñ', isLatex: false),
    ScientificSnippet(label: '¡', tooltip: 'Chấm than ngược', template: '¡', isLatex: false),
    ScientificSnippet(label: '¿', tooltip: 'Chấm hỏi ngược', template: '¿', isLatex: false),
  ];

  List<ScientificSnippet> get _currentSnippets {
    switch (_activeCategory) {
      case 0:
        return _mathSnippets;
      case 1:
        return _physicsSnippets;
      case 2:
        return _chemistrySnippets;
      case 3:
        return _greekSnippets;
      case 4:
        return _languagesSnippets;
      default:
        return _mathSnippets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category selector tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: List.generate(_categories.length, (idx) {
                final active = idx == _activeCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      _categories[idx],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.bold : FontWeight.w500,
                        color: active ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: active,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.background,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    onSelected: (_) => setState(() => _activeCategory = idx),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          // Snippet buttons row
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _currentSnippets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final item = _currentSnippets[index];
                return Tooltip(
                  message: item.tooltip,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      final str = item.isLatex ? '\$${item.template}\$' : item.template;
                      widget.onInsertSnippet(str, item.selectionOffset, item.selectionLength);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
