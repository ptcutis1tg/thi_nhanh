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

    // 1. Cổng FormSubmit AJAX Direct phát động tới bất kỳ địa chỉ Gmail người dùng nhập (hqledttn@gmail.com, khanhlykk1047@gmail.com, v.v.)
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
        debugPrint('Đã phát mã OTP $otpCode tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Thông báo cổng FormSubmit Mailer: $e');
    }

    return false;
  }
}
