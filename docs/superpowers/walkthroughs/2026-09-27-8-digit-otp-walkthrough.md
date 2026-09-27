# Báo Cáo Chuyển Đổi Hệ Thống Mã OTP Sang 8 Chữ Số (8-Digit OTP Walkthrough)

**Mục tiêu**: Chuẩn hóa toàn bộ mã OTP kích hoạt và đặt lại mật khẩu trong ứng dụng **Thi Nhanh** sang độ dài **8 chữ số**, tăng cường an ninh bảo mật, nâng cấp trải nghiệm nhập liệu với bộ lọc `FilteringTextInputFormatter.digitsOnly` và khoảng cách chữ `letterSpacing: 6`, đảm bảo toàn bộ 82/82 bài kiểm thử tự động pass 100%.

---

## 1. Tóm tắt các thay đổi (Changelog)

| Hạng mục | Trước thay đổi | Sau khi nâng cấp (8 chữ số) |
| :--- | :--- | :--- |
| **Logic xác thực đăng ký** (`verifySignUpOTP`) | Kiểm tra `otp.length != 6` | Kiểm tra chuẩn: `cleanOtp.length != 8 \|\| int.tryParse(cleanOtp) == null`<br>Ném lỗi: `Mã OTP phải bao gồm đúng 8 chữ số.` |
| **Logic đặt lại mật khẩu** (`verifyPasswordResetOTP`) | Kiểm tra `otp.length != 6` | Kiểm tra chuẩn: `cleanOtp.length != 8 \|\| int.tryParse(cleanOtp) == null`<br>Ném lỗi: `Mã OTP phải bao gồm đúng 8 chữ số.` |
| **Hộp thoại kích hoạt đăng ký** (`_SignUpOtpDialog`) | `maxLength: 6`, `hintText: 000000`, `letterSpacing: 8` | `maxLength: 8`, `hintText: 00000000`, `letterSpacing: 6`, `FilteringTextInputFormatter.digitsOnly`<br>Cập nhật nhãn và SnackBar sang 8 số |
| **Màn hình Quên mật khẩu** (`ResetPasswordScreen`) | `maxLength: 6`, `hintText: 000000`, `letterSpacing: 8` | `maxLength: 8`, `hintText: 00000000`, `letterSpacing: 6`, `FilteringTextInputFormatter.digitsOnly`<br>Cập nhật thông điệp Bước 1, 2 sang 8 chữ số |
| **Hộp thư dự phòng** (`OTPMailer`) | Gửi mẫu email ghi 6 chữ số | Cập nhật mẫu email thông báo mã OTP 8 chữ số |
| **Kiểm thử tự động** (`auth_provider_test.dart`) | Chỉ kiểm tra chuỗi 6 ký tự | Kiểm tra từ chối mã 6 số cũ (`123456`), từ chối chuỗi chữ/sai độ dài (`123`, `abcdefgh`, `123456789`), chấp thuận mã 8 số hợp lệ (`12345678`) |

---

## 2. Kết quả kiểm thử và phân tích (Verification)

### 2.1. Phân tích tĩnh (Flutter Analyze)
- `flutter analyze lib/screens/auth/greeting_screen.dart` -> **No issues found!**
- `flutter analyze lib/screens/auth/reset_password_screen.dart` -> **No issues found!**

### 2.2. Kiểm thử tự động (Flutter Test)
- `flutter test test/providers/auth_provider_test.dart` -> **10/10 tests passed!**
- `flutter test` (toàn bộ test suite dự án) -> **82/82 tests passed!**

```text
00:00 +0: AuthProvider Native Tests signUpWithEmail throws exception for invalid email format
00:00 +1: AuthProvider Native Tests signUpWithEmail throws exception for short password
00:00 +2: AuthProvider Native Tests verifySignUpOTP throws exception for invalid OTP format
00:00 +3: AuthProvider Native Tests sendPasswordResetOTP throws exception for invalid email format
00:00 +4: AuthProvider Native Tests verifyPasswordResetOTP throws exception for invalid OTP format
00:00 +5: AuthProvider Native Tests verifySignUpOTP accepts valid 8-digit OTP in local mode
00:00 +6: AuthProvider Native Tests verifyPasswordResetOTP accepts valid 8-digit OTP in local mode
...
00:32 +82: All tests passed!
```

---

## 3. Hướng dẫn thiết lập Supabase Console

Để Supabase phát hành mã OTP 8 số (thay vì 6 số mặc định), người quản trị dự án cần thực hiện 2 bước đơn giản trên **Supabase Dashboard**:

### Bước 1: Cấu hình độ dài OTP (OTP Length)
1. Truy cập [Supabase Dashboard](https://supabase.com/dashboard) và chọn dự án **Thi Nhanh**.
2. Điều hướng tới **Authentication** -> **Providers** -> **Email** (hoặc **Auth Settings**).
3. Tìm mục **Email OTP length** (hoặc **OTP Length**), nhập giá trị **`8`**.
4. Nhấn **Save** để lưu cấu hình.

### Bước 2: Cập nhật Mẫu Email (Email Templates)
1. Điều hướng tới **Authentication** -> **Email Templates**.
2. **Mẫu Confirm signup (Xác nhận đăng ký)**:
   ```html
   <h2>Xác thực tài khoản Thi Nhanh</h2>
   <p>Cảm ơn bạn đã đăng ký tài khoản tại <strong>Thi Nhanh</strong>. Mã xác thực OTP gồm 8 chữ số của bạn là:</p>
   <div style="font-size: 28px; font-weight: bold; letter-spacing: 6px; padding: 12px; background: #F1EDFE; color: #8B72F6; text-align: center; border-radius: 8px;">
     {{ .Token }}
   </div>
   <p>Mã này có hiệu lực trong vòng 15 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
   ```
3. **Mẫu Reset password (Khôi phục mật khẩu)**:
   ```html
   <h2>Đặt lại mật khẩu Thi Nhanh</h2>
   <p>Bạn vừa yêu cầu đặt lại mật khẩu tài khoản. Mã xác thực OTP gồm 8 chữ số của bạn là:</p>
   <div style="font-size: 28px; font-weight: bold; letter-spacing: 6px; padding: 12px; background: #F1EDFE; color: #8B72F6; text-align: center; border-radius: 8px;">
     {{ .Token }}
   </div>
   <p>Mã này có hiệu lực trong vòng 15 phút. Nếu bạn không yêu cầu đổi mật khẩu, vui lòng bỏ qua email.</p>
   ```
4. Nhấn **Save changes** để áp dụng.
