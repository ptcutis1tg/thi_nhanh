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
      // Sử dụng API gửi mail tự động qua EmailJS / Resend Service
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': 'service_thinhanh',
          'template_id': 'template_otp',
          'user_id': 'user_thinhanh_public',
          'template_params': {
            'to_email': cleanEmail,
            'otp_code': otpCode,
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Đã gửi mã OTP $otpCode thành công tới Gmail: $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi gửi mail OTP tự động: $e');
    }
    return false;
  }
}
