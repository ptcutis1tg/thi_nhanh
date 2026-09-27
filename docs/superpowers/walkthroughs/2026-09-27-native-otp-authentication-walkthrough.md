# Walkthrough: Hệ Thống Xác Thực Native 6-Digit OTP (Thi Nhanh)

**Ngày hoàn thành**: 2026-09-27  
**Trạng thái**: Đã triển khai & Kiểm thử thành công  
**Mục tiêu**: Xóa bỏ hoàn toàn link xác nhận gây lỗi 404, chuẩn hóa 100% bằng mã OTP 6 chữ số trực tiếp trên ứng dụng, loại bỏ lưu trữ mật khẩu dạng plain text và dọn dẹp phân quyền cũ.

---

## 1. Tổng Quan Những Gì Đã Triển Khai

| Hạng mục | Trước khi sửa | Sau khi chuẩn hóa |
|---|---|---|
| **Kích hoạt Đăng ký** | Gửi email chứa Link tiếng Anh (`Confirm email address`), bấm vào bị chuyển hướng 404 trên GitHub Pages | Gửi **Mã OTP gồm 6 chữ số** về email; người dùng giữ nguyên màn hình app, nhập 6 số vào hộp thoại để kích hoạt và đăng nhập ngay |
| **Quên mật khẩu** | Lệ thuộc vào `_registeredUsers` trong bộ nhớ máy cục bộ; gửi qua `formsubmit.co` không ổn định; kẹt trên thiết bị mới | 100% Supabase Native Auth: Nhập email -> Nhận mã OTP 6 số -> Nhập OTP xác thực -> Tạo mật khẩu mới ngay trên app |
| **Đổi mật khẩu trong Profile** | Chỉ lưu vào SharedPreferences giả lập, không cập nhật lên Supabase Auth | Xác thực mật khẩu cũ với Supabase trước khi cập nhật; tài khoản Google OAuth tự động ẩn đổi mật khẩu và hiển thị huy hiệu liên kết Google |
| **Lưu trữ bảo mật Client** | Lưu mật khẩu và mã OTP dạng văn bản thô (plain-text) trong `SharedPreferences` | **Xóa sạch hoàn toàn**. Chỉ sử dụng JWT Session (`access_token`, `refresh_token`) do Supabase SDK quản lý bảo mật |
| **Bảo mật CSDL Supabase** | Bảng `user_otps` có RLS `for all using (true)` mở toang quyền đọc/ghi cho mọi người | Thu hồi và khóa toàn bộ quyền truy cập công khai của bảng `user_otps` qua migration mới |
| **Phân quyền vai trò** | Còn sót code cũ `enum UserRole`, `_activeRole`, `setRole` gây nhầm lẫn | Dọn sạch mã cũ; toàn bộ tài khoản thống nhất một quyền hạn (vừa học tập vừa soạn đề) |
| **Trải nghiệm Khách (Guest)** | Hiển thị avatar trống; truy cập tính năng tạo đề bị lỗi | Hiển thị nút **"Đăng nhập"** nổi bật trên thanh điều hướng; khi bấm vào tính năng tạo đề thì hiển thị hộp thoại nhắc nhở nhẹ nhàng |

---

## 2. Hướng Dẫn Cấu Hình Mẫu Email Trên Supabase Dashboard

Để đảm bảo Supabase gửi đúng mã OTP 6 số bằng tiếng Việt (thay vì link tiếng Anh mặc định), bạn truy cập **Supabase Dashboard** của dự án:
👉 **URL Project**: `https://supabase.com/dashboard/project/egsmzfrhekpacpjoxijs`

### Bước 1: Cấu hình URL Chuyển hướng chuẩn
1. Vào **Authentication** -> **URL Configuration**.
2. Mục **Site URL**: Điền chính xác:
   `https://ptcutis1tg.github.io/thi_nhanh/`
3. Mục **Redirect URLs**: Bổ sung thêm:
   `https://ptcutis1tg.github.io/thi_nhanh/**`

### Bước 2: Cấu hình Mẫu Email Đăng ký (Confirm signup)
1. Vào **Authentication** -> **Email Templates** -> chọn tab **Confirm signup**.
2. **Subject**: `Mã OTP xác thực tài khoản Thi Nhanh: {{ .Token }}`
3. **Body (HTML)**:
```html
<div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; borderRadius: 16px;">
  <h2 style="color: #6557E8; text-align: center;">Thi Nhanh - Xác Thực Tài Khoản</h2>
  <p>Chào bạn,</p>
  <p>Cảm ơn bạn đã đăng ký tài khoản tại <strong>Thi Nhanh</strong>. Mã xác thực OTP gồm 6 chữ số của bạn là:</p>
  <div style="text-align: center; margin: 24px 0;">
    <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #8B72F6; background: #f5f3ff; padding: 12px 24px; border-radius: 12px; display: inline-block;">
      {{ .Token }}
    </span>
  </div>
  <p style="color: #64748b; font-size: 14px;">Mã này có hiệu lực trong 15 phút. Vui lòng nhập mã này vào ứng dụng để hoàn tất đăng ký. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.</p>
</div>
```
*(Lưu ý quan trọng: Xóa bỏ thẻ `{{ .ConfirmationURL }}` để Supabase không gửi đường link bấm nữa).*

### Bước 3: Cấu hình Mẫu Email Đặt lại Mật khẩu (Reset password)
1. Vào tab **Reset password**.
2. **Subject**: `Mã OTP đặt lại mật khẩu Thi Nhanh: {{ .Token }}`
3. **Body (HTML)**:
```html
<div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px;">
  <h2 style="color: #6557E8; text-align: center;">Thi Nhanh - Khôi Phục Mật Khẩu</h2>
  <p>Chào bạn,</p>
  <p>Bạn vừa yêu cầu đặt lại mật khẩu tài khoản. Mã xác thực OTP gồm 6 chữ số của bạn là:</p>
  <div style="text-align: center; margin: 24px 0;">
    <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #8B72F6; background: #f5f3ff; padding: 12px 24px; border-radius: 12px; display: inline-block;">
      {{ .Token }}
    </span>
  </div>
  <p style="color: #64748b; font-size: 14px;">Mã này có hiệu lực trong 15 phút. Nhập mã vào màn hình khôi phục mật khẩu để tạo mật khẩu mới.</p>
</div>
```

---

## 3. Các Luồng Hoạt Động Chi Tiết Trên App

### Luồng 1: Đăng ký tài khoản (Sign-Up)
1. Người dùng mở trang Đăng ký -> Điền Họ tên, Email, Mật khẩu -> Bấm **"Đăng ký"**.
2. Nếu Supabase yêu cầu xác nhận email: Hộp thoại **"Nhập mã OTP kích hoạt"** xuất hiện ngay lập tức.
3. Người dùng nhập 6 chữ số từ email -> Nhấn **"Kích hoạt tài khoản"** -> Vào thẳng màn hình chính `/home`.

### Luồng 2: Quên mật khẩu (Forgot Password)
1. Bấm **"Quên mật khẩu?"** tại màn hình đăng nhập.
2. Bước 1: Nhập email -> Nhận mã OTP 6 số.
3. Bước 2: Nhập 6 số mã OTP -> Hệ thống xác nhận phiên khôi phục.
4. Bước 3: Nhập mật khẩu mới -> Hoàn tất và quay lại đăng nhập.

### Luồng 3: Đổi mật khẩu trong Trang Cá Nhân
1. Mở trang Cá nhân (`/profile`) -> Kéo xuống mục **"Thay đổi mật khẩu"**.
2. Với tài khoản Email/Password: Nhập Mật khẩu hiện tại + Mật khẩu mới -> Cập nhật trực tiếp lên Supabase.
3. Với tài khoản Google OAuth: Ẩn phần nhập mật khẩu và hiển thị huy hiệu thông báo: *"Tài khoản liên kết Google"*.

### Luồng 4: Trải nghiệm Người dùng Khách (Guest)
1. Khi chưa đăng nhập, góc phải trên thanh điều hướng hiển thị nút **"Đăng nhập"** trang nhã.
2. Khách vẫn thoải mái làm bài thi thử hoặc tham gia phòng thi bằng mã `PTxxxxxx`.
3. Khi khách bấm vào các tính năng cần tài khoản (*Tạo đề thi*, *Bộ đề của tôi*, *Tạo phòng thi*), ứng dụng hiển thị hộp thoại nhắc nhở thân thiện với hai lựa chọn: `[Để sau]` và `[Đăng nhập ngay]`.
