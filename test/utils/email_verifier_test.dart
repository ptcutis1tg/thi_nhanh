import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/email_verifier.dart';

void main() {
  group('EmailVerifier Tests', () {
    test('Valid deliverable email passes verification', () async {
      expect(
        EmailVerifier.verifyEmail('khanhlykk1047@gmail.com'),
        completes,
      );
    });

    test('Invalid format email fails verification', () async {
      expect(
        () => EmailVerifier.verifyEmail('invalid-email-format'),
        throwsA(isA<Exception>()),
      );
    });

    test('Disposable email fails verification', () async {
      expect(
        () => EmailVerifier.verifyEmail('user@yopmail.com'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
