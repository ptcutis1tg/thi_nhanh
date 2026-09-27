import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/email_verifier.dart';

void main() {
  group('EmailVerifier Tests', () {
    test('accepts valid standard email addresses', () async {
      expect(() => EmailVerifier.verifyEmail('student@gmail.com'), returnsNormally);
      expect(() => EmailVerifier.verifyEmail('teacher.math@edu.vn'), returnsNormally);
    });

    test('rejects invalid email formats', () async {
      expect(() => EmailVerifier.verifyEmail('invalid-email'), throwsException);
      expect(() => EmailVerifier.verifyEmail('test@'), throwsException);
      expect(() => EmailVerifier.verifyEmail('@domain.com'), throwsException);
    });

    test('rejects disposable/trash email domains', () async {
      expect(() => EmailVerifier.verifyEmail('fake@yopmail.com'), throwsException);
      expect(() => EmailVerifier.verifyEmail('trash@tempmail.com'), throwsException);
      expect(() => EmailVerifier.verifyEmail('user@10minutemail.com'), throwsException);
    });
  });
}
