import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/email_verifier.dart';
import '../utils/supabase_retry_helper.dart';

class AuthProvider extends ChangeNotifier {
  SupabaseClient? _supabaseClient;
  User? _user;
  String? _userName;
  String? _userEmail;
  String? _userAvatarUrl;

  User? get user => _user;
  bool get isAuthenticated =>
      _user != null || (_supabaseClient == null && _userEmail != null);
  bool get hasSupabaseSession => _supabaseClient?.auth.currentSession != null;
  bool get isGoogleUser =>
      _user?.appMetadata['provider'] == 'google' ||
      (_user?.identities?.any((id) => id.provider == 'google') ?? false);

  String get userName {
    final metaName = _user?.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.isNotEmpty) return metaName;
    if (_userName != null && _userName!.isNotEmpty) return _userName!;
    if (_userEmail != null && _userEmail!.contains('@')) {
      return _userEmail!.split('@').first;
    }
    return 'Người dùng';
  }

  String get userEmail => _user?.email ?? _userEmail ?? '';

  String? get userAvatarUrl =>
      (_user?.userMetadata?['avatar_url'] as String?) ?? _userAvatarUrl;

  bool _isPasswordRecoveryMode = false;
  bool get isPasswordRecoveryMode => _isPasswordRecoveryMode;

  void clearPasswordRecoveryMode() {
    _isPasswordRecoveryMode = false;
    notifyListeners();
  }

  AuthProvider({bool isSupabaseInitialized = false}) {
    if (isSupabaseInitialized) {
      _supabaseClient = Supabase.instance.client;
      _user = _supabaseClient?.auth.currentUser;
      _supabaseClient?.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        if (data.event == AuthChangeEvent.passwordRecovery) {
          _isPasswordRecoveryMode = true;
          if (_user?.email != null) {
            _userEmail = _user!.email;
          }
          debugPrint('Đã kích hoạt chế độ khôi phục mật khẩu từ Supabase Recovery Event!');
        } else if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.tokenRefreshed ||
            data.event == AuthChangeEvent.userUpdated) {
          _syncProfileFromUser();
        } else if (data.event == AuthChangeEvent.signedOut) {
          _userName = null;
          _userEmail = null;
          _userAvatarUrl = null;
          _saveState();
        }
        notifyListeners();
      });
    }
  }

  Future<void> init() async {
    await _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userEmail ??= prefs.getString('active_user_email');
      _userName ??= prefs.getString('active_user_name');
      _userAvatarUrl ??= prefs.getString('active_user_avatar');
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu tài khoản từ SharedPreferences: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userEmail != null) {
        await prefs.setString('active_user_email', _userEmail!);
      } else {
        await prefs.remove('active_user_email');
      }
      if (_userName != null) {
        await prefs.setString('active_user_name', _userName!);
      } else {
        await prefs.remove('active_user_name');
      }
      if (_userAvatarUrl != null) {
        await prefs.setString('active_user_avatar', _userAvatarUrl!);
      } else {
        await prefs.remove('active_user_avatar');
      }
    } catch (e) {
      debugPrint('Lỗi lưu dữ liệu tài khoản vào SharedPreferences: $e');
    }
  }

  Future<void> _syncProfileFromUser() async {
    final u = _user;
    if (u == null) return;
    _userEmail = u.email;
    final metaName = u.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.isNotEmpty) {
      _userName = metaName;
    }
    final metaAvatar = u.userMetadata?['avatar_url'] as String?;
    if (metaAvatar != null && metaAvatar.isNotEmpty) {
      _userAvatarUrl = metaAvatar;
    }
    await _saveState();
  }

  /// Calculates the full redirect URL for web OAuth and auth callbacks,
  /// preserving subdirectory paths (such as GitHub Pages /thi_nhanh/)
  static String? getWebRedirectUrl([Uri? customUri]) {
    if (!kIsWeb && customUri == null) return null;
    final uri = customUri ?? Uri.base;
    final origin = uri.origin;
    var path = uri.path;
    if (path.endsWith('index.html')) {
      path = path.substring(0, path.length - 'index.html'.length);
    }
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    return '$origin$path';
  }

  Future<void> signInWithGoogle() async {
    if (_supabaseClient != null) {
      await _supabaseClient!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: getWebRedirectUrl(),
      );
    } else {
      _userEmail = 'demo_google_user@gmail.com';
      _userName = 'Google User (Demo)';
      _userAvatarUrl = null;
      await _saveState();
      notifyListeners();
    }
  }

  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        _user = response.user;
        await _syncProfileFromUser();
        notifyListeners();
        return response;
      } catch (e) {
        debugPrint('Lỗi đăng nhập Supabase: $e');
        rethrow;
      }
    } else {
      _userEmail = cleanEmail;
      _userName = cleanEmail.split('@').first;
      await _saveState();
      notifyListeners();
      return null;
    }
  }

  Future<AuthResponse?> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    final cleanEmail = email.trim();
    if (password.length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    EmailVerifier.verifyEmail(cleanEmail);

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {'full_name': fullName},
        );
        _user = response.user;
        if (response.session != null) {
          await _syncProfileFromUser();
        }
        notifyListeners();
        return response;
      } catch (e) {
        debugPrint('Lỗi đăng ký Supabase: $e');
        rethrow;
      }
    } else {
      _userEmail = cleanEmail;
      _userName = fullName;
      await _saveState();
      notifyListeners();
      return null;
    }
  }

  Future<AuthResponse?> verifySignUpOTP(String email, String otpCode) async {
    final cleanEmail = email.trim();
    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      throw Exception('Mã OTP phải bao gồm đúng 6 chữ số.');
    }

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.verifyOTP(
          email: cleanEmail,
          token: cleanOtp,
          type: OtpType.signup,
        );
        _user = response.user;
        if (_user != null) {
          await _syncProfileFromUser();
          final userId = _user!.id;
          try {
            await SupabaseRetryHelper.run(() async {
              await _supabaseClient!.from('profiles').upsert({
                'id': userId,
                'display_name': userName,
                'updated_at': DateTime.now().toIso8601String(),
              });
            });
          } catch (eDb) {
            debugPrint('Lỗi đồng bộ hồ sơ sau kích hoạt OTP: $eDb');
          }
        }
        notifyListeners();
        return response;
      } catch (e) {
        debugPrint('Lỗi xác thực mã OTP đăng ký: $e');
        rethrow;
      }
    } else {
      _userEmail = cleanEmail;
      notifyListeners();
      return null;
    }
  }

  Future<void> sendPasswordResetOTP(String email) async {
    final cleanEmail = email.trim();
    EmailVerifier.verifyEmail(cleanEmail);

    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.resetPasswordForEmail(cleanEmail);
      } catch (e) {
        debugPrint('Lỗi gửi OTP đặt lại mật khẩu: $e');
        rethrow;
      }
    }
  }

  Future<AuthResponse?> verifyPasswordResetOTP(String email, String otpCode) async {
    final cleanEmail = email.trim();
    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      throw Exception('Mã OTP phải bao gồm đúng 6 chữ số.');
    }

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.verifyOTP(
          email: cleanEmail,
          token: cleanOtp,
          type: OtpType.recovery,
        );
        _user = response.user;
        _isPasswordRecoveryMode = true;
        notifyListeners();
        return response;
      } catch (e) {
        debugPrint('Lỗi xác thực OTP khôi phục mật khẩu: $e');
        rethrow;
      }
    } else {
      _isPasswordRecoveryMode = true;
      notifyListeners();
      return null;
    }
  }

  Future<UserResponse?> updateNewPassword(String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        _isPasswordRecoveryMode = false;
        notifyListeners();
        return response;
      } catch (e) {
        debugPrint('Lỗi cập nhật mật khẩu mới: $e');
        rethrow;
      }
    } else {
      _isPasswordRecoveryMode = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final email = userEmail;
    if (email.isEmpty) {
      throw Exception('Bạn chưa đăng nhập.');
    }
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    if (_supabaseClient != null) {
      try {
        // 1. Xác thực lại mật khẩu hiện tại để bảo mật
        await _supabaseClient!.auth.signInWithPassword(
          email: email,
          password: currentPassword,
        );

        // 2. Cập nhật mật khẩu mới lên Supabase
        await _supabaseClient!.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid login credentials') ||
            errStr.contains('invalid_grant')) {
          throw Exception('Mật khẩu hiện tại không chính xác.');
        }
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> updateProfile(String newName) async {
    _userName = newName;
    await _saveState();
    final userId = _user?.id;
    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.updateUser(
          UserAttributes(data: {'full_name': newName}),
        );
        if (userId != null) {
          await SupabaseRetryHelper.run(() async {
            await _supabaseClient!.from('profiles').upsert({
              'id': userId,
              'display_name': newName,
              'updated_at': DateTime.now().toIso8601String(),
            });
          });
        }
      } catch (e) {
        debugPrint('Lỗi cập nhật hồ sơ người dùng: $e');
      }
    }
    notifyListeners();
  }

  Future<void> updateAvatar(String avatarDataUrl) async {
    _userAvatarUrl = avatarDataUrl;
    await _saveState();
    final userId = _user?.id;
    if (_supabaseClient != null && userId != null) {
      try {
        await SupabaseRetryHelper.run(() async {
          await _supabaseClient!.from('profiles').upsert({
            'id': userId,
            'avatar_url': avatarDataUrl,
            'updated_at': DateTime.now().toIso8601String(),
          });
        });
      } catch (e) {
        debugPrint('Lỗi cập nhật ảnh đại diện: $e');
      }
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    _userName = null;
    _userEmail = null;
    _userAvatarUrl = null;
    _user = null;
    _isPasswordRecoveryMode = false;
    await _supabaseClient?.auth.signOut();
    await _saveState();
    notifyListeners();
  }
}
