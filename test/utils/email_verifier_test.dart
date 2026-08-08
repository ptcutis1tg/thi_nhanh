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

    test('Non-existent domain email fails verification', () async {
      expect(
        () => EmailVerifier.verifyEmail('test@nonexistentdomain999999.com'),
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
