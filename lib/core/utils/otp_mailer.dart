import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OTPMailer {
  /// Gửi email chứa mã OTP 6 chữ số ngẫu nhiên trực tiếp tới hòm thư Gmail của người dùng (Không yêu cầu kích hoạt, không đường link)
  static Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final cleanEmail = recipientEmail.trim();
    final subjectText = 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode';
    final bodyText = 'Mã xác thực OTP 6 chữ số để khôi phục mật khẩu của bạn là: $otpCode\n\nMã này có hiệu lực trong 15 phút. Vui lòng nhập mã vào ứng dụng Thi Nhanh để hoàn tất.';

    // 1. Cổng Web3Forms Client API (Cho phép phát trực tiếp từ trình duyệt Web không cần kích hoạt)
    try {
      final web3Response = await http.post(
        Uri.parse('https://api.web3forms.com/submit'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'access_key': '06927d6d-6254-4f24-9b1d-289524e4d588',
          'subject': subjectText,
          'from_name': 'Thi Nhanh App',
          'email': cleanEmail,
          'message': bodyText,
        }),
      ).timeout(const Duration(seconds: 5));

      if (web3Response.statusCode == 200) {
        debugPrint('Đã phát mã OTP $otpCode qua Web3Forms tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Thông báo cổng Web3Forms Mailer: $e');
    }

    // 2. Cổng FormSubmit AJAX Direct
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
      ).timeout(const Duration(seconds: 5));

      if (formSubmitResponse.statusCode == 200) {
        debugPrint('Đã phát mã OTP $otpCode qua FormSubmit tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Thông báo cổng FormSubmit Mailer: $e');
    }

    return false;
  }
}
