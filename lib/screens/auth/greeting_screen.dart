import 'package:flutter/material.dart';
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
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  bool _isLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Vui lòng nhập Email và Mật khẩu');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      _showError('Đăng nhập thất bại: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.'), backgroundColor: Colors.green),
        );
        _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } catch (e) {
      _showError('Đăng ký thất bại: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      // Wait for auth state change to route automatically, or redirect
    } catch (e) {
      _showError('Đăng nhập Google thất bại: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          
          if (isDesktop) {
            return Row(
              children: [
                Expanded(child: _buildWelcomeSection(context)),
                Expanded(child: _buildLoginSection(context)),
              ],
            );
          }
          
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: constraints.maxHeight * 0.4,
                  child: _buildWelcomeSection(context),
                ),
                _buildLoginSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE4DFFF),
            Color(0xFFC5C0FF),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ôn thi thần tốc, xếp hạng thời gian thực',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 48,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Placeholder for Illustration
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, size: 120, color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginSection(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Tab Bar
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: Column(
                        children: [
                          Text(
                            'Đăng nhập',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _currentPage == 0 ? AppTheme.primary : AppTheme.textSecondary,
                              fontWeight: _currentPage == 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(height: 2, color: _currentPage == 0 ? AppTheme.primary : Colors.transparent),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: Column(
                        children: [
                          Text(
                            'Đăng ký',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _currentPage == 1 ? AppTheme.primary : AppTheme.textSecondary,
                              fontWeight: _currentPage == 1 ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(height: 2, color: _currentPage == 1 ? AppTheme.primary : Colors.transparent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Forms PageView
              SizedBox(
                height: 480, // Fixed height to prevent unbounded errors
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildLoginForm(),
                    _buildRegisterForm(),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Thi ngay với mã phòng (Guest)'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleLogin,
            icon: const Icon(Icons.g_mobiledata, size: 24),
            label: const Text('Tiếp tục với Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppTheme.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('hoặc', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                Expanded(child: Divider(color: AppTheme.border)),
              ],
            ),
          ),
          TextField(
            controller: _emailController,
            enabled: !_isLoading,
            decoration: const InputDecoration(hintText: 'Email của bạn', prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Mật khẩu', prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            enabled: !_isLoading,
            decoration: const InputDecoration(hintText: 'Họ tên', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            enabled: !_isLoading,
            decoration: const InputDecoration(hintText: 'Email của bạn', prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Mật khẩu', prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            enabled: !_isLoading,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Xác nhận mật khẩu', prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailRegister,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Đăng ký'),
          ),
        ],
      ),
    );
  }
}
