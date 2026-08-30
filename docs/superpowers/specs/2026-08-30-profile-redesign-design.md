# Design Spec: Enhanced Profile & Learning Dashboard ("Thi Nhanh")

## 1. Executive Summary
Nâng cấp trang Hồ sơ cá nhân (`ProfileScreen`) của hệ thống **Thi Nhanh** thành một **Bảng điều khiển học tập cá nhân (Personal Learning Dashboard)** hiện đại, chuẩn SaaS giáo dục, giữ nguyên 100% nhận diện thương hiệu (Tone màu tím `Color(0xFF6557E8)`, nền xám nhạt `Color(0xFFF8F8FC)`, thẻ bo cong 24px, bo góc input 12px, font chữ Be Vietnam Pro).

## 2. Layout & Section Hierarchy (Ưu tiên UX)
Trang Profile được bố trí theo độ ưu tiên từ trên xuống dưới, giới hạn chiều rộng chuẩn Desktop (~1200px - 1440px):

```
+-----------------------------------------------------------------------------------+
| 1. PROFILE HEADER CARD                                                             |
| [Avatar + Badge Học sinh/Giáo viên + Name/Email]  |  [24 Bài | 8.2 ĐTB | 🔥5 Chuỗi] |
+-----------------------------------------------------------------------------------+
| 2. DASHBOARD LAYOUT (2 Columns)                                                   |
| [LEFT 65%]: 📊 Tổng quan học tập                 | [RIGHT 35%]: 🏆 Thành tích      |
| - Biểu đồ điểm số gần đây (Custom Line Chart)    | - Grid 4 huy hiệu thành tích     |
| - Điểm cao nhất (9.5) & Tổng thời gian (6h 32m)   |   (Chuỗi 5 bài, Top 3, v.v.)     |
+-----------------------------------------------------------------------------------+
| 3. RECENT TEST HISTORY                                                            |
| 🕘 Bài thi gần đây (Danh sách dòng: Tên bài, Ngày, Điểm số pill, nút [Chi tiết →])|
|                                                      [Xem tất cả lịch sử →]       |
+-----------------------------------------------------------------------------------+
| 4. ACCOUNT SETTINGS                                                               |
| ⚙️ Thông tin cá nhân (Họ tên, Gmail đăng ký ✓, [Lưu thay đổi])                   |
+-----------------------------------------------------------------------------------+
| 5. CHANGE PASSWORD                                                                |
| 🔑 Thay đổi mật khẩu (Mật khẩu hiện tại, mới, xác nhận + eye toggle, [Đổi MK])   |
+-----------------------------------------------------------------------------------+
| 6. ACCOUNT ACTIONS                                                                |
| [Đăng xuất]                                                  Xóa tài khoản        |
+-----------------------------------------------------------------------------------+
```

## 3. Dynamic Role-Based Design
- Hỗ trợ xem ở cả 2 vai trò: **Học sinh (Student)** và **Giáo viên (Teacher)**:
  - **Học sinh:** Thống kê *Bài đã thi*, *Điểm trung bình*, *Chuỗi bài thi*, *Biểu đồ điểm số*, *Huy hiệu thành tích*.
  - **Giáo viên:** Thống kê *Bộ đề đã tạo*, *Phòng thi đã tổ chức*, *Tổng lượt tham gia*, *Biểu đồ lượt tham gia*, *Huy hiệu giảng dạy*.

## 4. Technical Implementation Plan
- **Tệp chỉnh sửa chính:** `lib/screens/profile/profile_screen.dart`
- **Component biểu đồ:** Tách hoặc tích hợp `_ScoreLineChart` bằng `CustomPainter` vẽ đường nối điểm, chấm tròn highlight và vùng gradient mờ màu tím bên dưới.
- **Giữ nguyên TopNavBar:** Sử dụng `MainLayoutScreen` (đã có `TopNavBar` ở trên cùng).
