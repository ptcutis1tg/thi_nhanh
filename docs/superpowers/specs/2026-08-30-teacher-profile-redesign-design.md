# Design Spec: Enhanced Teacher Profile Dashboard ("Thi Nhanh")

## 1. Overview
Tối ưu hóa và nâng cấp màn hình **Hồ sơ Giáo viên (Teacher Profile Dashboard)** trong ứng dụng **Thi Nhanh** sao cho phù hợp 100% với vai trò giảng dạy, quản lý đề thi và phòng thi. Loại bỏ hoàn toàn các thông tin cá nhân của học sinh (điểm bài thi cá nhân, chuỗi bài thi, thành tích học sinh) ở giao diện giáo viên, thay thế bằng các thông số thống kê bài học, phòng thi, bộ đề và gợi ý cần chú ý (Teaching Insights).

Hệ thống giữ nguyên 100% nhận diện thương hiệu hiện tại (Tone tím `Color(0xFF6557E8)`, nền xám nhạt `Color(0xFFF8F8FC)`, thẻ bo cong 24px, bo góc input 12px, Be Vietnam Pro typography) và cho phép chuyển đổi linh hoạt giữa góc nhìn **Học sinh (Student)** và **Giáo viên (Teacher)** trên cùng một component `ProfileScreen`.

## 2. Desktop Page Hierarchy for Teacher Role

```
+-----------------------------------------------------------------------------------+
| 1. TEACHER PROFILE HEADER CARD                                                     |
| [Avatar + Badge 👨‍🏫 Giáo viên + Name/Email] | [12 Bộ đề | 35 Phòng | 450 Lượt | 8.1 ĐTB] |
+-----------------------------------------------------------------------------------+
| 2. MAIN TEACHING ANALYTICS & OVERVIEW (2 Columns)                                 |
| [LEFT 65%]: 📊 Thống kê giảng dạy                 | [RIGHT 35%]: 📌 Tổng quan đề thi|
| - Biểu đồ lượt học sinh 6 phòng gần nhất         | - 240 câu hỏi                    |
| - 👥 Phòng đông nhất (45) | ✓ Tỷ lệ hoàn thành (92%)| - 76% tỷ lệ đúng                 |
|   📈 Điểm TB học sinh (8.1)                      | - ⚠️ Câu khó nhất (Câu 8, 42%)   |
|                                                  | - 🔥 Đề tham gia nhiều nhất (86) |
+-----------------------------------------------------------------------------------+
| 3. RECENT EXAM ROOMS CARD                                                          |
| 🕘 Phòng thi gần đây                   [+ Tạo phòng thi]                           |
| (Danh sách hàng ngang: Tên phòng, Mã phòng, Ngày, Số HS, Status pill, [Xem kết quả →])|
|                                                      [Xem tất cả phòng thi →]     |
+-----------------------------------------------------------------------------------+
| 4. MY EXAM SETS CARD                                                              |
| 📝 Bộ đề của tôi                       [+ Tạo đề thi]                              |
| (Danh sách bộ đề: Tên đề, Số câu, Thời gian, Số lượt thi, [Chỉnh sửa] [Tạo phòng →])|
|                                                      [Xem tất cả bộ đề →]         |
+-----------------------------------------------------------------------------------+
| 5. TEACHING INSIGHTS CARD                                                         |
| 💡 Cần chú ý (2-3 thẻ gợi ý thông minh về câu hỏi khó, điểm số tăng/giảm)        |
+-----------------------------------------------------------------------------------+
| 6. ACCOUNT SETTINGS & PASSWORD                                                    |
| ⚙️ Thông tin cá nhân (Họ tên, Gmail đăng ký ✓, [Lưu])                              |
| 🔑 Thay đổi mật khẩu (Mật khẩu hiện tại, mới, xác nhận + eye toggle, [Đổi MK])   |
+-----------------------------------------------------------------------------------+
| 7. ACCOUNT ACTIONS                                                                |
| [Đăng xuất]                                                  Xóa tài khoản        |
+-----------------------------------------------------------------------------------+
```

## 3. Detailed Component Spec for Teacher Role

### Header Card (Thống kê Giáo viên)
- 4 chỉ số hiển thị dạng cột ngăn cách bởi đường vạch đứng:
  - `12` / `Bộ đề đã tạo`
  - `35` / `Phòng thi`
  - `450` / `Lượt tham gia`
  - `8.1` / `Điểm TB học sinh`

### Teaching Analytics (Cột trái 65%)
- Custom Line/Bar Chart hiển thị số lượt học sinh tham gia 6 phòng gần nhất (Phòng 1: 32, Phòng 2: 41, Phòng 3: 28, Phòng 4: 45, Phòng 5: 38, Phòng 6: 43).
- 3 chỉ số phụ xếp hàng ngang:
  - 👥 **Phòng đông nhất**: `45 học sinh`
  - ✓ **Tỷ lệ hoàn thành**: `92%`
  - 📈 **Điểm TB học sinh**: `8.1`

### Exam Overview (Cột phải 35%)
- Thay thế card "Thành tích".
- 4 chỉ số giảng dạy với nền icon pastel dịu nhẹ:
  - 📝 **Tổng số câu hỏi**: `240 câu`
  - 🎯 **Tỷ lệ trả lời đúng**: `76%`
  - ⚠️ **Câu khó nhất**: `Câu 8 – Toán 12 (42% đúng)`
  - 🔥 **Đề được tham gia nhiều nhất**: `Ôn tập Toán HK1 (86 lượt)`

### Recent Exam Rooms (Phòng thi gần đây)
- Có nút `[+ Tạo phòng thi]` ở góc trên bên phải.
- Mỗi hàng gồm: Tên phòng, Mã phòng, Ngày tạo, Số lượng học sinh, Badge trạng thái (Đã kết thúc: Xám, Đang diễn ra: Xanh lục, Sắp diễn ra: Tím), Nút `[Xem kết quả →]`.

### My Exam Sets (Bộ đề của tôi)
- Có nút `[+ Tạo đề thi]` ở góc trên bên phải.
- Mỗi hàng gồm: Tên đề thi, Số câu • Thời gian • Số lượt thi • Ngày cập nhật, Nút `[Chỉnh sửa]` và `[Tạo phòng →]`.

### Teaching Insights (Cần chú ý)
- Hiển thị 2-3 gợi ý giảng dạy:
  - 💡 *42% học sinh trả lời sai câu 8 trong đề Toán 12 – Hàm số.*
  - 💡 *Câu hỏi về đạo hàm có tỷ lệ đúng thấp nhất: 58%.*
  - 📈 *Điểm trung bình của phòng Toán 12 gần nhất tăng 0.6 điểm.*
