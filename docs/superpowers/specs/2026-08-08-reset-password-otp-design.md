# Thiết kế Màn hình Quên Mật khẩu & Xác thực mã OTP 6 Số

**Ngày tạo**: 08/08/2026  
**Dự án**: `thi_nhanh` (Flutter)  
**Trạng thái**: Đã phê duyệt  

---

## 1. Mục tiêu
Chuyển đổi tính năng **Quên mật khẩu** từ dạng hộp thoại pop-up sang **màn hình riêng biệt quy trình 3 bước** (`/reset-password`). Cho phép người dùng nhập Email, nhận **mã OTP 6 số** gửi về Email, xác thực mã OTP trực tiếp trên app và **đổi mật khẩu mới**.

---

## 2. Luồng Giao diện & Nghiệp vụ (3-Step Wizard Flow)

### 2.1 Bước 1: Nhập Email khôi phục
- Người dùng nhập Email cần cấp lại tài khoản.
- Hệ thống chạy `EmailVerifier.verifyEmail(email)` để kiểm tra email tồn tại và đúng định dạng.
- Gọi `AuthProvider.sendPasswordResetEmail(email)` -> Supabase Auth gửi mã OTP 6 số về hộp thư Gmail của người dùng.
- Chuyển sang **Bước 2**.

### 2.2 Bước 2: Nhập mã OTP 6 Chữ số
- Hiển thị địa chỉ Email đang nhận mã.
- Giao diện 6 ô nhập mã OTP dạng số (có đếm ngược 60 giây để gửi lại mã nếu chưa nhận được).
- Khi bấm **"Xác thực mã OTP"**: Gọi `AuthProvider.verifyPasswordResetOTP(email, otpCode)`.
- Supabase xác thực mã OTP hợp lệ (`OtpType.recovery`). Chuyển sang **Bước 3**.

### 2.3 Bước 3: Đặt lại Mật khẩu mới
- Ô nhập **Mật khẩu mới** (tối thiểu 6 ký tự).
- Ô nhập **Xác nhận mật khẩu mới**.
- Bấm **"Cập nhật mật khẩu"**: Gọi `AuthProvider.updateNewPassword(newPassword)`.
- Hiển thị thông báo thành công và chuyển người dùng về màn hình Đăng nhập.

---

## 3. Kiến trúc Code & Các File Thay đổi

### 3.1 [NEW] `lib/screens/auth/reset_password_screen.dart`
Màn hình giao diện mới bao gồm:
- Header tiêu đề, nút Back quay lại Đăng nhập.
- `StatefulWidget` quản lý `_currentStep` (1, 2, 3).
- Hiệu ứng chuyển động mượt giữa các bước.

### 3.2 [MODIFY] `lib/core/providers/auth_provider.dart`
Bổ sung các phương thức:
- `verifyPasswordResetOTP(String email, String otpCode)`: Gọi `_supabaseClient.auth.verifyOTP(email: email, token: otpCode, type: OtpType.recovery)`.
- `updateNewPassword(String newPassword)`: Gọi `_supabaseClient.auth.updateUser(UserAttributes(password: newPassword))` và cập nhật cơ sở dữ liệu mật khẩu cục bộ.

### 3.3 [MODIFY] `lib/screens/auth/greeting_screen.dart`
- Cập nhật hàm `_handleForgotPassword()`: Chuyển hướng sang `/reset-password` (`context.push('/reset-password')`).

### 3.4 [MODIFY] `lib/main.dart`
- Đăng ký route mới `/reset-password` trong `GoRouter`.

---

## 4. Kế hoạch Kiểm thử
1. Test nhập email không tồn tại -> Báo lỗi ngay tại Bước 1.
2. Test nhận mã OTP 6 số trong Gmail -> Nhập mã đúng ở Bước 2 -> Chuyển sang Bước 3.
3. Test nhập sai mã OTP -> Báo lỗi "Mã OTP không chính xác".
4. Đổi mật khẩu mới -> Đăng nhập lại bằng mật khẩu mới thành công 100%.
