import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OTPMailer {
  /// Gửi email chứa mã OTP 6 chữ số ngẫu nhiên TRỰC TIẾP vào hòm thư Gmail của người dùng ngay lập tức
  static Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final cleanEmail = recipientEmail.trim();

    // 1. Thử gửi trực tiếp qua Cổng Mailer tức thì (Không cần kích hoạt, gửi thẳng tới Gmail người dùng)
    try {
      final response = await http.post(
        Uri.parse('https://api.web3forms.com/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_key': 'e4b9b782-7489-4977-8491-0f7243b74910', // Khóa phát thư trực tiếp tức thì
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
        debugPrint('Đã gửi trực tiếp mã OTP $otpCode tới Gmail $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi phát mail trực tiếp Web3Forms: $e');
    }

    // 2. Cổng dự phòng 2 qua Brevo API
    try {
      final response2 = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'accept': 'application/json',
          'api-key': 'xkeysib-thinhanh-direct-mail-key',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'sender': {'name': 'Thi Nhanh App', 'email': 'no-reply@thinhanh.com'},
          'to': [
            {'email': cleanEmail}
          ],
          'subject': 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode',
          'htmlContent': '<h2>Mã OTP của bạn là: <b>$otpCode</b></h2>',
        }),
      );
      if (response2.statusCode == 201 || response2.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi phát mail Brevo: $e');
    }

    return false;
  }
}
