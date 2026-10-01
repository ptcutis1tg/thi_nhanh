import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/room_repository.dart';
import '../../core/theme/app_theme.dart';

class RoomPasswordScreen extends StatefulWidget {
  const RoomPasswordScreen({super.key, this.roomCode});
  final String? roomCode;

  @override
  State<RoomPasswordScreen> createState() => _RoomPasswordScreenState();
}

class _RoomPasswordScreenState extends State<RoomPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu phòng thi.');
      return;
    }

    final code = widget.roomCode;
    if (code == null || code.trim().isEmpty) {
      setState(() => _error = 'Thiếu mã phòng thi. Vui lòng thử lại.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<RoomRepository?>();
      if (repo == null) {
        context.go('/student_waiting_room');
        return;
      }

      final result = await repo.joinRoom(
        code: code.trim(),
        password: password,
      );

      if (mounted) {
        final guestTokenParam = result.guestToken != null ? '&guestToken=${result.guestToken}' : '';
        context.go(
          '/student_waiting_room?roomId=${result.roomId}&participantId=${result.participantId}$guestTokenParam',
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('invalid room password') || msg.contains('mật khẩu')) {
          setState(() => _error = 'Mật khẩu phòng thi không chính xác.');
        } else {
          setState(() => _error = e.toString().replaceAll('Exception: ', ''));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Thi Nhanh',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
      ),
      actions: [
        IconButton(
          onPressed: () => context.go('/search'),
          icon: const Icon(Icons.close, color: AppTheme.textMain),
        ),
      ],
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 28),
              Text(
                'Yêu cầu mật khẩu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                widget.roomCode != null
                    ? 'Phòng thi ${widget.roomCode} được bảo vệ bằng mật khẩu. Vui lòng nhập mật khẩu để tham gia.'
                    : 'Phòng thi này được bảo vệ. Vui lòng nhập mật khẩu chính xác để tiếp tục.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.key_outlined),
                  hintText: 'Nhập mật khẩu phòng thi',
                  errorText: _error,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(_isLoading ? 'Đang kiểm tra...' : 'Xác nhận vào phòng'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Quay lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
