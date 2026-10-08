# Thiết Kế Chi Tiết: Chuẩn Hóa & Hoàn Thiện Bộ Giao Diện Stitch AI Redesign và Lộ Trình Đồng Bộ Sang Mã Nguồn Flutter

> **Ngày tạo:** 08/10/2026  
> **Trạng thái:** Bản thiết kế đã thông qua phỏng vấn chuyên sâu (/grill-me)  
> **Tài liệu tham chiếu:** `edtech_assessment_modern/DESIGN.md`, `stitch_web_redesign_html_mockups.zip`  

---

## 1. Bối Cảnh & Đánh Giá Toàn Diện Bản Thiết Kế Của Stitch AI

### 1.1. Ưu Điểm Nổi Bật của Stitch AI Redesign
1. **Design System chuyên nghiệp (`edtech_assessment_modern/DESIGN.md`):** Xây dựng bảng quy chuẩn Design Tokens rất chi tiết, bao gồm:
   - **Bảng màu:** Màu chủ đạo Deep Violet (`#6557E8` / `#4C3BCE`), nền tương phản Ink Navy (`#24233A`), bề mặt mềm mại Lavender (`#F7F5FE` / `#F8FAFC`), và các màu chức năng (Success Emerald `#10B981`, Warning Amber `#F59E0B`, Danger Coral `#EF4444`).
   - **Typography:** Chuẩn hóa toàn bộ bằng Google Fonts `Be Vietnam Pro` (từ 11px caption đến 32px headline-xl) kết hợp `Fira Code` cho số đếm thời gian thực và mã PIN.
   - **Đổ bóng quang học (Violet-tinted luminescence):** Sử dụng bóng mờ ánh tím `rgba(101, 87, 232, 0.08)` thay vì bóng xám vô hồn, tạo cảm giác công nghệ cao cấp, hiện đại.
   - **Bo góc (Curvature):** 8px (sm) $\rightarrow$ 12px (md) $\rightarrow$ 16px (lg) $\rightarrow$ 20-24px (xl) $\rightarrow$ 999px (pill).
2. **Chất lượng tạo hình các màn hình học sinh:** Các màn hình `01_auth_greeting`, `02_home_screen`, `10_student_leaderboard` đạt thẩm mỹ xuất sắc, bố cục thẻ cân đối, phân cấp trực quan rõ ràng.

### 1.2. Các Khiếm Khuyết & Lỗ Hổng Cần Khắc Phục
1. **Bỏ sót 2 màn hình cốt lõi:**
   - `04_exam_detail.html`: Màn hình trung gian quan trọng nhất dẫn dắt học sinh vào thi, nơi nhập mã PIN phòng thi và chọn chế độ thi thử offline.
   - `09_live_dashboard.html`: Màn hình giám sát phòng thi realtime của giáo viên với các tính năng độc quyền (cờ vi phạm rời tab 🚩, tiến độ realtime X/Y câu, thu bài cưỡng chế ⛔).
2. **Lỗi đặt tên thư mục & băm dấu tiếng Việt:** Các thư mục bị mất nguyên âm có dấu (ví dụ `01_m_n_h_nh_ch_o_m_ng_ng_nh_p`, `07_so_n_th_o_thi_chuy_n_s_u`), gây khó khăn khi liên kết và mở trên web.
3. **Ưu tiên màn hình:** Tập trung tối ưu trải nghiệm cho máy tính (Desktop/Laptop), nơi giáo viên soạn đề và học sinh làm bài thi tập trung, với bố cục thoáng đãng, sắc nét, không bị giật lag layout.

---

## 2. Kiến Trúc & Quy Chuẩn Bộ HTML Redesign Hoàn Thiện (`stitch_design_redesign/`)

Bộ giao diện sẽ được tổ chức lại gọn gàng tại thư mục:  
`c:\Users\ADMINE\Desktop\CODE\thi_nhanh\stitch_design_redesign/`

```
stitch_design_redesign/
├── index.html                           # Cổng điều hướng trung tâm (Hub) cập nhật thẩm mỹ Stitch
├── 01_auth_greeting.html                # Chào mừng & Đăng nhập (Hero Glowing Book, Google, Guest)
├── 02_home_screen.html                   # Trang chủ học tập (TopNav, Smart Nav Cards, 8 môn học)
├── 03_search_screen.html                # Tìm kiếm đề thi & Google Pagination
├── 04_exam_detail.html                  # Chi tiết đề thi & Nhập PIN phòng thi (Mới hoàn thiện theo Stitch)
├── 05_taking_exam.html                  # Phòng thi trực tuyến (Đếm ngược, Chống gian lận, LaTeX)
├── 06_result_screen.html                # Kết quả bài thi & Luyện câu sai (Thang điểm 10)
├── 07_create_exam.html                  # Soạn thảo đề thi chia 3 cột & Visual Math Editor
├── 08_teacher_exams.html                # Quản lý kho đề thi giáo viên (Tabs & Actions)
├── 09_live_dashboard.html               # Giám sát phòng thi Realtime (Mới hoàn thiện theo Stitch)
└── 10_student_leaderboard.html          # Bảng vàng vinh danh (Bục Top 1-2-3 Podium)
```

### Chi Tiết Cải Tiến 2 Màn Hình Được Hoàn Thiện Mới:
- **`04_exam_detail.html`:**
  - Hero Card với gradient Deep Violet (`#6557E8` $\rightarrow$ `#402DB5`).
  - Hộp thông tin đề thi: Môn học, Thời gian, Số câu hỏi, Tác giả kèm avatar.
  - Phân vùng 2 hành động rõ rệt: (A) Ô nhập mã PIN phòng thi kèm nút "Vào phòng thi ngay"; (B) Nút "Tự luyện tập tự do".
  - Hộp cảnh báo quy chế phòng thi: Nhắc nhở về việc giám sát rời màn hình, xáo trộn câu hỏi.
- **`09_live_dashboard.html`:**
  - Thanh tiêu đề trực tiếp với chấm phát sáng xanh `pulse-dot`, tiêu đề phòng thi, đồng hồ đếm ngược Fira Code.
  - Hộp mã PIN phòng thi cỡ lớn kèm nút bấm 1-chạm sao chép liên kết.
  - 4 thẻ Metric thời gian thực: Thí sinh có mặt, Đã nộp bài, Cảnh báo vi phạm (màu coral `#EF4444`), Điểm trung bình tạm tính.
  - Bảng học sinh trực tuyến: Avatar chữ cái, tên học sinh, tiến độ thanh progress bar, trạng thái vi phạm (0 lần xanh lá / 1 lần cảnh báo vàng / 2+ lần cờ đỏ 🚩), các nút hành động: Xem bài làm live, Cảnh cáo, Thu bài cưỡng chế ⛔.

---

## 3. Lộ Trình Đồng Bộ Sang Mã Nguồn Flutter (`lib/`)

Quá trình đồng bộ sang Flutter sẽ thực hiện theo 2 giai đoạn:

### Giai Đoạn 1: Xuất Bản & Nghiệm Thu Bộ HTML Hoàn Hảo (Immediate Deliverable)
- Tạo toàn bộ thư mục `stitch_design_redesign/` chứa 11 tệp HTML hoàn thiện 100%.
- Kiểm tra tính liên kết: Các nút điều hướng trong các file HTML đều click qua lại được giữa các màn hình một cách liền mạch.
- Nghiệm thu trực quan cùng người dùng.

### Giai Đoạn 2: Đồng Bộ Từng Bước Vào Mã Nguồn Flutter (Phased Implementation Plan)
1. **Đồng bộ Theme & Design System (`lib/core/theme/app_theme.dart`):**
   - Định nghĩa chính xác bảng màu Stitch: `primary: 0xFF6557E8`, `secondary: 0xFF24233A`, `surface: 0xFFF7F5FE`, `canvas: 0xFFF8FAFC`.
   - Cập nhật bóng đổ `BoxShadow(color: Color(0x146557E8), blurRadius: 16, offset: Offset(0, 4))`.
2. **Đồng bộ Nhóm Màn Hình Học Sinh:**
   - `auth_screen.dart` $\rightarrow$ Thẩm mỹ 01.
   - `home_screen.dart` $\rightarrow$ Thẩm mỹ 02.
   - `search_screen.dart` & `exam_detail_screen.dart` $\rightarrow$ Thẩm mỹ 03, 04.
   - `taking_exam_screen.dart` & `result_screen.dart` $\rightarrow$ Thẩm mỹ 05, 06.
   - `student_leaderboard_screen.dart` $\rightarrow$ Thẩm mỹ 10 (Podium Top 1-2-3).
3. **Đồng bộ Nhóm Màn Hình Giáo Viên:**
   - `teacher_exams_screen.dart` $\rightarrow$ Thẩm mỹ 08.
   - `create_exam_screen.dart` $\rightarrow$ Thẩm mỹ 07 (Visual Math blocks).
   - `live_dashboard_screen.dart` $\rightarrow$ Thẩm mỹ 09 (Realtime monitoring).
4. **Kiểm thử tự động & TDD:**
   - Duy trì 100% số lượng bài kiểm thử (173/173 tests PASS).
   - Tự động chạy git commit & git push theo quy tắc của dự án.
   - Cập nhật tài liệu kiến trúc `system_architecture_and_deep_evaluation.md`.
