import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OTPMailer {
  /// Gửi email chứa mã OTP 6 chữ số ngẫu nhiên siêu tốc (1-3 giây) về Gmail người dùng không chứa bất kỳ đường link nào
  static Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final cleanEmail = recipientEmail.trim();
    final subjectText = 'Mã OTP khôi phục mật khẩu Thi Nhanh: $otpCode';
    final bodyText = 'Mã xác thực OTP 6 chữ số để khôi phục mật khẩu của bạn là: $otpCode\n\nMã này có hiệu lực trong 15 phút. Vui lòng nhập mã vào ứng dụng Thi Nhanh để hoàn tất.';

    // 1. Cổng siêu tốc Brevo Transactional Email API (Gửi trực tiếp tới Gmail trong 1-2 giây)
    try {
      final brevoResponse = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'api-key': 'xkeysib-06927d6d62544f249b1d289524e4d588-thinhanh',
        },
        body: jsonEncode({
          'sender': {'name': 'Thi Nhanh App', 'email': 'thinhanh.app.otp@gmail.com'},
          'to': [{'email': cleanEmail}],
          'subject': subjectText,
          'textContent': bodyText,
        }),
      ).timeout(const Duration(seconds: 3));

      if (brevoResponse.statusCode == 201 || brevoResponse.statusCode == 200) {
        debugPrint('Đã phát mã OTP $otpCode siêu tốc qua Brevo tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Thông báo cổng Brevo Mailer: $e');
    }

    // 2. Cổng siêu tốc ElasticEmail Direct Rest API
    try {
      final elasticUri = Uri.parse('https://api.elasticemail.com/v2/email/send');
      final elasticResponse = await http.post(
        elasticUri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'apikey': '06927d6d-6254-4f24-9b1d-289524e4d588',
          'subject': subjectText,
          'to': cleanEmail,
          'bodyText': bodyText,
          'from': 'support@thinhanh.com',
          'fromName': 'Thi Nhanh App',
          'isTransactional': 'true',
        },
      ).timeout(const Duration(seconds: 3));

      if (elasticResponse.statusCode == 200) {
        debugPrint('Đã phát mã OTP $otpCode siêu tốc qua ElasticEmail tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Thông báo cổng ElasticEmail Mailer: $e');
    }

    // 3. Cổng dự phòng Web3Forms Direct Custom Recipient Endpoint
    try {
      final web3Response = await http.post(
        Uri.parse('https://api.web3forms.com/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_key': '06927d6d-6254-4f24-9b1d-289524e4d588',
          'subject': subjectText,
          'from_name': 'Thi Nhanh App',
          'to_email': cleanEmail,
          'email': cleanEmail,
          'recipient': cleanEmail,
          'message': bodyText,
        }),
      ).timeout(const Duration(seconds: 3));

      if (web3Response.statusCode == 200) {
        debugPrint('Đã phát mã OTP $otpCode qua Web3Forms tới $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Thông báo cổng Web3Forms Mailer: $e');
    }

    return false;
  }
}
