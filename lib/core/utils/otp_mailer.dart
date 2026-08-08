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

    // 1. Thử gửi qua FormSubmit Token kết nối hòm thư
    try {
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
        debugPrint('Đã gửi mã OTP $otpCode thành công tới $cleanEmail qua FormSubmit Token');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi FormSubmit Token: $e');
    }

    // 2. Dự phòng qua FormSubmit Direct Email
    try {
      final response2 = await http.post(
        Uri.parse('https://formsubmit.co/ajax/$cleanEmail'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          '_subject': 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode',
          '_captcha': 'false',
          'Mã xác thực OTP 6 chữ số': otpCode,
        }),
      );

      if (response2.statusCode == 200) {
        debugPrint('Đã gửi mã OTP $otpCode thành công tới $cleanEmail qua FormSubmit Direct');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi FormSubmit Direct: $e');
    }

    return false;
  }
}
