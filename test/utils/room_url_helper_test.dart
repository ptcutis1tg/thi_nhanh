import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/room_url_helper.dart';

void main() {
  group('RoomUrlHelper Tests', () {
    test('buildJoinUrl normalizes room code and formats join url with query parameter', () {
      final url = RoomUrlHelper.buildJoinUrl('PT123456');
      expect(url, contains('/join?code=PT123456'));
    });

    test('buildJoinUrl automatically adds PT prefix if given pure digits', () {
      final url = RoomUrlHelper.buildJoinUrl('892341');
      expect(url, contains('/join?code=PT892341'));
    });
  });
}
