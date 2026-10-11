import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  test('cancelOrDeleteAttempt returns false on empty attemptId without throwing', () async {
    final result = await ProfileService.cancelOrDeleteAttempt('');
    expect(result, isFalse);
  });
}
