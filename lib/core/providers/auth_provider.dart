import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/email_verifier.dart';
import '../utils/otp_mailer.dart';

class _OTPRecord {
  final String code;
  final DateTime expiresAt;
  _OTPRecord({required this.code, required this.expiresAt});
}

class AuthProvider extends ChangeNotifier {
  SupabaseClient? _supabaseClient;
  User? _user;
  String? _userName;
  String? _userEmail;
  String? _userAvatarUrl;

  // Local Accounts DB: email -> {'name': fullName, 'password': password, 'avatar': avatarDataUrl}
  Map<String, Map<String, String>> _registeredUsers = {};
  final Map<String, _OTPRecord> _localOTPs = {};

  User? get user => _user;
  bool get isAuthenticated => _user != null || _userEmail != null;

  String get userName =>
      _user?.userMetadata?['full_name'] as String? ??
      _userName ??
      (_userEmail != null && _userEmail!.contains('@')
          ? _userEmail!.split('@').first
          : 'Người dùng');

  String get userEmail => _user?.email ?? _userEmail ?? 'chua_dang_ky@gmail.com';

  String? get userAvatarUrl =>
      (_user?.userMetadata?['avatar_url'] as String?) ?? _userAvatarUrl;

  bool _isPasswordRecoveryMode = false;
  bool get isPasswordRecoveryMode => _isPasswordRecoveryMode;

  void clearPasswordRecoveryMode() {
    _isPasswordRecoveryMode = false;
    notifyListeners();
  }

  AuthProvider({bool isSupabaseInitialized = false}) {
    _loadSavedState();
    if (isSupabaseInitialized) {
      _supabaseClient = Supabase.instance.client;
      _supabaseClient?.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        if (data.event == AuthChangeEvent.passwordRecovery) {
          _isPasswordRecoveryMode = true;
          if (_user?.email != null) {
            _userEmail = _user!.email;
          }
          debugPrint('Đã kích hoạt chế độ khôi phục mật khẩu từ Email Link!');
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
      final usersJson = prefs.getString('local_registered_users');
      if (usersJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(usersJson);
        _registeredUsers = decoded.map((key, value) => MapEntry(
            key,
            Map<String, String>.from(value as Map)));
      }
      _userEmail = prefs.getString('active_user_email');
      _userName = prefs.getString('active_user_name');
      _userAvatarUrl = prefs.getString('active_user_avatar');

      // Restoring name and avatar from registered DB for active email
      if (_userEmail != null) {
        final key = _userEmail!.trim().toLowerCase();
        if (_registeredUsers.containsKey(key)) {
          final savedName = _registeredUsers[key]!['name'];
          if (savedName != null && savedName.isNotEmpty) {
            _userName = savedName;
          }
          final savedAvatar = _registeredUsers[key]!['avatar'];
          if (savedAvatar != null && savedAvatar.isNotEmpty) {
            _userAvatarUrl = savedAvatar;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu tài khoản từ SharedPreferences: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_registered_users', jsonEncode(_registeredUsers));
      if (_userName != null) {
        await prefs.setString('active_user_name', _userName!);
      } else {
        await prefs.remove('active_user_name');
      }
      if (_userEmail != null) {
        await prefs.setString('active_user_email', _userEmail!);
      } else {
        await prefs.remove('active_user_email');
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

  Future<void> signInWithGoogle() async {
    if (_supabaseClient == null) return;
    try {
      await _supabaseClient!.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    final key = email.trim().toLowerCase();
    
    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        debugPrint('Lỗi đăng nhập Supabase Email: $e');
        rethrow;
      }
    }

    if (_registeredUsers.containsKey(key)) {
      final savedPassword = _registeredUsers[key]!['password'];
      if (savedPassword != null && savedPassword.isNotEmpty && savedPassword != password) {
        throw Exception('Mật khẩu không chính xác. Vui lòng thử lại.');
      }
      _userEmail = email;
      _userName = _registeredUsers[key]!['name'];
      _userAvatarUrl = _registeredUsers[key]!['avatar'];
    } else {
      final defaultName = email.contains('@') ? email.split('@').first : 'Người dùng';
      _registeredUsers[key] = {
        'name': defaultName,
        'password': password,
      };
      _userEmail = email;
      _userName = defaultName;
      _userAvatarUrl = null;
    }

    await _saveState();
    notifyListeners();
  }

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  Future<void> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    final cleanEmail = email.trim();
    if (password.length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    // Kiểm tra thực tế xem Email có tồn tại và nhận thư được không
    await EmailVerifier.verifyEmail(cleanEmail);

    final key = cleanEmail.toLowerCase();
    // Kiểm tra trùng lặp Email: Mỗi Gmail chỉ được đăng ký 1 tài khoản duy nhất
    if (_registeredUsers.containsKey(key)) {
      throw Exception('Email "$cleanEmail" đã được sử dụng để đăng ký tài khoản. Mỗi Email chỉ được đăng ký 1 tài khoản duy nhất.');
    }

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {'full_name': fullName},
        );
        if (response.user != null) {
          _user = response.user;
        }
        // Thử tự động đăng nhập luôn nếu session khả dụng
        if (response.session == null) {
          try {
            await _supabaseClient!.auth.signInWithPassword(
              email: cleanEmail,
              password: password,
            );
          } catch (_) {}
        }
      } catch (e) {
        final str = e.toString();
        if (str.contains('User already registered') || str.contains('user_already_exists')) {
          throw Exception('Email "$cleanEmail" đã được đăng ký tài khoản trong hệ thống. Vui lòng Đăng nhập.');
        }
        // Nếu dính giới hạn tần suất gửi email từ Supabase (over_email_send_rate_limit / 429), bỏ qua và cho phép đăng ký trực tiếp
        if (str.contains('rate limit') || str.contains('over_email_send_rate_limit') || str.contains('429')) {
          debugPrint('Bỏ qua giới hạn tần suất gửi mail của Supabase, tiến hành đăng ký trực tiếp: $e');
        } else {
          rethrow;
        }
      }
    }

    _registeredUsers[key] = {
      'name': fullName,
      'password': password,
    };

    _userEmail = cleanEmail;
    _userName = fullName;
    _userAvatarUrl = null;

    await _saveState();
    notifyListeners();
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    await EmailVerifier.verifyEmail(cleanEmail);

    final key = cleanEmail.toLowerCase();
    // Kiểm tra xem Email đã đăng ký tài khoản trong hệ thống chưa
    if (!_registeredUsers.containsKey(key)) {
      throw Exception('Email "$cleanEmail" chưa được đăng ký tài khoản trong hệ thống.');
    }

    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    _localOTPs[key] = _OTPRecord(
      code: randomOtp,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );

    // Gửi mail tự động trực tiếp chứa mã 6 số về Gmail của người dùng
    await OTPMailer.sendOTPEmail(recipientEmail: cleanEmail, otpCode: randomOtp);

    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.resetPasswordForEmail(cleanEmail);
      } catch (e) {
        final str = e.toString();
        if (str.contains('rate limit') || str.contains('over_email_send_rate_limit') || str.contains('429')) {
          debugPrint('Dính Rate Limit Supabase, cấp mã OTP ngẫu nhiên cục bộ: $randomOtp');
          return randomOtp;
        } else {
          rethrow;
        }
      }
    }
    return randomOtp;
  }

  Future<void> verifyPasswordResetOTP(String email, String otpCode) async {
    final cleanEmail = email.trim();
    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      throw Exception('Mã OTP phải bao gồm đúng 6 chữ số.');
    }

    bool isVerified = false;

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.verifyOTP(
          email: cleanEmail,
          token: cleanOtp,
          type: OtpType.recovery,
        );
        if (response.user != null) {
          _user = response.user;
        }
        isVerified = true;
      } catch (e) {
        debugPrint('Lỗi xác nhận mã OTP Supabase: $e');
      }
    }

    if (!isVerified) {
      final key = cleanEmail.toLowerCase();
      final record = _localOTPs[key];
      if (record != null && DateTime.now().isBefore(record.expiresAt)) {
        if (record.code == cleanOtp) {
          isVerified = true;
        }
      }
    }

    if (!isVerified) {
      throw Exception('Mã OTP không chính xác hoặc đã hết hạn. Vui lòng kiểm tra lại.');
    }
  }

  Future<void> updateNewPassword(String email, String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    final key = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(key)) {
      _registeredUsers[key]!['password'] = newPassword;
    } else {
      _registeredUsers[key] = {
        'name': userName,
        'password': newPassword,
      };
    }

    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (e) {
        debugPrint('Lỗi cập nhật mật khẩu Supabase: $e');
        rethrow;
      }
    }

    await _saveState();
    notifyListeners();
  }

  Future<void> updateProfile(String newName) async {
    _userName = newName;
    if (_userEmail != null) {
      final key = _userEmail!.trim().toLowerCase();
      if (_registeredUsers.containsKey(key)) {
        _registeredUsers[key]!['name'] = newName;
      } else {
        _registeredUsers[key] = {
          'name': newName,
          'password': '',
        };
      }
    }
    await _saveState();
    notifyListeners();
  }

  Future<void> updateAvatar(String avatarDataUrl) async {
    _userAvatarUrl = avatarDataUrl;
    if (_userEmail != null) {
      final key = _userEmail!.trim().toLowerCase();
      if (_registeredUsers.containsKey(key)) {
        _registeredUsers[key]!['avatar'] = avatarDataUrl;
      } else {
        _registeredUsers[key] = {
          'name': userName,
          'password': '',
          'avatar': avatarDataUrl,
        };
      }
    }
    await _saveState();
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_userEmail == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }
    final key = _userEmail!.trim().toLowerCase();
    if (_registeredUsers.containsKey(key)) {
      final savedPassword = _registeredUsers[key]!['password'];
      if (savedPassword != null && savedPassword.isNotEmpty && savedPassword != currentPassword) {
        throw Exception('Mật khẩu hiện tại không chính xác.');
      }
      _registeredUsers[key]!['password'] = newPassword;
    } else {
      _registeredUsers[key] = {
        'name': userName,
        'password': newPassword,
      };
    }
    await _saveState();
    notifyListeners();
  }

  Future<void> signOut() async {
    _userName = null;
    _userEmail = null;
    _userAvatarUrl = null;
    await _supabaseClient?.auth.signOut();
    await _saveState();
    notifyListeners();
  }
}
