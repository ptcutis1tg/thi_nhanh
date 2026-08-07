# Thiết kế Xác thực Email & Quên mật khẩu qua Supabase Auth

**Ngày tạo**: 08/08/2026  
**Dự án**: `thi_nhanh` (Flutter)  
**Trạng thái**: Đã phê duyệt  

---

## 1. Mục tiêu
Đảm bảo tài khoản người dùng đăng ký trên hệ thống phải sử dụng **Email thực tế có tồn tại** và phải trải qua quy trình **Xác thực Email (Email Verification)** trước khi sử dụng. Đồng thời, khi người dùng chọn **"Quên mật khẩu"**, liên kết/mã xác minh khôi phục mật khẩu phải được **gửi chính xác về hộp thư Email** của họ.

---

## 2. Luồng Nghiệp vụ (Workflow)

### 2.1 Luồng Đăng ký Tài khoản (Sign Up with Email Verification)
1. **Người dùng nhập thông tin**: Họ tên, Email, Mật khẩu, Xác nhận mật khẩu trên giao diện Đăng ký.
2. **Kiểm tra định dạng client**:
   - Email không được trống, phải đúng định dạng `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`.
   - Mật khẩu tối thiểu 6 ký tự. Mật khẩu xác nhận phải trùng khớp.
3. **Gửi yêu cầu tới Supabase Auth**:
   - Gọi `supabase.auth.signUp(email: email, password: password, data: {'full_name': fullName})`.
   - Supabase tự động tạo tài khoản ở trạng thái **chưa xác minh (unverified)** và gửi thư chứa liên kết/mã xác nhận tới Email của người dùng.
4. **Phản hồi UI**:
   - Hiển thị dialog / SnackBar thông báo: *"Email xác thực đã được gửi tới [Email]! Vui lòng kiểm tra hộp thư và nhấp vào liên kết xác nhận để kích hoạt tài khoản."*
   - Không cho phép tự động chuyển vào màn hình chính `/home` cho đến khi tài khoản được xác thực.

### 2.2 Luồng Quên Mật khẩu (Forgot / Reset Password)
1. **Người dùng nhấn "Quên mật khẩu?"** trên giao diện Đăng nhập.
2. **Nhập Email**: Nhập địa chỉ email cần khôi phục mật khẩu trong hộp thoại.
3. **Gửi yêu cầu tới Supabase Auth**:
   - Gọi `supabase.auth.resetPasswordForEmail(email)`.
4. **Xử lý phía Supabase & Phản hồi UI**:
   - Supabase kiểm tra nếu email tồn tại trong hệ thống, tự động gửi Email chứa link/OTP đặt lại mật khẩu.
   - Hiển thị thông báo: *"Yêu cầu đặt lại mật khẩu đã được gửi! Vui lòng kiểm tra hộp thư email của bạn."*
5. **Cập nhật mật khẩu mới**:
   - Khi người dùng truy cập link khôi phục hoặc nhập mã OTP, ứng dụng hiển thị màn hình/dialog nhập Mật khẩu mới và gọi `supabase.auth.updateUser(UserAttributes(password: newPassword))` để cập nhật mật khẩu trên hệ thống.

---

## 3. Kiến trúc Phân lớp & Thay đổi Codebase

### 3.1 `lib/core/providers/auth_provider.dart`
- **Tích hợp `SupabaseClient`**:
  - Đảm bảo tất cả hàm đăng ký, đăng nhập, quên mật khẩu ưu tiên gọi API của Supabase Auth khi `_supabaseClient != null`.
  - Hàm `signUpWithEmail`: Gửi email xác thực từ Supabase và trả về trạng thái chờ xác thực (`needsVerification = true`).
  - Hàm `sendPasswordResetEmail(String email)`: Thực hiện gọi `_supabaseClient.auth.resetPasswordForEmail(email)`.
  - Hàm `updatePassword(String newPassword)`: Thực hiện đổi mật khẩu người dùng đã xác minh OTP/Reset Link.

### 3.2 `lib/screens/auth/greeting_screen.dart`
- Validate định dạng Email chuẩn regex trước khi gửi yêu cầu.
- Cập nhật handler `_handleEmailRegister()` để hiển thị thông báo hướng dẫn người dùng kiểm tra Email kích hoạt.
- Cập nhật handler `_handleForgotPassword()` để gọi `sendPasswordResetEmail()` và xử lý thông báo lỗi/thành công từ Supabase Auth.

---

## 4. Hướng dẫn Cấu hình Supabase Dashboard
1. Truy cập [Supabase Dashboard](https://supabase.com/dashboard) -> Chọn dự án `thi_nhanh`.
2. Vào mục **Authentication** -> **Providers** -> **Email**:
   - Bật **Enable Email provider**.
   - Bật **Confirm email** (*Require email confirmation before user can sign in*).
3. (Tùy chọn) Vào **Authentication** -> **Email Templates**:
   - Tùy chỉnh nội dung Email tiếng Việt cho **Confirm Signup** và **Reset Password**.

---

## 5. Kế hoạch Kiểm thử (Testing & Verification Plan)
1. **Kiểm thử Đăng ký với Email thật**:
   - Đăng ký tài khoản bằng email thật -> Kiểm tra hộp thư nhận được email xác nhận từ Supabase.
   - Thử đăng nhập trước khi nhấn link xác nhận -> Kiểm tra thông báo yêu cầu xác minh email.
   - Nhấn link xác nhận trong email -> Đăng nhập lại thành công.
2. **Kiểm thử Đăng ký với Email không tồn tại / Sai định dạng**:
   - Nhập email sai định dạng (VD: `test@abc`) -> UI chặn báo lỗi ngay lập tức.
3. **Kiểm thử Quên mật khẩu**:
   - Nhập email đã đăng ký -> Kiểm tra hộp thư nhận email đặt lại mật khẩu.
   - Làm theo hướng dẫn trong email để đổi mật khẩu -> Đăng nhập bằng mật khẩu mới thành công.
