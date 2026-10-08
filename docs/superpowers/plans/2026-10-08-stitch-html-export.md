# Xuất Bộ Mã Nguồn Semantic HTML5/CSS Cho AI Stitch Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xuất bản trọn bộ 10 màn hình giao diện cốt lõi của Thi Nhanh dưới dạng các tệp Semantic HTML5 + Vanilla CSS độc lập, kèm trang mục lục `index.html` điều hướng, được thiết kế chỉn chu, hiện đại để sẵn sàng cung cấp cho AI Stitch (hoặc các AI thiết kế UI) tái thiết kế giao diện toàn diện.

**Architecture:** Tạo thư mục `thi_nhanh/stitch_design_export/`. Mỗi màn hình là một file HTML độc lập chứa đầy đủ cấu trúc ngữ nghĩa (`<header>`, `<nav>`, `<main>`, `<article>`, `<section>`, v.v.) và nhúng sẵn khối `<style>` tự chứa, sử dụng font chữ `Be Vietnam Pro`, bảng màu Violet/Ink của hệ thống và layout responsive flex/grid.

**Tech Stack:** HTML5 Semantic, Vanilla CSS (Modern CSS variables, flexbox, CSS grid, smooth transitions), Google Fonts (Be Vietnam Pro).

## Global Constraints
- Mỗi file HTML phải tự chứa (self-contained) hoàn chỉnh CSS, có thể mở trực tiếp bằng trình duyệt không cần local server.
- Sử dụng đầy đủ các nhãn ngữ nghĩa, text thực tế phản ánh chính xác cấu trúc dữ liệu và tính năng của ứng dụng Thi Nhanh.
- Đảm bảo 100% test suite hiện tại của dự án tiếp tục màu xanh (không làm ảnh hưởng mã nguồn Dart/Flutter).
- Tự động commit và đẩy mã nguồn lên GitHub sau khi hoàn thành.

---

### Task 1: Thiết lập thư mục & Tạo Trang Mục Lục Trung Tâm (`index.html`)

**Files:**
- Create: `stitch_design_export/index.html`

**Interfaces:**
- Consumes: Cấu trúc 10 màn hình từ bản thiết kế
- Produces: Showcase dashboard hiển thị danh mục, mô tả, thẻ xem trước và liên kết mở nhanh tới tất cả các màn hình.

- [ ] **Step 1: Khởi tạo thư mục `stitch_design_export/`**
- [ ] **Step 2: Viết mã nguồn `stitch_design_export/index.html`**
  - Header mang nhận diện thương hiệu "Thi Nhanh - Stitch Redesign Export Hub".
  - Grid card hiển thị 10 màn hình kèm tag phân loại (Học sinh, Giáo viên, Giám sát phòng thi).
  - Khối hướng dẫn cách copy mã hoặc kéo thả vào công cụ AI Stitch.
- [ ] **Step 3: Kiểm tra hiển thị file trên trình duyệt hoặc công cụ đọc tệp**
- [ ] **Step 4: Commit task 1**

---

### Task 2: Xuất nhóm Màn Hình Chào Mừng & Khám Phá (`01_auth_greeting.html`, `02_home_screen.html`, `03_search_screen.html`)

**Files:**
- Create: `stitch_design_export/01_auth_greeting.html`
- Create: `stitch_design_export/02_home_screen.html`
- Create: `stitch_design_export/03_search_screen.html`

**Interfaces:**
- Consumes: `GreetingScreen`, `HomeScreen`, `SearchScreen` trong `lib/`
- Produces: 3 file HTML độc lập mô tả toàn diện luồng Onboarding, Trang chủ điều hướng thông minh và Tìm kiếm đề thi.

- [ ] **Step 1: Tạo `01_auth_greeting.html`**
  - Hero book layout, form Email/Password, nút Đăng nhập, nút Đăng ký, modal hoặc tab Chế độ Khách tham gia nhanh không cần mật khẩu.
- [ ] **Step 2: Tạo `02_home_screen.html`**
  - Top navigation bar (Logo, Home, Search, Leaderboard, History, Avatar dropdown).
  - Chip 8 môn học phổ thông (Toán, Vật lý, Hóa học, Sinh học, Lịch sử, Địa lý, GDCD, Tiếng Anh).
  - Ô nhập nhanh mã phòng thi ("Nhập mã phòng PTxxxxxx...").
  - Thẻ thông minh "Bài Đang Làm" và "Phòng Đang Diễn Ra".
  - Danh sách đề thi nổi bật và phòng thi vừa tạo.
- [ ] **Step 3: Tạo `03_search_screen.html`**
  - Thanh tìm kiếm từ khóa, thanh lọc 8 môn học, bộ lọc mức độ (Dễ, Trung bình, Khó).
  - Danh sách thẻ đề thi có hiển thị thời gian tương đối động ("5 phút trước", "2 giờ trước").
  - Thanh phân trang Google Pagination Bar (Prev, 1, 2, 3... Next).
- [ ] **Step 4: Commit task 2**

---

### Task 3: Xuất nhóm Màn Hình Làm Bài Thi & Bảng Điểm (`04_exam_detail.html`, `05_taking_exam.html`, `06_result_screen.html`)

**Files:**
- Create: `stitch_design_export/04_exam_detail.html`
- Create: `stitch_design_export/05_taking_exam.html`
- Create: `stitch_design_export/06_result_screen.html`

**Interfaces:**
- Consumes: `ExamDetailScreen`, `TakingExamScreen`, `ResultScreen`
- Produces: 3 file HTML thể hiện chi tiết luồng học sinh chuẩn bị vào thi, giao diện làm bài chống gian lận và màn hình kết quả điểm số.

- [ ] **Step 1: Tạo `04_exam_detail.html`**
  - Breadcrumbs điều hướng (Trang chủ > Tìm kiếm > Chi tiết đề thi).
  - Header đề thi: Tên đề, tác giả, môn, số câu hỏi, thời lượng (phút).
  - Thẻ hành động: Nút "Bắt đầu tự luyện", ô nhập mã phòng thi, nút lưu đề.
  - Các khối thông tin: "Giới thiệu bài thi", "Hướng dẫn & Quy chế".
- [ ] **Step 2: Tạo `05_taking_exam.html`**
  - Thanh điều hướng bài thi: Tên đề, đồng hồ đếm ngược thời gian thực, nút Nộp bài thi.
  - Banner chống gian lận: Chỉ báo trạng thái giám sát vi phạm rời tab/màn hình.
  - Khung nội dung câu hỏi trắc nghiệm Toán học có công thức LaTeX (phân số, tích phân, căn thức).
  - 4 phương án lựa chọn A, B, C, D với hiệu ứng chọn rõ ràng.
  - Sidebar bảng lưới câu hỏi 1-40 hiển thị trạng thái đã chọn/chưa chọn.
- [ ] **Step 3: Tạo `06_result_screen.html`**
  - Banner chúc mừng với huy hiệu điểm số lớn (thang điểm 10).
  - Card thống kê 3 cột: Số câu Đúng (xanh), Số câu Sai (đỏ), Bỏ qua (xám).
  - Nút "Luyện tập lại câu sai" và "Xem chi tiết lời giải".
  - Danh sách đáp án chi tiết từng câu hỏi đối chiếu bài làm học sinh.
- [ ] **Step 4: Commit task 3**

---

### Task 4: Xuất nhóm Màn Hình Quản Trị Giáo Viên & Giám Sát Phòng Thi (`07_create_exam.html`, `08_teacher_exams.html`, `09_live_dashboard.html`)

**Files:**
- Create: `stitch_design_export/07_create_exam.html`
- Create: `stitch_design_export/08_teacher_exams.html`
- Create: `stitch_design_export/09_live_dashboard.html`

**Interfaces:**
- Consumes: `CreateExamScreen`, `TeacherExamsScreen`, `LiveDashboardScreen`
- Produces: 3 file HTML phục vụ giao diện giáo viên: soạn thảo đề thi chuyên sâu, kho đề thi và bảng theo dõi thi trực tiếp.

- [ ] **Step 1: Tạo `07_create_exam.html`**
  - Header: Tên đề, thời gian, môn học, nút Xem trước & Lưu bản thảo.
  - Sidebar trái: Danh sách cây câu hỏi (Câu 1, Câu 2... thêm câu hỏi).
  - Khu vực chính: Soạn thảo câu hỏi Toán học với Visual Math Block & LaTeX.
  - Danh sách phương án trả lời kèm radio đánh dấu đáp án đúng.
  - Thanh công cụ toán học đáy màn hình: Ký hiệu toán học (phân số, lũy thừa, căn, tích phân, ma trận).
- [ ] **Step 2: Tạo `08_teacher_exams.html`**
  - Header: "📁 Quản Lý Kho Đề Thi Trắc Nghiệm", nút "Tạo Đề Thi Mới".
  - Thanh 3 tabs kèm bộ đếm: Tất cả (2), Đề nháp (1), Đã công khai (1).
  - Thanh tìm kiếm và dropdown chọn môn học.
  - Danh sách thẻ đề thi với nút "Xuất bản đề", "Sửa đề", "Xóa đề".
- [ ] **Step 3: Tạo `09_live_dashboard.html`**
  - Header: Tên phòng thi, mã phòng `PTxxxxxx`, đồng hồ đếm ngược phòng, nút "Đóng phòng thi".
  - 4 thẻ thống kê tổng quan: Tổng thí sinh, Đang làm bài, Đã nộp bài, Cảnh báo vi phạm.
  - Bảng danh sách thí sinh làm bài theo thời gian thực: Tên học sinh, Tiến độ (X/Y câu), Điểm hiện tại, Cờ đỏ cảnh báo vi phạm 🚩, Huy hiệu thu bài ⛔.
- [ ] **Step 4: Commit task 4**

---

### Task 5: Xuất Màn Hình Bảng Xếp Hạng & Kiểm Tra Mở Trình Duyệt, Đồng Bộ Tài Liệu, Auto-Push (`10_student_leaderboard.html`)

**Files:**
- Create: `stitch_design_export/10_student_leaderboard.html`
- Modify: `docs/system_architecture_and_deep_evaluation.md`

- [ ] **Step 1: Tạo `10_student_leaderboard.html`**
  - Bục vinh danh Top 3 thí sinh xuất sắc (Top 1 Gold, Top 2 Silver, Top 3 Bronze) với avatar, vương miện, điểm số.
  - Bộ lọc bảng xếp hạng theo Tuần / Tháng / Môn học.
  - Bảng xếp hạng chi tiết từ Top 4 trở đi, hiển thị avatar, tên người dùng từ `profiles`, nhãn phân biệt Khách `(Khách)`, điểm số và thời gian hoàn thành.
- [ ] **Step 2: Chạy kiểm thử tự động toàn dự án (`flutter test`) xác nhận 173/173 tests PASS**
- [ ] **Step 3: Cập nhật tài liệu kiến trúc `docs/system_architecture_and_deep_evaluation.md`**
- [ ] **Step 4: Đồng bộ Artifact IDE**
- [ ] **Step 5: Git commit và push lên GitHub cả `thi_nhanh` và `CODE`**
