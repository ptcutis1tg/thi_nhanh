import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';

void main() {
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
  });
}
