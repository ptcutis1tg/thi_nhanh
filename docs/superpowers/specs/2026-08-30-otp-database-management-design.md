# Design Spec: OTP Management & Database Persistence

## Overview
Cung cấp giải pháp lưu trữ và quản lý mã OTP 6 chữ số cho mỗi tài khoản người dùng trong ứng dụng **Thi Nhanh**. Mỗi tài khoản được cấp một mã OTP 6 số ban đầu khi vừa tạo, đồng thời mỗi khi có yêu cầu liên quan đến OTP (đổi/khôi phục mật khẩu, xác thực), hệ thống sẽ sinh ra mã OTP 6 số mới, lưu vào CSDL (bảng `user_otps` trên Supabase và local storage `SharedPreferences`), sau đó gửi mã qua email cho người dùng để xác nhận trên ứng dụng/web.

## Technical Architecture

### 1. Database Schema & Storage

#### A. Local Storage (`SharedPreferences`)
- Cấu trúc bản ghi tài khoản người dùng (`_registeredUsers[email]`):
  ```json
  {
    "name": "Full Name",
    "password": "hashed_or_plain_password",
    "avatar": "avatar_url",
    "otp": "123456",
    "otp_expires_at": "2026-08-30T21:00:00.000Z"
  }
  ```

#### B. Supabase Database (`public.user_otps`)
- Migration SQL File: `supabase/migrations/202608300001_user_otps.sql`
- Định nghĩa bảng:
  ```sql
  create table if not exists public.user_otps (
    email text primary key,
    user_id uuid references auth.users(id) on delete cascade,
    otp_code text not null check (otp_code ~ '^[0-9]{6}$'),
    expires_at timestamptz not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
  );

  alter table public.user_otps enable row level security;

  create policy "Users can read/write their own OTP" on public.user_otps
    for all using (true) with check (true);
  ```

### 2. Workflow & Core Functions

#### A. Khởi tạo tài khoản (`signUpWithEmail`)
1. Đăng ký tài khoản mới qua `SupabaseAuth` và/hoặc lưu vào `_registeredUsers`.
2. Tự động sinh ngẫu nhiên mã OTP 6 số ban đầu (ví dụ: `Random().nextInt(900000) + 100000`).
3. Lưu mã OTP 6 số này vào `SharedPreferences` và `public.user_otps` trong Supabase DB cho tài khoản mới.

#### B. Phát sinh yêu cầu OTP mới (`sendPasswordResetEmail` / `requestOTP`)
1. Sinh ngẫu nhiên mã OTP 6 số mới.
2. Thiết lập thời gian hết hạn (`expiresAt` = hiện tại + 10 phút).
3. Cập nhật mã OTP 6 số mới và `expiresAt` vào CSDL (`_registeredUsers` & `user_otps`).
4. Gửi email chứa mã OTP 6 số cho người dùng qua `OTPMailer.sendOTPEmail`.

#### C. Kiểm tra mã OTP từ Web/App (`verifyPasswordResetOTP`)
1. Lấy thông tin mã OTP 6 số từ CSDL (`_registeredUsers` và/hoặc bảng `user_otps` Supabase).
2. So sánh mã do người dùng nhập trên giao diện với mã lưu trong CSDL:
   - Nếu mã khớp và chưa quá thời gian `expiresAt`: Xác thực thành công. Hủy/xoá mã OTP khỏi bộ nhớ để chống tái sử dụng (replay attack).
   - Nếu mã sai hoặc đã hết hạn: Báo lỗi chi tiết tới người dùng.

## Verification Plan
1. Unit test / Test flow tạo tài khoản mới: Kiểm tra tài khoản có được lưu kèm mã OTP 6 số trong CSDL local không.
2. Test phát mã OTP đổi mật khẩu: Gọi gửi OTP, kiểm tra mã OTP mới được ghi đè vào DB và gửi mail.
3. Test xác thực mã OTP trên giao diện web/app với trường hợp mã đúng, mã sai và mã hết hạn.
