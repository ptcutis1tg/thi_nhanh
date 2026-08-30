import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  final Set<String> _verifiedResetEmails = {};

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

  Future<void> signInWithGoogle() async {
    if (_supabaseClient != null) {
      await _supabaseClient!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
    } else {
      _userEmail = 'demo_google_user@gmail.com';
      _userName = 'Google User (Demo)';
      _userAvatarUrl = null;
      await _saveState();
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final key = cleanEmail.toLowerCase();

    bool isLocalPasswordValid = false;
    if (_registeredUsers.containsKey(key)) {
      final savedPassword = _registeredUsers[key]!['password'];
      if (savedPassword != null && savedPassword.isNotEmpty && savedPassword == password) {
        isLocalPasswordValid = true;
      }
    }

    if (_supabaseClient != null) {
      try {
        final response = await _supabaseClient!.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (response.user != null) {
          _user = response.user;
        }
      } catch (e) {
        debugPrint('Bỏ qua lỗi đăng ký Supabase (dùng chế độ đăng ký local): $e');
      }
    }

    if (_registeredUsers.containsKey(key)) {
      final savedPassword = _registeredUsers[key]!['password'];
      if (savedPassword != null && savedPassword.isNotEmpty && savedPassword != password) {
        throw Exception('Mật khẩu không chính xác. Vui lòng thử lại.');
      }
      _userEmail = cleanEmail;
      _userName = _registeredUsers[key]!['name'];
      _userAvatarUrl = _registeredUsers[key]!['avatar'];
    } else {
      final defaultName = cleanEmail.contains('@') ? cleanEmail.split('@').first : 'Người dùng';
      _registeredUsers[key] = {
        'name': defaultName,
        'password': password,
      };
      _userEmail = cleanEmail;
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

  String _generate6DigitOTP() {
    return (100000 + Random().nextInt(900000)).toString();
  }

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

    // Tự động sinh mã 6 số OTP riêng ban đầu cho tài khoản khi được tạo
    final initialOtp = _generate6DigitOTP();
    final initialExpiresAt = DateTime.now().add(const Duration(hours: 24));

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

        // Lưu mã OTP 6 số vào bảng user_otps trên Supabase DB
        try {
          await _supabaseClient!.from('user_otps').upsert({
            'email': cleanEmail,
            'user_id': _user?.id,
            'otp_code': initialOtp,
            'expires_at': initialExpiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (eDb) {
          debugPrint('Lỗi lưu OTP ban đầu vào Supabase DB: $eDb');
        }
      } catch (e) {
        debugPrint('Bỏ qua lỗi đăng ký Supabase (dùng chế độ đăng ký local): $e');
      }
    }

    _registeredUsers[key] = {
      'name': fullName,
      'password': password,
      'otp': initialOtp,
      'otp_expires_at': initialExpiresAt.toIso8601String(),
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
    // Chỉ cho phép đổi mật khẩu đối với tài khoản đã được đăng ký
    if (!_registeredUsers.containsKey(key)) {
      throw Exception('Email "$cleanEmail" chưa được đăng ký trong hệ thống. Vui lòng kiểm tra lại hoặc tạo tài khoản mới.');
    }

    // Sinh 1 mã 6 số mới mỗi khi được yêu cầu liên quan đến OTP (đổi mật khẩu...)
    final randomOtp = _generate6DigitOTP();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    // 1. Lưu mã OTP 6 số mới vào database local tương ứng với tài khoản đó
    _registeredUsers[key]!['otp'] = randomOtp;
    _registeredUsers[key]!['otp_expires_at'] = expiresAt.toIso8601String();
    _localOTPs[key] = _OTPRecord(
      code: randomOtp,
      expiresAt: expiresAt,
    );
    await _saveState();

    // 2. Đồng bộ mã OTP 6 số mới vào CSDL Supabase user_otps
    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.from('user_otps').upsert({
          'email': cleanEmail,
          'user_id': _user?.id,
          'otp_code': randomOtp,
          'expires_at': expiresAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (eDb) {
        debugPrint('Lỗi đồng bộ OTP mới vào Supabase DB: $eDb');
      }
    }

    // 3. Gửi mã 6 số đấy về email cho user
    await OTPMailer.sendOTPEmail(recipientEmail: cleanEmail, otpCode: randomOtp);

    // 4. Thử qua Supabase Auth nếu khả dụng
    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.resetPasswordForEmail(
          cleanEmail,
          redirectTo: kIsWeb ? Uri.base.origin : null,
        );
      } catch (e) {
        try {
          await _supabaseClient!.auth.signInWithOtp(
            email: cleanEmail,
            shouldCreateUser: false,
          );
        } catch (e2) {
          debugPrint('Thông báo Supabase Auth OTP: $e2');
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

    final key = cleanEmail.toLowerCase();
    bool isVerified = false;

    // 1. Kiểm tra với Supabase Database user_otps
    if (_supabaseClient != null) {
      try {
        final res = await _supabaseClient!
            .from('user_otps')
            .select()
            .eq('email', cleanEmail)
            .maybeSingle();
        if (res != null) {
          final dbOtp = res['otp_code'] as String?;
          final dbExpires = DateTime.tryParse(res['expires_at'] as String? ?? '');
          if (dbOtp == cleanOtp && dbExpires != null && DateTime.now().isBefore(dbExpires)) {
            isVerified = true;
          }
        }
      } catch (e) {
        debugPrint('Lỗi đối chiếu mã OTP từ Supabase DB: $e');
      }

      if (!isVerified) {
        for (final type in [OtpType.recovery, OtpType.magiclink, OtpType.email]) {
          try {
            final response = await _supabaseClient!.auth.verifyOTP(
              email: cleanEmail,
              token: cleanOtp,
              type: type,
            );
            if (response.user != null) {
              _user = response.user;
            }
            isVerified = true;
            break;
          } catch (e) {
            debugPrint('Lỗi xác nhận mã OTP Supabase ($type): $e');
          }
        }
      }
    }

    // 2. Kiểm tra mã OTP 6 số lưu trong Database tương ứng của tài khoản (Local / In-memory)
    if (!isVerified && _registeredUsers.containsKey(key)) {
      final savedOtp = _registeredUsers[key]!['otp'];
      final savedExpStr = _registeredUsers[key]!['otp_expires_at'];
      final savedExp = savedExpStr != null ? DateTime.tryParse(savedExpStr) : null;
      if (savedOtp == cleanOtp && (savedExp == null || DateTime.now().isBefore(savedExp))) {
        isVerified = true;
      }
    }

    if (!isVerified) {
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

    // Đã xác thực thành công: Hủy mã OTP (tránh tái sử dụng) và ghi nhận trạng thái xác nhận cho email này
    _localOTPs.remove(key);
    if (_registeredUsers.containsKey(key)) {
      _registeredUsers[key]!.remove('otp');
      _registeredUsers[key]!.remove('otp_expires_at');
    }
    _verifiedResetEmails.add(key);
    await _saveState();
  }

  Future<void> updateNewPassword(String email, String newPassword) async {
    final cleanEmail = email.trim();
    final key = cleanEmail.toLowerCase();

    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    if (!isPasswordRecoveryMode && !_verifiedResetEmails.contains(key)) {
      throw Exception('Yêu cầu không hợp lệ. Vui lòng xác thực mã OTP trước khi đổi mật khẩu.');
    }

    if (_registeredUsers.containsKey(key)) {
      _registeredUsers[key]!['password'] = newPassword;
    } else {
      final defaultName = cleanEmail.contains('@') ? cleanEmail.split('@').first : 'Người dùng';
      _registeredUsers[key] = {
        'name': defaultName,
        'password': newPassword,
      };
    }

    if (_supabaseClient != null) {
      try {
        await _supabaseClient!.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (e) {
        debugPrint('Bỏ qua lỗi phiên làm việc Supabase khi cập nhật mật khẩu: $e');
      }
    }

    // Đổi mật khẩu thành công, thu hồi quyền đổi mật khẩu của email này
    _verifiedResetEmails.remove(key);

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
