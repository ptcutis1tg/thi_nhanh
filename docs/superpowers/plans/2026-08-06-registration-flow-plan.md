# Registration Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate a sliding registration (Sign Up) form alongside the existing login form in the `GreetingScreen` using Supabase Auth.

**Architecture:** Extend `AuthProvider` with a sign-up method that takes email, password, and full name. Refactor `GreetingScreen`'s login container to use a top navigation bar (TabBar-like) and a `PageView` to slide between the Login and Register forms.

**Tech Stack:** Flutter, Provider, Supabase Flutter

## Global Constraints

- No need to prioritize performance optimization on the greeting screen.
- Maintain existing AppTheme styling.

---

### Task 1: Extend AuthProvider with Sign-Up

**Files:**
- Modify: `lib/core/providers/auth_provider.dart`

**Interfaces:**
- Produces: `Future<void> signUpWithEmail(String email, String password, String fullName)`

- [ ] **Step 1: Write minimal implementation**

Modify `lib/core/providers/auth_provider.dart` to add the `signUpWithEmail` method inside the `AuthProvider` class:

```dart
  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    try {
      await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } catch (e) {
      debugPrint('Lỗi đăng ký Email: $e');
      rethrow;
    }
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/providers/auth_provider.dart
git commit -m "feat(auth): add signUpWithEmail to AuthProvider"
```

---

### Task 2: Implement Sliding Registration Form in GreetingScreen

**Files:**
- Modify: `lib/screens/auth/greeting_screen.dart`

**Interfaces:**
- Consumes: `signUpWithEmail` from `AuthProvider`

- [ ] **Step 1: Update State Variables**

In `_GreetingScreenState`, add the necessary controllers and state:
```dart
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
```
Dispose them in the `dispose` method.

- [ ] **Step 2: Add Register Logic**

Add the `_handleEmailRegister` method to `_GreetingScreenState`:
```dart
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
```

- [ ] **Step 3: Build Navigation Bar & PageView**

Modify `_buildLoginSection` in `_GreetingScreenState`. Remove the single `Column` layout and instead build a container with a custom tab bar and a `PageView`.

```dart
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
```

- [ ] **Step 4: Extract LoginForm & Build RegisterForm**

Create `_buildLoginForm()` matching the old layout, and `_buildRegisterForm()` with the new fields:

```dart
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
```

- [ ] **Step 5: Commit**

```bash
git add lib/screens/auth/greeting_screen.dart
git commit -m "feat(auth): add sliding registration form to GreetingScreen"
```
