# Kế Hoạch Triển Khai: Chuẩn Hóa & Hoàn Thiện Bộ Giao Diện Stitch AI Redesign và Đồng Bộ Sang Mã Nguồn Flutter

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` or `superpowers:subagent-driven-development` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn thiện 100% bộ giao diện HTML5/CSS chuẩn mực trong thư mục `stitch_design_redesign/` kế thừa toàn bộ thẩm mỹ Stitch AI (`#6557E8`, `#24233A`, `#F7F5FE`, Be Vietnam Pro, Fira Code), đồng thời bảo toàn 100% logic nghiệp vụ của app hiện tại (TopNavBar 4 mục: Home, Tìm kiếm, Quản lí đề, Tạo phòng thi; đếm ngược 3-2-1; chống gian lận 0/3; mã PIN phòng PT; cờ vi phạm 🚩; nhập đề hàng loạt; 2 Smart Cards), sau đó đồng bộ từng bước sang mã nguồn Flutter (`lib/`).

**Architecture:** 
- Giai đoạn 1: Xây dựng 11 tệp HTML độc lập tự chứa CSS trong `stitch_design_redesign/` với 100% liên kết điều hướng click qua lại mượt mà, khắc phục toàn bộ lỗi của Stitch (thiếu màn 04 & 09, lỗi TopNav phân mảnh, lỗi lưới câu hỏi bị đè nút nộp bài, lỗi cắt cụt tiêu đề, lỗi thiếu công tắc bảo mật).
- Giai đoạn 2: Đồng bộ các Design Tokens vào `AppTheme`, chuẩn hóa `TopNavBar` Flutter và kiểm thử hồi quy 173/173 tests PASS.

**Tech Stack:** Semantic HTML5, Vanilla CSS, Google Fonts Be Vietnam Pro & Fira Code, Flutter 3.x, Dart 3.x, GoRouter, Provider, Supabase Realtime.

## Global Constraints
- **TopNavBar chuẩn:** Bắt buộc có đúng 4 thành phần thực tế: `Home` (`02_home_screen.html`), `Tìm kiếm` (`03_search_screen.html`), `Quản lí đề` (`08_teacher_exams.html`), `Tạo phòng thi` (`09_live_dashboard.html`), kèm ô nhập PIN `[Nhập mã PT...]` và Avatar người dùng `M`.
- **Thẩm mỹ Stitch:** Áp dụng hệ màu EdTech Modern: Primary Violet `#6557E8`, Secondary Ink `#24233A`, Lavender surface `#F7F5FE`, bóng mờ ánh tím `rgba(101, 87, 232, 0.08)`.
- **Không phá vỡ kiểm thử Flutter:** Giữ vững 173/173 tests PASS trong suốt quá trình đồng bộ code Flutter.
- **Auto-push:** Commit và push code lên GitHub repo `thi_nhanh` và `CODE` sau khi hoàn thành.

---

### Task 1: Thiết Lập Thư Mục & Tạo Cổng Mục Lục Trung Tâm (`stitch_design_redesign/index.html`)

**Files:**
- Create: `stitch_design_redesign/index.html`

- [ ] **Step 1: Khởi tạo thư mục `stitch_design_redesign/`**
- [ ] **Step 2: Viết mã nguồn `index.html`** với giao diện Showcase Hub hiện đại:
  - Bảng giới thiệu hệ thống Design System EdTech Modern.
  - Lưới 10 thẻ xem trước màn hình kèm nhãn phân loại (Học Sinh, Giáo Viên, Khảo Thí Realtime).
  - Tích hợp liên kết trực tiếp đến toàn bộ 10 màn hình.
  - Bảng tổng hợp đối soát các điểm cải tiến vượt trội so với bản gốc của Stitch AI.
- [ ] **Step 3: Kiểm tra hiển thị file `index.html`**

---

### Task 2: Xuất Nhóm Màn Hình Đăng Nhập & Khám Phá Học Sinh (`01`, `02`, `03`)

**Files:**
- Create: `stitch_design_redesign/01_auth_greeting.html`
- Create: `stitch_design_redesign/02_home_screen.html`
- Create: `stitch_design_redesign/03_search_screen.html`

- [ ] **Step 1: Tạo `01_auth_greeting.html`**
  - Cột trái: Hero Glowing Book, biểu tượng sấm sét `⚡ Thi Nhanh`, 3 chips thống kê.
  - Cột phải: Form đăng nhập/đăng ký OTP, **khôi phục nút Đăng nhập bằng Google** (`assets/images/google_logo.png`), nút **Tham gia nhanh với Chế độ Khách**.
- [ ] **Step 2: Tạo `02_home_screen.html`**
  - Áp dụng **Global App TopNavBar chuẩn 4 mục** (Home active, Tìm kiếm, Quản lí đề, Tạo phòng thi) + ô nhập PIN + Avatar.
  - Hero banner với toggle workspace (🎓 Học tập / 👨‍🏫 Soạn đề).
  - 8 môn học thực tế dạng chip bo góc.
  - **2 Smart Navigation Cards:** "⚡ ĐANG LÀM DỞ DANG" (Vật Lý 12 - Dao Động Cơ Học) và "🏛️ PHÒNG THI ĐANG DIỄN RA" (Phòng PT888999 - Khảo Sát Toán).
  - Lưới đề thi nổi bật + Nút trợ lý AI nổi (`AiNavigationButton`).
- [ ] **Step 3: Tạo `03_search_screen.html`**
  - Áp dụng **Global App TopNavBar chuẩn 4 mục** (Tìm kiếm active) + ô nhập PIN + Avatar.
  - Thanh tìm kiếm lớn bo tròn, 8 chip môn học, dropdown độ khó & sắp xếp.
  - Danh sách đề thi kết quả với thời gian tương đối động `formatRelativeTime` (15 phút trước, 2 giờ trước).
  - Thanh phân trang **GooglePaginationBar** thực tế của app.
- [ ] **Step 4: Commit Task 2 vào Git**

---

### Task 3: Xuất Nhóm Màn Hình Chi Tiết, Làm Bài & Kết Quả (`04`, `05`, `06`)

**Files:**
- Create: `stitch_design_redesign/04_exam_detail.html`
- Create: `stitch_design_redesign/05_taking_exam.html`
- Create: `stitch_design_redesign/06_result_screen.html`

- [ ] **Step 1: Tạo mới hoàn toàn `04_exam_detail.html` theo chuẩn Stitch**
  - TopNavBar chuẩn 4 mục + ô nhập PIN + Avatar.
  - Breadcrumbs điều hướng `Trang Chủ > Khám Phá Đề > Chi Tiết`.
  - Hero Card đề thi Deep Violet: Môn học, Thời gian, Số câu, Tác giả kèm avatar.
  - **2 Hành động rõ ràng:** (A) Ô nhập mã PIN phòng thi giáo viên yêu cầu kèm nút "Vào phòng thi ngay"; (B) Nút "Tự luyện tập" offline.
  - Hộp thông báo quy chế phòng thi và chống gian lận.
- [ ] **Step 2: Tạo `05_taking_exam.html` với bản sửa lỗi toàn diện**
  - Focused Exam Bar: Nút Thoát (về 04) + Tiêu đề đề thi/Mã đề + Đồng hồ đếm ngược Fira Code `42:15` đập nhịp + Nút Nộp bài (sang 06).
  - Banner cảnh báo giám sát toàn màn hình (0/3 lần vi phạm).
  - Thẻ câu hỏi với công thức toán học LaTeX sắc nét, 4 phương án A-B-C-D.
  - **Khắc phục lỗi Stitch:** Sửa lỗi bảng 40 câu hỏi bị nút nộp bài đè lên bằng container có scroll `overflow-y: auto` và khoảng đệm chân trang.
- [ ] **Step 3: Tạo `06_result_screen.html`**
  - TopNavBar chuẩn 4 mục + ô nhập PIN + Avatar.
  - Hero Score Card màu Ink Navy `#24233A` với điểm số cỡ lớn `8.50/10` font Fira Code.
  - 4 Thẻ thống kê: Đúng (34), Sai (4), Chưa làm (2), Độ chính xác (85%).
  - Hàng nút hành động: **"🔄 Luyện tập lại 4 câu sai"**, "📝 Thi lại toàn bộ đề", "🏆 Bảng xếp hạng phòng".
  - Khu vực xem lại chi tiết bài làm có bộ lọc (Tất cả / Câu sai / Câu đúng) và lời giải từng bước.
- [ ] **Step 4: Commit Task 3 vào Git**

---

### Task 4: Xuất Nhóm Màn Hình Quản Trị Giáo Viên & Bảng Vàng (`07`, `08`, `09`, `10`)

**Files:**
- Create: `stitch_design_redesign/07_create_exam.html`
- Create: `stitch_design_redesign/08_teacher_exams.html`
- Create: `stitch_design_redesign/09_live_dashboard.html`
- Create: `stitch_design_redesign/10_student_leaderboard.html`

- [ ] **Step 1: Tạo `07_create_exam.html` với bản sửa lỗi toàn diện**
  - Focused Editor Bar: Nút Trở về `← Quản lý đề` (về 08), ô nhập tiêu đề đề thi rộng rãi (không bị cắt cụt `...`), Badge Bản nháp, nút Lưu tạm, nút Xuất bản.
  - Giao diện 3 cột:
    - Cột trái: Cây danh sách 40 câu hỏi + nút "+ Thêm câu" và nút "Nhập nhanh từ văn bản (Bulk Import)".
    - Cột giữa: Visual Math Editor với thanh công cụ toán học nhanh, nội dung câu hỏi, 4 đáp án A-B-C-D kèm radio đáp án đúng, lời giải chi tiết.
    - Cột phải: **Khôi phục toàn bộ công tắc bảo mật** mà Stitch đã cắt bỏ (Trộn câu hỏi, Trộn đáp án, Giám sát chống gian lận).
- [ ] **Step 2: Tạo `08_teacher_exams.html`**
  - TopNavBar chuẩn 4 mục (Quản lí đề active) + ô nhập PIN + Avatar (**loại bỏ nút trùng lặp trên navbar**).
  - 4 Thẻ thống kê kho đề thi (Tổng số đề, Đã xuất bản, Bản nháp, Lượt thí sinh).
  - 3 Tabs trạng thái (Tất cả, Đã xuất bản, Bản nháp) kết hợp **thanh tìm kiếm kho đề và lọc môn học**.
  - Thẻ đề thi với các nút: "📡 Mở phòng thi" (sang 09), "✏️ Sửa", "👁️ Xem", "🗑️ Xóa".
- [ ] **Step 3: Tạo mới hoàn toàn `09_live_dashboard.html` theo chuẩn Stitch**
  - Focused Proctoring Bar: Nút Thoát phòng (về 08) + Chấm xanh trực tiếp `pulse-dot` + Mã PIN phòng cỡ lớn kèm nút 1-chạm sao chép + Nút `⛔ Thu bài toàn phòng`.
  - 4 Thẻ metric thời gian thực: Thí sinh có mặt (24/25), Đã nộp bài (6), Cảnh báo vi phạm (2 - màu coral `#EF4444`), Điểm trung bình (7.85).
  - Bảng theo dõi học sinh thời gian thực: Tiến độ X/Y câu, **cờ vi phạm rời tab 🚩**, nút Xem bài, Nhắc nhở, Thu bài cưỡng chế ⛔.
- [ ] **Step 4: Tạo `10_student_leaderboard.html`**
  - TopNavBar chuẩn 4 mục (Bảng vàng) + ô nhập PIN + Avatar.
  - Bục Top 1-2-3 Podium với hiệu ứng vương miện 👑 Quán quân và màu Vàng/Bạc/Đồng.
  - Bảng điểm xếp hạng đầy đủ với phân biệt học sinh chính thức vs tài khoản vãng lai `(Khách)`.
  - **Khôi phục thanh Sticky Bar cố định ở đáy màn hình:** Báo thứ hạng người dùng hiện tại (`Hạng #3 • Điểm 9.50 • Thời gian 34m 25s`).
- [ ] **Step 5: Commit Task 4 vào Git**

---

### Task 5: Kiểm Thử Toàn Diện Bộ HTML & Nghiệm Thu Trực Quan

- [ ] **Step 1: Kiểm tra tính liên kết (Click Navigation):**
  - Thử nghiệm click toàn bộ các link trên TopNavBar và các nút CTA giữa 10 màn hình để xác nhận không còn bất kỳ link chết `href="#"` nào.
- [ ] **Step 2: Kiểm tra độ tương thích & Responsive máy tính (Desktop/Laptop):**
  - Đảm bảo layout 1440px / 1200px / 1024px không bị co dúm hay overflow vỡ khung.
- [ ] **Step 3: Báo cáo nghiệm thu hoàn thành Giai đoạn 1 cho người dùng.**

---

### Task 6: Đồng Bộ Giai Đoạn 2 Sang Mã Nguồn Flutter (`lib/`)

- [ ] **Step 1: Cập nhật Design System Tokens (`lib/core/theme/app_theme.dart`):**
  - Cập nhật các hằng số màu sắc, bóng đổ luminescence ánh tím, và typography Be Vietnam Pro.
- [ ] **Step 2: Cập nhật `lib/shared/widgets/top_nav_bar.dart`:**
  - Đồng bộ giao diện TopNavBar theo chuẩn mẫu đã thống nhất (chuẩn 4 mục: Home, Tìm kiếm, Quản lí đề, Tạo phòng thi).
- [ ] **Step 3: Chạy toàn bộ kiểm thử Flutter:**
  - Lệnh: `flutter test`
  - Đảm bảo 173 / 173 bài test PASS 100%.
- [ ] **Step 4: Cập nhật tài liệu kiến trúc & Đồng bộ Artifact:**
  - Cập nhật `docs/system_architecture_and_deep_evaluation.md` và artifact tương ứng.
- [ ] **Step 5: Git commit & auto-push lên GitHub cả 2 repo `thi_nhanh` và `CODE`.**
