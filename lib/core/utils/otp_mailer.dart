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
      // Gửi trực tiếp tới địa chỉ Gmail của người dùng qua dịch vụ FormSubmit
      final response = await http.post(
        Uri.parse('https://formsubmit.co/ajax/$cleanEmail'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          '_subject': 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode',
          '_template': 'table',
          'Ứng dụng': 'Thi Nhanh App',
          'Mã xác thực OTP 6 số': otpCode,
          'Lưu ý': 'Mã OTP này có hiệu lực trong 10 phút. Vui lòng nhập mã vào ứng dụng.',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Đã gửi mã OTP $otpCode thành công tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi kết nối gửi OTP Mail: $e');
    }
    return false;
  }
}
