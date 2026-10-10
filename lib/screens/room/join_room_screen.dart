import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/repositories/room_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_error_reporter.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({
    super.key,
    this.initialRoomCode,
  });

  final String? initialRoomCode;

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialCode = widget.initialRoomCode?.trim() ?? '';
    _codeController = TextEditingController(
      text: initialCode.isNotEmpty ? AppErrorReporter.normalizeRoomCode(initialCode) : '',
    );
    _nameController = TextEditingController();

    // Auto-fill name if authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider?>();
      if (auth != null && auth.isAuthenticated && (auth.user?.email?.isNotEmpty ?? false)) {
        final email = auth.user!.email!;
        final defaultName = email.split('@').first;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = defaultName;
        }
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    final rawCode = _codeController.text.trim();
    final normalizedCode = AppErrorReporter.normalizeRoomCode(rawCode);
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final roomRepo = context.read<RoomRepository?>();
      if (roomRepo == null) {
        throw Exception('Dịch vụ phòng thi chưa sẵn sàng. Vui lòng thử lại sau.');
      }

      final auth = context.read<AuthProvider?>();
      final isAuth = auth?.isAuthenticated ?? false;

      final result = await roomRepo.joinRoom(
        code: normalizedCode,
        password: password,
        guestName: isAuth ? null : name,
      );

      if (mounted) {
        final guestTokenParam = result.guestToken != null ? '&guestToken=${result.guestToken}' : '';
        context.go(
          '/student_waiting_room?roomId=${result.roomId}&participantId=${result.participantId}$guestTokenParam',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppErrorReporter.formatErrorMessage(e, roomCode: normalizedCode);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tham gia phòng thi', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Về trang chủ',
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Trang chủ',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.luminescenceShadow,
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
                ),
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Icon & Title
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLavender,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: AppTheme.primary,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Vào phòng thi trực tuyến',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Nhập thông tin bên dưới để kết nối vào phòng thi',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error message banner
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 1. Mã phòng thi
                      const Text(
                        'Mã phòng thi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _codeController,
                        style: AppTheme.firaCodeStyle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: PT892341',
                          hintStyle: TextStyle(
                            fontFamily: 'sans-serif',
                            letterSpacing: 0,
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.tag_rounded, color: AppTheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập mã phòng thi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Họ và tên
                      const Text(
                        'Họ và tên thí sinh',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Nhập họ và tên hiển thị trong phòng...',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên của bạn';
                          }
                          if (val.trim().length < 2) {
                            return 'Tên phải có ít nhất 2 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 3. Mật khẩu phòng (nếu có)
                      const Text(
                        'Mật khẩu phòng (nếu có)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Để trống nếu phòng không yêu cầu mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleJoin,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            _isLoading ? 'Đang kết nối...' : 'Tham gia phòng thi ngay',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
