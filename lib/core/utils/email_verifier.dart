import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailVerifier {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static const Set<String> _disposableDomains = {
    'yopmail.com',
    'mailinator.com',
    'tempmail.com',
    'tempmail.net',
    'tempmail.org',
    'guerrillamail.com',
    'dispostable.com',
    '10minutemail.com',
    'trashmail.com',
    'sharklasers.com',
    'getnada.com',
    'maildrop.cc',
    'fakeinbox.com',
    'throwawaymail.com',
    'byom.de',
    'crazymailing.com',
    'boun.cr',
  };

  /// Kiểm tra thực tế xem địa chỉ Email có tồn tại (hòm thư có thực) hay không mà không cần gửi email xác nhận.
  static Future<void> verifyEmail(String email) async {
    final cleanEmail = email.trim();

    // 1. Kiểm tra cú pháp Email (Syntax Validation)
    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Địa chỉ Email không đúng định dạng (Ví dụ: name@gmail.com).');
    }

    final parts = cleanEmail.split('@');
    if (parts.length != 2) {
      throw Exception('Địa chỉ Email không hợp lệ.');
    }

    final domain = parts[1].toLowerCase();

    // 2. Kiểm tra danh sách tên miền Email rác / Email tạm thời
    if (_disposableDomains.contains(domain)) {
      throw Exception('Vui lòng không sử dụng Email rác hoặc Email tạm thời.');
    }

    // 3. Kiểm tra bản ghi MX (Mail Exchange) của Tên miền qua Google Public DNS API
    try {
      final dnsResponse = await http.get(
        Uri.parse('https://dns.google/resolve?name=$domain&type=MX'),
      ).timeout(const Duration(seconds: 4));

      if (dnsResponse.statusCode == 200) {
        final data = jsonDecode(dnsResponse.body) as Map<String, dynamic>;
        final status = data['Status'] as int?;
        final answer = data['Answer'] as List?;

        if (status != 0 || answer == null || answer.isEmpty) {
          throw Exception('Địa chỉ Email này không tồn tại (Tên miền "@$domain" không tồn tại hoặc không nhận thư).');
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('không tồn tại')) {
        rethrow;
      }
    }

    // 4. Kiểm tra qua Disify API (Real-time Email Deliverability API)
    try {
      final disifyUri = Uri.parse('https://api.disify.com/v1/email/$cleanEmail');
      final response = await http.get(disifyUri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final format = data['format'] as bool?;
        final disposable = data['disposable'] as bool?;
        final dns = data['dns'] as bool?;

        if (format == false) {
          throw Exception('Cấu trúc địa chỉ Email không hợp lệ.');
        }
        if (disposable == true) {
          throw Exception('Vui lòng không sử dụng địa chỉ Email rác.');
        }
        if (dns == false) {
          throw Exception('Tên miền của địa chỉ Email này không nhận thư.');
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Email')) {
        rethrow;
      }
      debugPrint('Kiểm tra Disify API gặp sự cố (bỏ qua): $e');
    }
  }
}
