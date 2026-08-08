import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OTPMailer {
  /// Gửi email chứa mã OTP 6 chữ số ngẫu nhiên trực tiếp tới hòm thư Gmail của người dùng
  static Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final cleanEmail = recipientEmail.trim();

    // 1. Thử gửi qua cổng Web3Forms API
    try {
      final response = await http.post(
        Uri.parse('https://api.web3forms.com/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_key': '06927d6d-6254-4f24-9b1d-289524e4d588',
          'subject': 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode',
          'from_name': 'Thi Nhanh App',
          'to': cleanEmail,
          'email': cleanEmail,
          'message': '''
Mã xác thực OTP 6 chữ số để khôi phục mật khẩu của bạn là: $otpCode

Mã này có hiệu lực trong 10 phút. Vui lòng nhập mã vào ứng dụng Thi Nhanh để hoàn tất.
''',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Đã phát mã OTP $otpCode qua Web3Forms tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi Web3Forms Mailer: $e');
    }

    // 2. Dự phòng qua cổng StaticForms API (Gửi trực tiếp không cần kích hoạt form)
    try {
      final response2 = await http.post(
        Uri.parse('https://api.staticforms.xyz/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail,
          'subject': 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode',
          'message': 'Mã xác thực OTP 6 chữ số để khôi phục mật khẩu của bạn là: $otpCode (Hiệu lực trong 10 phút)',
          'replyTo': '@',
        }),
      );

      if (response2.statusCode == 200) {
        debugPrint('Đã phát mã OTP $otpCode qua StaticForms tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi StaticForms Mailer: $e');
    }

    return false;
  }
}
