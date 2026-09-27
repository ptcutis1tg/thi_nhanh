import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/ai_navigation_service.dart';

class AiNavigationButton extends StatefulWidget {
  const AiNavigationButton({super.key, this.interpretCommand});

  final Future<AiNavigationAction> Function(String command)? interpretCommand;

  @override
  State<AiNavigationButton> createState() => _AiNavigationButtonState();
}

class _AiNavigationButtonState extends State<AiNavigationButton> {
  bool _isLoading = false;

  Future<void> _openCommandDialog() async {
    var enteredCommand = '';
    final command = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Điều hướng bằng AI'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: Đưa tôi về trang chủ',
          ),
          onChanged: (value) => enteredCommand = value,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(enteredCommand),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );

    if (command == null || command.trim().isEmpty || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final interpret = widget.interpretCommand ??
          AiNavigationService(Supabase.instance.client).interpret;
      final action = await interpret(command);
      if (!mounted) return;

      switch (action) {
        case AiNavigationAction.goHome:
          context.go('/home');
        case AiNavigationAction.none:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI chưa nhận ra yêu cầu về trang chủ.')),
          );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gọi AI. Hãy kiểm tra Edge Function và API key.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _openCommandDialog,
      icon: _isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(_isLoading ? 'Đang hỏi AI...' : 'AI'),
    );
  }
}
