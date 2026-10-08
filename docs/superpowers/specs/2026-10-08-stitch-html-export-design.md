# Thiết Kế: Xuất Bộ Mã Nguồn Semantic HTML5/CSS Cho AI Stitch Redesign Giao Diện

> **Mục tiêu:** Tạo bộ mã nguồn HTML5 ngữ nghĩa và Vanilla CSS độc lập cho tất cả 10 màn hình cốt lõi của ứng dụng Thi Nhanh, kèm trang mục lục `index.html` điều hướng, đóng gói sẵn sàng để tải lên công cụ AI Stitch (hoặc các AI thiết kế UI/UX) để tái thiết kế giao diện toàn diện.

---

## 1. Nguyên Tắc & Tiêu Chuẩn Kỹ Thuật

- **Mỗi Màn Hình Là Một File Độc Lập:** Tất cả các tệp HTML đều nhúng sẵn CSS bên trong thẻ `<style>` để có thể hoạt động độc lập, mở xem trực tiếp trên mọi trình duyệt mà không cần cài đặt dependencies hay server, dễ dàng kéo thả/copy mã vào AI Stitch.
- **Cấu Trúc HTML5 Ngữ Nghĩa (Semantic HTML):** Sử dụng các thẻ chuẩn mực như `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, `<footer>`, `<button>`, `<input>` thay vì lạm dụng `<div>`, giúp AI phân tích chính xác vai trò từng phần tử giao diện.
- **Bộ Nhận Diện Thiết Kế Thống Nhất:**
  - Font chữ: Google Fonts `Be Vietnam Pro` (tối ưu tiếng Việt sắc nét).
  - Bảng màu: Primary Violet `#6557E8`, Dark Violet `#4E3EC8`, Background `#F7F5FE`, Text `#24233A`, Secondary Text `#6B7280`, Card `#FFFFFF`, Border `#E5E7EB`.
  - Responsive: Hỗ trợ linh hoạt cả giao diện Desktop và Mobile.

---

## 2. Danh Sách Các Màn Hình Xuất Bản (`stitch_design_export/`)

| Tên File | Màn Hình Tương Ứng Trong App | Các Thành Phần & Điểm Nhấn Thiết Kế |
| :--- | :--- | :--- |
| `index.html` | **Trang Mục Lục Tổng Quan** | Dashboard showcase liên kết đến toàn bộ 10 màn hình, mô tả vai trò và trạng thái từng trang. |
| `01_auth_greeting.html` | `GreetingScreen` | Hero banner sách phát sáng, Form đăng nhập Email/Mật khẩu, nút chuyển sang Đăng ký & nút "Khách tham gia nhanh". |
| `02_home_screen.html` | `HomeScreen` | Top navigation bar, danh mục 8 môn học phổ thông (Toán, Lý, Hóa, ...), thẻ "Bài Đang Làm", "Phòng Đang Diễn Ra", đề thi nổi bật, phòng thi vừa tạo. |
| `03_search_screen.html` | `SearchScreen` | Thanh tìm kiếm nhanh, bộ lọc môn học và độ khó, danh thiệp đề thi hiển thị thời gian tương đối động ("5 phút trước", "2 giờ trước"), thanh phân trang Google. |
| `04_exam_detail.html` | `ExamDetailScreen` | Thông tin chi tiết đề thi (số câu, thời lượng, tác giả), thẻ hành động nhập mã phòng / tự luyện thi, các khối lưu ý & quy chế phòng thi. |
| `05_taking_exam.html` | `TakingExamScreen` | Đồng hồ đếm ngược, banner cảnh báo giám sát chống gian lận, nội dung câu hỏi Toán học render LaTeX, 4 đáp án A/B/C/D, bảng lưới câu hỏi 1-40 bên cạnh. |
| `06_result_screen.html` | `ResultScreen` | Huy hiệu điểm số thang 10 nổi bật, card thống kê Đúng/Sai/Bỏ qua, nút làm lại câu sai & bảng tra cứu đáp án chi tiết. |
| `07_create_exam.html` | `CreateExamScreen` | Giao diện soạn đề giáo viên: Cây câu hỏi sidebar trái, trình soạn thảo công thức Toán học, danh sách đáp án trắc nghiệm, thanh công cụ toán học đáy trang. |
| `08_teacher_exams.html` | `TeacherExamsScreen` | Quản lý kho đề thi: 3 tabs (Tất cả, Đề nháp, Đã công khai), thanh tìm kiếm, danh sách thẻ đề thi có nút "Xuất bản", "Sửa", "Xóa". |
| `09_live_dashboard.html` | `LiveDashboardScreen` | Bảng điều khiển giám sát trực tiếp cho giáo viên: Tiến độ làm bài thực tế từng học sinh, cờ đỏ vi phạm 🚩, trạng thái thu bài ⛔. |
| `10_student_leaderboard.html` | `StudentLeaderboardScreen` | Bảng xếp hạng học sinh: Bục vinh danh Top 1, Top 2, Top 3 kèm huy chương, bảng điểm danh dự và nhãn phân biệt tài khoản chính thức vs `(Khách)`. |

---

## 3. Kế Hoạch Triển Khai & Kiểm Thử

1. **Khởi tạo thư mục `stitch_design_export/`:** Đặt trong thư mục gốc dự án `thi_nhanh/stitch_design_export/`.
2. **Biên soạn từng trang HTML:** Từng trang được viết chỉnh chu, tỉ mỉ, đầy đủ nội dung thực tế (không dùng placeholder vô nghĩa).
3. **Tạo trang `index.html` điều hướng trung tâm:** Cho phép xem trực quan từng trang.
4. **Kiểm tra hiển thị:** Đảm bảo tất cả các file mở mượt mà trên trình duyệt.
5. **Git Commit & Auto-Push:** Lưu trữ lên Git để đồng bộ.
