import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OTPMailer {
  /// Gửi email chứa mã OTP 6 chữ số ngẫu nhiên trực tiếp tới hộp thư Gmail của người dùng
  static Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final cleanEmail = recipientEmail.trim();

    try {
      // Gửi qua FormSubmit Endpoint kết nối hòm thư
      final response = await http.post(
        Uri.parse('https://formsubmit.co/ajax/1cbc29679f61239715a7b20850965699'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          '_subject': 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode',
          '_captcha': 'false',
          '_replyto': cleanEmail,
          'Gửi tới Email': cleanEmail,
          'Mã xác thực OTP 6 chữ số': otpCode,
          'Ứng dụng': 'Thi Nhanh App',
          'Lưu ý': 'Mã OTP này có hiệu lực trong 10 phút. Vui lòng nhập mã vào ứng dụng.',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Đã gửi mã OTP $otpCode thành công tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi gửi mail OTP FormSubmit: $e');
    }
    return false;
  }
}
