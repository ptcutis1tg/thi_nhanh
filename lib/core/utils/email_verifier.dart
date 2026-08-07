import 'dart:convert';
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

  /// Kiểm tra xem email có định dạng hợp lệ, không phải mail rác và tên miền có MX record nhận thư hay không.
  static Future<void> verifyEmail(String email) async {
    final cleanEmail = email.trim();
    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Địa chỉ Email không đúng định dạng (Ví dụ: user@gmail.com).');
    }

    final parts = cleanEmail.split('@');
    if (parts.length != 2) {
      throw Exception('Địa chỉ Email không hợp lệ.');
    }

    final domain = parts[1].toLowerCase();

    // 1. Kiểm tra danh sách tên miền email tạm/rác
    if (_disposableDomains.contains(domain)) {
      throw Exception('Vui lòng không sử dụng Email rác/Email tạm thời.');
    }

    // 2. Kiểm tra bản ghi MX (Mail Exchange) của tên miền thông qua Google DNS API
    try {
      final response = await http.get(
        Uri.parse('https://dns.google/resolve?name=$domain&type=MX'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['Status'] as int?;
        final answer = data['Answer'] as List?;

        // Status != 0 hoặc Answer rỗng nghĩa là tên miền không tồn tại hoặc không có hệ thống nhận Email
        if (status != 0 || answer == null || answer.isEmpty) {
          throw Exception('Tên miền Email "@$domain" không tồn tại hoặc không thể nhận thư.');
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('không tồn tại')) {
        rethrow;
      }
      // Nếu lỗi mạng DNS lookup timeout thì bỏ qua để không chặn người dùng nếu mất kết nối DNS
    }
  }
}
