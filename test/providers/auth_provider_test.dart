import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider Email Validation Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider(isSupabaseInitialized: false);
    });

    test('signUpWithEmail throws exception for invalid email format', () async {
      expect(
        () => authProvider.signUpWithEmail('invalid-email', '123456', 'Test User'),
        throwsA(isA<Exception>()),
      );
    });

    test('sendPasswordResetEmail throws exception for invalid email format', () async {
      expect(
        () => authProvider.sendPasswordResetEmail('invalid-email'),
        throwsA(isA<Exception>()),
      );
    });

    test('verifyPasswordResetOTP throws exception for invalid OTP format', () async {
      expect(
        () => authProvider.verifyPasswordResetOTP('test@gmail.com', '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateNewPassword throws exception for short password', () async {
      expect(
        () => authProvider.updateNewPassword('test@gmail.com', '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('Google sign-in reports a missing Supabase configuration', () async {
      await expectLater(
        authProvider.signInWithGoogle(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
