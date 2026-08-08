import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OTPMailer {
  /// Gửi email chứa mã OTP 6 chữ số ngẫu nhiên về Gmail người dùng
  static Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final cleanEmail = recipientEmail.trim();
    final subjectText = 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode';
    final bodyText = 'Mã xác thực OTP 6 chữ số để khôi phục mật khẩu của bạn là: $otpCode\n\nMã này có hiệu lực trong 15 phút. Vui lòng nhập mã vào ứng dụng Thi Nhanh để hoàn tất.';

    // 1. Cổng FormSubmit AJAX Direct (Sử dụng form-urlencoded để vượt qua rào cản CORS trình duyệt)
    try {
      final formSubmitResponse = await http.post(
        Uri.parse('https://formsubmit.co/ajax/$cleanEmail'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          '_subject': subjectText,
          'message': bodyText,
          '_captcha': 'false',
          '_template': 'table',
        },
      ).timeout(const Duration(seconds: 8));

      if (formSubmitResponse.statusCode == 200) {
        debugPrint('Đã phát mã OTP $otpCode qua FormSubmit tới $cleanEmail');
        return true;
      } else {
        debugPrint('Lỗi FormSubmit: ${formSubmitResponse.statusCode} - ${formSubmitResponse.body}');
      }
    } catch (e) {
      debugPrint('Thông báo cổng FormSubmit Mailer: $e');
    }

    return false;
  }
}
