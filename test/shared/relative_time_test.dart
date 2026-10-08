import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/home/search_screen.dart';

void main() {
  group('formatRelativeTime helper', () {
    test('trả về Vừa xong cho thời gian dưới 1 phút', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(seconds: 30))), 'Vừa xong');
    });

    test('trả về X phút trước cho thời gian dưới 1 giờ', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(minutes: 15))), '15 phút trước');
    });

    test('trả về X giờ trước cho thời gian trong ngày', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(hours: 3))), '3 giờ trước');
    });

    test('trả về Hôm qua cho thời gian 1 ngày trước', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(days: 1))), 'Hôm qua');
    });

    test('trả về X ngày trước cho thời gian dưới 7 ngày', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now.subtract(const Duration(days: 4))), '4 ngày trước');
    });
  });
}
