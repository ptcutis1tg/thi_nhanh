import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Lắng nghe sự kiện đăng nhập / đăng xuất
    _supabaseClient.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      // NOTE: Cần cấu hình OAuth Google trên Supabase dashboard
      await _supabaseClient.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Lỗi đăng nhập Email: $e');
      rethrow;
    }
  }

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

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}
