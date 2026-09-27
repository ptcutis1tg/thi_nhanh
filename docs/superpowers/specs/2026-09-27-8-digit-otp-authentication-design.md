# Thiết kế Chuyển đổi Hệ thống Mã OTP Xác thực sang 8 Chữ số (8-Digit OTP Authentication)

## 1. Tổng quan
- **Bối cảnh**: Hệ thống hiện tại của ứng dụng **Thi Nhanh** đang sử dụng mã OTP 6 chữ số cho cả 2 luồng: kích hoạt tài khoản đăng ký mới (`verifySignUpOTP`) và đặt lại mật khẩu (`verifyPasswordResetOTP`).
- **Mục tiêu**: Chuyển đổi toàn diện toàn bộ mã OTP đăng nhập và xác thực trong app sang định dạng **8 chữ số**, tăng tính bảo mật, đồng bộ hóa validation ở tầng Provider, bổ sung bộ lọc ký tự chỉ nhận số (`FilteringTextInputFormatter.digitsOnly`), tinh chỉnh giao diện tránh tràn dòng, và cập nhật trọn vẹn bộ kiểm thử tự động.

---

## 2. Phạm vi thay đổi (Scope)

| Khu vực | Chi tiết thay đổi |
| :--- | :--- |
| **Logic nghiệp vụ (`AuthProvider`)** | - Cập nhật `verifySignUpOTP`: kiểm tra độ dài `cleanOtp.length != 8` và ký tự số.<br>- Cập nhật `verifyPasswordResetOTP`: kiểm tra độ dài `cleanOtp.length != 8` và ký tự số.<br>- Cập nhật thông điệp lỗi: `"Mã OTP phải bao gồm đúng 8 chữ số."`. |
| **Kích hoạt tài khoản (`GreetingScreen`)** | - `_SignUpOtpDialog`: `maxLength: 8`, `hintText: '00000000'`, `letterSpacing: 6`.<br>- Thêm `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`.<br>- Thông báo lỗi nhập thiếu/sai: `"Vui lòng nhập đủ 8 chữ số mã OTP."`.<br>- Cập nhật nhãn thông tin và SnackBar: `"gồm 8 chữ số"`, `"mã OTP 8 số"`. |
| **Quên mật khẩu (`ResetPasswordScreen`)** | - Bước 1 mô tả: `"mã xác minh 8 chữ số"`.<br>- Thông báo gửi mã: `"Mã xác minh OTP 8 số đã được gửi về email..."`.<br>- Bước 2 mô tả: `"Mã xác minh 8 số đã được gửi tới email..."`.<br>- Ô nhập OTP: `maxLength: 8`, `hintText: '00000000'`, `letterSpacing: 6`, `FilteringTextInputFormatter.digitsOnly`.<br>- Kiểm tra lỗi: `"Vui lòng nhập đủ 8 chữ số mã OTP."`. |
| **Hộp thư dự phòng (`OTPMailer`)** | - Cập nhật nội dung template email dự phòng sang 8 chữ số. |
| **Kiểm thử tự động (`auth_provider_test.dart`)** | - Kiểm tra mã cũ 6 số `'123456'` bị từ chối.<br>- Kiểm tra chuỗi chứa chữ cái hoặc sai độ dài (`'123'`, `'1234567'`, `'123456789'`) bị từ chối.<br>- Kiểm tra mã đúng chuẩn 8 chữ số `'12345678'` được chấp thuận. |

---

## 3. Kiến trúc và Chi tiết Kỹ thuật

### 3.1. Provider (`lib/core/providers/auth_provider.dart`)
```dart
Future<AuthResponse?> verifySignUpOTP(String email, String otpCode) async {
  final cleanEmail = email.trim();
  final cleanOtp = otpCode.trim();
  if (cleanOtp.length != 8 || int.tryParse(cleanOtp) == null) {
    throw Exception('Mã OTP phải bao gồm đúng 8 chữ số.');
  }
  // Gửi token 8 số lên Supabase Auth
  ...
}

Future<AuthResponse?> verifyPasswordResetOTP(String email, String otpCode) async {
  final cleanEmail = email.trim();
  final cleanOtp = otpCode.trim();
  if (cleanOtp.length != 8 || int.tryParse(cleanOtp) == null) {
    throw Exception('Mã OTP phải bao gồm đúng 8 chữ số.');
  }
  // Gửi token 8 số lên Supabase Auth
  ...
}
```

### 3.2. Giao diện người dùng (UI/UX)
* **Kích thước và khoảng cách ký tự (`letterSpacing: 6`):** Với 8 chữ số, nếu giữ nguyên `letterSpacing: 8` kết hợp `fontSize: 24` kiểu chữ đậm (bold), chuỗi văn bản có thể chiếm đến 320px bề ngang, dễ gây lỗi `RenderFlex overflowed` trên màn hình điện thoại khổ hẹp (320px–360px). Giảm `letterSpacing: 6` giữ được vẻ đẹp hiện đại, thông thoáng mà hoàn toàn an toàn về mặt hiển thị.
* **Bộ lọc ký tự (`FilteringTextInputFormatter.digitsOnly`):** Ngăn chặn người dùng nhập ký tự chữ hoặc dấu phân tách, đồng thời tự động làm sạch chuỗi khi người dùng sao chép & dán mã OTP từ email vào ô nhập.

---

## 4. Kế hoạch Kiểm thử (Test Suite)

Cập nhật file [auth_provider_test.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/test/providers/auth_provider_test.dart):
1. `test('verifySignUpOTP throws exception for invalid OTP format')`:
   - Xác nhận `'123'` ném ngoại lệ.
   - Xác nhận mã 6 số `'123456'` ném ngoại lệ.
   - Xác nhận chuỗi chữ `'abcdefgh'` ném ngoại lệ.
   - Xác nhận chuỗi 9 số `'123456789'` ném ngoại lệ.
   - Xác nhận mã 8 số hợp lệ `'12345678'` không ném lỗi format.
2. `test('verifyPasswordResetOTP throws exception for invalid OTP format')`:
   - Xác nhận các trường hợp tương tự đối với luồng quên mật khẩu.

---

## 5. Hướng dẫn Cấu hình Supabase Console

Để dịch vụ gửi mã của Supabase phát hành mã 8 chữ số tương thích với ứng dụng:
1. Đăng nhập [Supabase Dashboard](https://supabase.com/dashboard) -> Chọn dự án Thi Nhanh.
2. Điều hướng tới **Authentication** -> **Providers** -> **Email**.
3. Cài đặt **Email OTP length** thành **`8`** và nhấn Lưu (Save).
4. Điều hướng tới **Authentication** -> **Email Templates**:
   - Cập nhật tiêu đề và mô tả trong mẫu **Confirm signup** thành: *"Mã xác thực OTP gồm 8 chữ số của bạn là: {{ .Token }}"*.
   - Cập nhật trong mẫu **Reset password** thành: *"Mã xác thực OTP gồm 8 chữ số của bạn là: {{ .Token }}"*.
