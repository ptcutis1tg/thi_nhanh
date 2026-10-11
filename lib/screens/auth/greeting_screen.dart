import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_interactive_hover_card.dart';

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
  bool _rememberMe = false;
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
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 720;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD9FFF7), Color(0xFFF7FFFE), Color(0xFFF0F4FF)],
            stops: [0, .52, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthGridBackground()),
            SafeArea(
              child: Column(
                children: [
                  _buildPageHeader(isCompact),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isCompact ? 16 : 24,
                        isCompact ? 18 : 34,
                        isCompact ? 16 : 24,
                        24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: _buildAuthCard(isCompact),
                        ),
                      ),
                    ),
                  ),
                  if (!isCompact) _buildPageFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(bool isCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 48, vertical: 18),
      child: Row(
        children: [
          _buildBrandMark(size: 42),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAROVA',
                  style: TextStyle(
                    color: AppTheme.primaryDarker,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (!isCompact)
                  const Text(
                    'HỌC TẬP · KẾT NỐI · BỨT PHÁ',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!isCompact) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .78),
                border: Border.all(color: AppTheme.primaryLight),
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 8, color: AppTheme.success),
                  SizedBox(width: 7),
                  Text(
                    'Hệ thống sẵn sàng',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
          ],
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: Text(isCompact ? 'Trợ giúp' : 'Hỗ trợ kỹ thuật'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(bool isCompact) {
    return AppInteractiveHoverCard(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 24 : 34,
        isCompact ? 26 : 30,
        isCompact ? 24 : 34,
        isCompact ? 24 : 28,
      ),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _buildBrandMark(size: 56, glow: true)),
          const SizedBox(height: 16),
          Text(
            _isRegisterMode ? 'Tạo tài khoản' : 'Đăng nhập',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMain,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isRegisterMode
                ? 'Bắt đầu hành trình học tập cùng PAROVA'
                : 'Truy cập không gian học tập của bạn',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 22),
          OutlinedButton(
            key: const Key('google-login-button'),
            onPressed: _isLoading ? null : _handleGoogleLogin,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textMain,
              side: const BorderSide(color: AppTheme.primaryLight, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleIcon(),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Đăng nhập với Google',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider(color: AppTheme.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'HOẶC',
                  style: TextStyle(
                    color: AppTheme.textPlaceholder,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.border)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isRegisterMode) ...[
            _buildFieldLabel('HỌ VÀ TÊN'),
            const SizedBox(height: 7),
            TextField(
              controller: _nameController,
              enabled: !_isLoading,
              textInputAction: TextInputAction.next,
              decoration: _buildInputDecoration(
                hintText: 'Nguyễn Văn A',
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 15),
          ],
          _buildFieldLabel('EMAIL HOẶC TÊN ĐĂNG NHẬP'),
          const SizedBox(height: 7),
          TextField(
            key: const Key('login-email-field'),
            controller: _emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hintText: 'hocvien@example.com',
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 15),
          _buildFieldLabel('MẬT KHẨU'),
          const SizedBox(height: 7),
          TextField(
            key: const Key('login-password-field'),
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: _isPasswordObscured,
            textInputAction: _isRegisterMode ? TextInputAction.next : TextInputAction.done,
            onSubmitted: (_) {
              if (!_isRegisterMode && !_isLoading) _handleEmailLogin();
            },
            decoration: _buildInputDecoration(
              hintText: '••••••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _isPasswordObscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                icon: Icon(
                  _isPasswordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (_isRegisterMode) ...[
            const SizedBox(height: 15),
            _buildFieldLabel('XÁC NHẬN MẬT KHẨU'),
            const SizedBox(height: 7),
            TextField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              obscureText: _isConfirmPasswordObscured,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_isLoading) _handleEmailRegister();
              },
              decoration: _buildInputDecoration(
                hintText: 'Nhập lại mật khẩu',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _isConfirmPasswordObscured = !_isConfirmPasswordObscured,
                  ),
                  icon: Icon(
                    _isConfirmPasswordObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) => setState(() => _rememberMe = value ?? false),
                    activeColor: AppTheme.primaryDark,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Ghi nhớ đăng nhập',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    foregroundColor: AppTheme.primaryDarker,
                  ),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 13),
          ElevatedButton(
            key: const Key('email-auth-submit-button'),
            onPressed: _isLoading
                ? null
                : (_isRegisterMode ? _handleEmailRegister : _handleEmailLogin),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              elevation: 7,
              shadowColor: AppTheme.primary.withValues(alpha: .35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegisterMode ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 7),
                      const Icon(Icons.arrow_forward_rounded, size: 17),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                _isRegisterMode ? 'Đã có tài khoản? ' : 'Chưa có tài khoản? ',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              InkWell(
                onTap: () => setState(() => _isRegisterMode = !_isRegisterMode),
                child: Text(
                  _isRegisterMode ? 'Đăng nhập ngay' : 'Đăng ký ngay',
                  style: const TextStyle(
                    color: AppTheme.primaryDarker,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => context.go('/home'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            child: const Text(
              'Tiếp tục với chế độ khách',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandMark({required double size, bool glow = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .27),
        border: Border.all(color: AppTheme.primaryLight),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: .38),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .27),
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: Image.asset(
            'assets/images/parova_symbol.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .35,
      ),
    );
  }

  Widget _buildPageFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 8, 48, 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '© 2026 PAROVA. Nền tảng học tập và thi trực tuyến.',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            ),
          ),
          const SizedBox(width: 24),
          _footerLink('Điều khoản dịch vụ'),
          const SizedBox(width: 26),
          _footerLink('Chính sách quyền riêng tư'),
          const SizedBox(width: 26),
          _footerLink('Hướng dẫn thí sinh'),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: AppTheme.textSecondary,
        minimumSize: const Size(0, 28),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
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
      fillColor: Colors.white.withValues(alpha: .9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
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
      prefixIcon: prefixIcon == null
          ? null
          : IconTheme(
              data: const IconThemeData(color: AppTheme.primaryDark, size: 19),
              child: prefixIcon,
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

class _AuthGridBackground extends StatelessWidget {
  const _AuthGridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthGridPainter());
  }
}

class _AuthGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: .055)
      ..strokeWidth = 1;
    const gap = 56.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [AppTheme.primary.withValues(alpha: .16), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * .5, size.height * .68),
        radius: size.width * .32,
      ));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      await context.read<AuthProvider>().resendSignUpOTP(widget.email);
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

