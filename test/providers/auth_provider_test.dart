import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider Native Tests', () {
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider(isSupabaseInitialized: false);
      await authProvider.init();
    });

    test('signUpWithEmail throws exception for invalid email format', () async {
      expect(
        () => authProvider.signUpWithEmail('invalid-email', '123456', 'Test User'),
        throwsA(isA<Exception>()),
      );
    });

    test('signUpWithEmail throws exception for short password', () async {
      expect(
        () => authProvider.signUpWithEmail('valid@gmail.com', '12345', 'Test User'),
        throwsA(isA<Exception>()),
      );
    });

    test('verifySignUpOTP throws exception for invalid OTP format', () async {
      expect(
        () => authProvider.verifySignUpOTP('valid@gmail.com', '123'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => authProvider.verifySignUpOTP('valid@gmail.com', 'abcdef'),
        throwsA(isA<Exception>()),
      );
    });

    test('sendPasswordResetOTP throws exception for invalid email format', () async {
      expect(
        () => authProvider.sendPasswordResetOTP('invalid-email'),
        throwsA(isA<Exception>()),
      );
    });

    test('verifyPasswordResetOTP throws exception for invalid OTP format', () async {
      expect(
        () => authProvider.verifyPasswordResetOTP('test@gmail.com', '123'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => authProvider.verifyPasswordResetOTP('test@gmail.com', 'abcdef'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateNewPassword throws exception for short password', () async {
      expect(
        () => authProvider.updateNewPassword('123'),
        throwsA(isA<Exception>()),
      );
    });

    test('Google sign-in works in local demo mode when Supabase is uninitialized', () async {
      await authProvider.signInWithGoogle();
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.userEmail, equals('demo_google_user@gmail.com'));
      expect(authProvider.userName, equals('Google User (Demo)'));
    });

    test('getWebRedirectUrl constructs proper base redirect URL for subpath and root deployments', () {
      final ghPagesUri = Uri.parse('https://ptcutis1tg.github.io/thi_nhanh/');
      expect(AuthProvider.getWebRedirectUrl(ghPagesUri), equals('https://ptcutis1tg.github.io/thi_nhanh/'));

      final ghPagesHashUri = Uri.parse('https://ptcutis1tg.github.io/thi_nhanh/#/greeting');
      expect(AuthProvider.getWebRedirectUrl(ghPagesHashUri), equals('https://ptcutis1tg.github.io/thi_nhanh/'));

      final ghPagesNoSlash = Uri.parse('https://ptcutis1tg.github.io/thi_nhanh');
      expect(AuthProvider.getWebRedirectUrl(ghPagesNoSlash), equals('https://ptcutis1tg.github.io/thi_nhanh/'));

      final ghPagesIndex = Uri.parse('https://ptcutis1tg.github.io/thi_nhanh/index.html');
      expect(AuthProvider.getWebRedirectUrl(ghPagesIndex), equals('https://ptcutis1tg.github.io/thi_nhanh/'));

      final localhostUri = Uri.parse('http://localhost:5000/');
      expect(AuthProvider.getWebRedirectUrl(localhostUri), equals('http://localhost:5000/'));
    });
  });
}
