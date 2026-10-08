import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Supabase restores the browser session after the OAuth redirect before
    // this screen is built. Send signed-in users straight to the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        context.go('/home');
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập Email và Mật khẩu');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signInWithEmail(email, password);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('email_not_confirmed')) {
        _showSignUpOtpDialog(email);
      } else {
        _showError('Đăng nhập thất bại: ${_friendlyAuthErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthErrorMessage(dynamic e) {
    final str = e.toString().toLowerCase();
    if (str.contains('email_not_confirmed')) {
      return 'Email của bạn chưa được kích hoạt mã OTP! Vui lòng nhập mã OTP để hoàn tất.';
    }
    if (str.contains('over_email_send_rate_limit') || str.contains('rate limit')) {
      return 'Bạn đã gửi yêu cầu quá nhiều lần trong thời gian ngắn. Vui lòng chờ 1 - 2 phút rồi thử lại nhé!';
    }
    if (str.contains('user already registered') || str.contains('already exists')) {
      return 'Email này đã được đăng ký tài khoản trước đó. Vui lòng chuyển sang tab Đăng nhập.';
    }
    if (str.contains('invalid login credentials') || str.contains('invalid_grant')) {
      return 'Email hoặc mật khẩu không chính xác.';
    }
    if (str.contains('otp_expired') || str.contains('token has expired')) {
      return 'Mã OTP đã hết hạn hoặc không chính xác. Vui lòng thử lại.';
    }
    return e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
  }

  Future<void> _handleEmailRegister() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (password != confirmPassword) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await context.read<AuthProvider>().signUpWithEmail(
            email,
            password,
            name,
          );
      if (mounted) {
        if (response != null && response.session == null) {
          // Supabase yêu cầu xác thực OTP 8 số
          _showSignUpOtpDialog(email);
        } else {
          _showSuccess('Đăng ký thành công! Chào mừng bạn.');
          context.go('/home');
        }
      }
    } catch (e) {
      _showError('Đăng ký thất bại: ${_friendlyAuthErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSignUpOtpDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SignUpOtpDialog(
        email: email,
        onSuccess: () {
          _showSuccess('Xác thực tài khoản thành công! Chào mừng bạn.');
          context.go('/home');
        },
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      _showError('Đăng nhập Google thất bại: ${_friendlyAuthErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() {
    context.push('/reset-password');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Clean Background Image (flying books + lavender background without baked card)
          Positioned.fill(
            child: Image.asset(
              'assets/images/clean_login_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF1EDFE),
                      Color(0xFFE5DEFF),
                      Color(0xFFF6F3FF),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Foreground Main Interactive Login Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 38),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6557E8).withValues(alpha: 0.08),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Title
                        Text(
                          _isRegisterMode ? 'Đăng ký' : 'Đăng nhập',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegisterMode
                              ? 'Tạo tài khoản mới để bắt đầu với Thi Nhanh'
                              : 'Chào mừng bạn quay lại với Thi Nhanh',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Continue with Google Button
                        OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            backgroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildGoogleIcon(),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider "HOẶC ĐĂNG NHẬP BẰNG EMAIL"
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                _isRegisterMode
                                    ? 'HOẶC ĐĂNG KÝ BẰNG EMAIL'
                                    : 'HOẶC ĐĂNG NHẬP BẰNG EMAIL',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Name Field (only in register mode)
                        if (_isRegisterMode) ...[
                          const Text(
                            'Họ và tên',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            enabled: !_isLoading,
                            style: const TextStyle(fontSize: 14),
                            decoration: _buildInputDecoration(
                              hintText: 'Nhập họ và tên của bạn',
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Email Field
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 14),
                          decoration: _buildInputDecoration(
                            hintText: 'Nhập email của bạn',
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Password Field Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mật khẩu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if (!_isRegisterMode)
                              GestureDetector(
                                onTap: _handleForgotPassword,
                                child: const Text(
                                  'Quên mật khẩu?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8B72F6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: _isPasswordObscured,
                          style: const TextStyle(fontSize: 14),
                          decoration: _buildInputDecoration(
                            hintText: 'Nhập mật khẩu',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordObscured = !_isPasswordObscured;
                                });
                              },
                            ),
                          ),
                        ),

                        // Confirm Password Field (only in register mode)
                        if (_isRegisterMode) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Xác nhận mật khẩu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            enabled: !_isLoading,
                            obscureText: _isConfirmPasswordObscured,
                            style: const TextStyle(fontSize: 14),
                            decoration: _buildInputDecoration(
                              hintText: 'Nhập lại mật khẩu',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordObscured
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordObscured =
                                        !_isConfirmPasswordObscured;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Primary Button ("Đăng nhập" / "Đăng ký")
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_isRegisterMode ? _handleEmailRegister : _handleEmailLogin),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isRegisterMode ? 'Đăng ký' : 'Đăng nhập',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Guest Button Link ("Trải nghiệm ngay (Chế độ Khách)")
                        OutlinedButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(
                            Icons.explore_outlined,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          label: const Text(
                            'Trải nghiệm ngay (Chế độ Khách)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryLight, width: 1.2),
                            backgroundColor: AppTheme.surfaceLavender.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Register / Login Toggle Link
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isRegisterMode
                                    ? 'Đã có tài khoản? '
                                    : 'Chưa có tài khoản? ',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isRegisterMode = !_isRegisterMode;
                                  });
                                },
                                child: Text(
                                  _isRegisterMode ? 'Đăng nhập ngay' : 'Đăng ký ngay',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF8B72F6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppTheme.textPlaceholder,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppTheme.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildGoogleIcon() {
    return Image.asset(
      'assets/images/google_logo.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.g_mobiledata_rounded,
        size: 22,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

class _SignUpOtpDialog extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  const _SignUpOtpDialog({
    required this.email,
    required this.onSuccess,
  });

  @override
  State<_SignUpOtpDialog> createState() => _SignUpOtpDialogState();
}

class _SignUpOtpDialogState extends State<_SignUpOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  int _countdown = 60;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 8 || int.tryParse(otp) == null) {
      setState(() => _errorMessage = 'Vui lòng nhập đủ 8 chữ số mã OTP.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().verifySignUpOTP(widget.email, otp);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString().toLowerCase();
        if (err.contains('expired') || err.contains('token has expired') || err.contains('otp_expired')) {
          setState(() => _errorMessage = 'Mã OTP đã hết hạn. Vui lòng bấm gửi lại mã.');
        } else {
          setState(() => _errorMessage = 'Mã OTP không chính xác. Vui lòng kiểm tra lại.');
        }
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_countdown > 0) return;
    setState(() => _errorMessage = null);
    try {
      await context.read<AuthProvider>().sendPasswordResetOTP(widget.email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã OTP 8 số về hộp thư của bạn!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Chưa thể gửi lại mã lúc này. Vui lòng thử lại sau.');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EDFE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Color(0xFF8B72F6),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nhập mã OTP kích hoạt',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Mã xác thực gồm 8 chữ số đã được gửi tới email:\n${widget.email}\n(Vui lòng kiểm tra hộp thư đến và thư mục Spam/Rác)',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                textAlign: TextAlign.center,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: '00000000',
                  hintStyle: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    letterSpacing: 6,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B72F6), width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _handleVerify(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _countdown > 0 ? null : _handleResend,
                    child: Text(
                      _countdown > 0 ? 'Gửi lại mã ($_countdown s)' : 'Gửi lại mã OTP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _countdown > 0 ? const Color(0xFF94A3B8) : const Color(0xFF8B72F6),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isVerifying ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B72F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kích hoạt tài khoản',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

