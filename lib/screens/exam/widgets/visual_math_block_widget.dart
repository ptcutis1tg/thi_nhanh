import 'package:flutter/material.dart';
import '../../../core/models/visual_math_block.dart';
import '../../../core/theme/app_theme.dart';
import 'visual_math_slot_input.dart';

class VisualMathBlockWidget extends StatelessWidget {
  const VisualMathBlockWidget({
    super.key,
    required this.block,
    required this.onSlotChanged,
    required this.onDelete,
    this.autofocusFirstSlot = false,
  });

  final MathBlockSegment block;
  final void Function(String slotKey, String value) onSlotChanged;
  final VoidCallback onDelete;
  final bool autofocusFirstSlot;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _buildLayout(context),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    switch (block.type) {
      case MathBlockType.fraction:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VisualSlotInput(
              initialValue: block.slots['num'] ?? '',
              placeholder: 'tử số',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('num', val),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 3),
              constraints: const BoxConstraints(minWidth: 42, maxWidth: 160),
              color: Colors.black87,
            ),
            VisualSlotInput(
              initialValue: block.slots['den'] ?? '',
              placeholder: 'mẫu số',
              onChanged: (val) => onSlotChanged('den', val),
            ),
          ],
        );

      case MathBlockType.sqrt:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('√', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: AppTheme.primary)),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.primary, width: 2)),
              ),
              padding: const EdgeInsets.only(top: 2),
              child: VisualSlotInput(
                initialValue: block.slots['radicand'] ?? '',
                placeholder: 'biểu thức',
                autofocus: autofocusFirstSlot,
                onChanged: (val) => onSlotChanged('radicand', val),
              ),
            ),
          ],
        );

      case MathBlockType.nroot:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(4, -8),
              child: VisualSlotInput(
                initialValue: block.slots['index'] ?? '',
                placeholder: 'n',
                minWidth: 26,
                fontSize: 11,
                autofocus: autofocusFirstSlot,
                onChanged: (val) => onSlotChanged('index', val),
              ),
            ),
            const Text('√', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: AppTheme.primary)),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.primary, width: 2)),
              ),
              padding: const EdgeInsets.only(top: 2),
              child: VisualSlotInput(
                initialValue: block.slots['radicand'] ?? '',
                placeholder: 'biểu thức',
                onChanged: (val) => onSlotChanged('radicand', val),
              ),
            ),
          ],
        );

      case MathBlockType.power:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VisualSlotInput(
              initialValue: block.slots['base'] ?? '',
              placeholder: 'cơ số',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('base', val),
            ),
            Transform.translate(
              offset: const Offset(0, -8),
              child: VisualSlotInput(
                initialValue: block.slots['exp'] ?? '',
                placeholder: 'mũ',
                fontSize: 11,
                minWidth: 28,
                onChanged: (val) => onSlotChanged('exp', val),
              ),
            ),
          ],
        );

      case MathBlockType.subscript:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VisualSlotInput(
              initialValue: block.slots['base'] ?? '',
              placeholder: 'biến',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('base', val),
            ),
            Transform.translate(
              offset: const Offset(0, 8),
              child: VisualSlotInput(
                initialValue: block.slots['sub'] ?? '',
                placeholder: 'chỉ số',
                fontSize: 11,
                minWidth: 28,
                onChanged: (val) => onSlotChanged('sub', val),
              ),
            ),
          ],
        );

      case MathBlockType.integral:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VisualSlotInput(
                  initialValue: block.slots['upper'] ?? '',
                  placeholder: 'b',
                  fontSize: 11,
                  minWidth: 26,
                  onChanged: (val) => onSlotChanged('upper', val),
                ),
                const Text('∫', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: AppTheme.primary)),
                VisualSlotInput(
                  initialValue: block.slots['lower'] ?? '',
                  placeholder: 'a',
                  fontSize: 11,
                  minWidth: 26,
                  autofocus: autofocusFirstSlot,
                  onChanged: (val) => onSlotChanged('lower', val),
                ),
              ],
            ),
            const SizedBox(width: 4),
            VisualSlotInput(
              initialValue: block.slots['expr'] ?? '',
              placeholder: 'f(x)',
              onChanged: (val) => onSlotChanged('expr', val),
            ),
            const SizedBox(width: 4),
            const Text('dx', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
          ],
        );

      case MathBlockType.limit:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('lim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('x→', style: TextStyle(fontSize: 11)),
                    VisualSlotInput(
                      initialValue: block.slots['to'] ?? '',
                      placeholder: 'x₀',
                      fontSize: 10,
                      minWidth: 26,
                      autofocus: autofocusFirstSlot,
                      onChanged: (val) => onSlotChanged('to', val),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            VisualSlotInput(
              initialValue: block.slots['expr'] ?? '',
              placeholder: 'f(x)',
              onChanged: (val) => onSlotChanged('expr', val),
            ),
          ],
        );

      case MathBlockType.logarithm:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('log', style: TextStyle(fontWeight: FontWeight.bold)),
            Transform.translate(
              offset: const Offset(0, 6),
              child: VisualSlotInput(
                initialValue: block.slots['base'] ?? '',
                placeholder: 'a',
                fontSize: 10,
                minWidth: 24,
                autofocus: autofocusFirstSlot,
                onChanged: (val) => onSlotChanged('base', val),
              ),
            ),
            const Text('('),
            VisualSlotInput(
              initialValue: block.slots['arg'] ?? '',
              placeholder: 'b',
              onChanged: (val) => onSlotChanged('arg', val),
            ),
            const Text(')'),
          ],
        );

      case MathBlockType.summation:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VisualSlotInput(
                  initialValue: block.slots['to'] ?? '',
                  placeholder: 'n',
                  fontSize: 10,
                  minWidth: 26,
                  onChanged: (val) => onSlotChanged('to', val),
                ),
                const Text('∑', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                VisualSlotInput(
                  initialValue: block.slots['from'] ?? '',
                  placeholder: 'i=1',
                  fontSize: 10,
                  minWidth: 32,
                  autofocus: autofocusFirstSlot,
                  onChanged: (val) => onSlotChanged('from', val),
                ),
              ],
            ),
            const SizedBox(width: 4),
            VisualSlotInput(
              initialValue: block.slots['expr'] ?? '',
              placeholder: 'f(i)',
              onChanged: (val) => onSlotChanged('expr', val),
            ),
          ],
        );

      case MathBlockType.vector:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('→', style: TextStyle(fontSize: 14, height: 0.8, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            VisualSlotInput(
              initialValue: block.slots['name'] ?? '',
              placeholder: 'v',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('name', val),
            ),
          ],
        );

      case MathBlockType.angle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('^', style: TextStyle(fontSize: 14, height: 0.8, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            VisualSlotInput(
              initialValue: block.slots['name'] ?? '',
              placeholder: 'ABC',
              autofocus: autofocusFirstSlot,
              onChanged: (val) => onSlotChanged('name', val),
            ),
          ],
        );
    }
  }
}
