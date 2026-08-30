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

    test('Google sign-in works in local demo mode when Supabase is uninitialized', () async {
      await authProvider.signInWithGoogle();
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.userEmail, equals('demo_google_user@gmail.com'));
    });

    test('sendPasswordResetEmail for unregistered email throws Exception', () async {
      expect(
        () => authProvider.sendPasswordResetEmail('unregistered_user@gmail.com'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateNewPassword without OTP verification throws Exception', () async {
      await authProvider.signUpWithEmail('registered_user@gmail.com', 'oldpassword123', 'Registered User');
      authProvider.signOut();

      // Trying to update password without OTP verification must throw Exception
      expect(
        () => authProvider.updateNewPassword('registered_user@gmail.com', 'newpassword123'),
        throwsA(isA<Exception>()),
      );
    });

    test('Full password reset flow with OTP verification succeeds and revokes token', () async {
      const email = 'valid_user@gmail.com';
      await authProvider.signUpWithEmail(email, 'oldpassword123', 'Valid User');
      authProvider.signOut();

      // Step 1: Send OTP
      final otpCode = await authProvider.sendPasswordResetEmail(email);
      expect(otpCode, isNotNull);
      expect(otpCode!.length, equals(6));

      // Step 2: Verify OTP
      await authProvider.verifyPasswordResetOTP(email, otpCode);

      // OTP cannot be reused a second time
      expect(
        () => authProvider.verifyPasswordResetOTP(email, otpCode),
        throwsA(isA<Exception>()),
      );

      // Step 3: Update Password
      await authProvider.updateNewPassword(email, 'newpassword123');

      // Check login with new password
      await authProvider.signInWithEmail(email, 'newpassword123');
      expect(authProvider.isAuthenticated, isTrue);

      // Privilege to update password without a new OTP is revoked
      authProvider.signOut();
      expect(
        () => authProvider.updateNewPassword(email, 'anotherpass123'),
        throwsA(isA<Exception>()),
      );
    });

    test('local-only sign-in is not treated as a Supabase session', () async {
      await authProvider.signInWithEmail('local@example.com', '123456');

      expect(authProvider.hasSupabaseSession, isFalse);
    });
  });
}
