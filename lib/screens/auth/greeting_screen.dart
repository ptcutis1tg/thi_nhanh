import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GreetingScreen extends StatelessWidget {
  const GreetingScreen({super.key});

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
              Text(
                'Đăng nhập',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chào mừng bạn quay lại với Thi Nhanh',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                icon: const Icon(Icons.g_mobiledata, size: 24), // Placeholder for Google icon
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
              
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Email của bạn',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: const Text('Đăng nhập'),
              ),
              
              const SizedBox(height: 16),
              
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Thi ngay với mã phòng (Guest)'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
