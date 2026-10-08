# Thiết Kế Chi Tiết: Chuẩn Hóa & Hoàn Thiện Bộ Giao Diện Stitch AI Redesign — Kế Thừa Thẩm Mỹ Hiện Đại, Giữ Nguyên 100% Logic Nghiệp Vụ Cốt Lõi

> **Ngày cập nhật:** 09/10/2026  
> **Trạng thái:** Đã thống nhất & Phê duyệt nguyên tắc cốt lõi  
> **Nguyên tắc chỉ đạo:**  
> 1. **Thẩm mỹ & Bố cục:** Kế thừa toàn bộ hệ thống màu sắc, typography, bo góc, bóng mờ luminescence ánh tím và cách bố cục thẻ hiện đại từ Stitch AI.  
> 2. **Logic & Kiến trúc ứng dụng:** Giữ nguyên 100% logic nghiệp vụ thực tế của ứng dụng `thi_nhanh` (Flutter), tuyệt đối không để các lỗi bịa đặt/cắt xén của Stitch làm sai lệch cấu trúc hệ thống.  

---

## 1. Chuẩn Hóa Top Navigation Bar: Giữ Nguyên 4 Thành Phần Của App Thực Tế

Trong ứng dụng Flutter (`lib/shared/widgets/top_nav_bar.dart` và `lib/main.dart`), toàn bộ các màn hình chính đều được bọc trong `ShellRoute` với một `TopNavBar` dùng chung duy nhất. Thanh TopNavBar này bắt buộc phải giữ nguyên **đúng 4 thành phần điều hướng thực tế**, đồng thời khoác lên lớp áo thẩm mỹ cao cấp của Stitch:

```html
<header class="top-nav" role="banner">
  <div class="nav-container">
    <!-- 1. Brand Logo & Title -->
    <a href="02_home_screen.html" class="nav-brand" aria-label="Về trang chủ Thi Nhanh">
      <div class="nav-logo">⚡</div>
      <span class="brand-title">Thi Nhanh</span>
    </a>

    <!-- 2. BỐN THÀNH PHẦN ĐIỀU HƯỚNG CHUẨN CỦA APP (GIỮ NGUYÊN 100% LOGIC) -->
    <nav class="nav-links" aria-label="Điều hướng chính">
      <a href="02_home_screen.html" class="nav-link {active-02}">Home</a>
      <a href="03_search_screen.html" class="nav-link {active-03}">Tìm kiếm</a>
      <a href="08_teacher_exams.html" class="nav-link {active-08}">Quản lí đề</a>
      <a href="09_live_dashboard.html" class="nav-link {active-09}">Tạo phòng thi</a>
    </nav>

    <!-- 3. Cụm Hành Động Bên Phải Chuẩn: Ô Nhập Mã PT... + Avatar Người Dùng -->
    <div class="nav-actions">
      <form class="quick-join-group" action="05_taking_exam.html" method="get">
        <input type="text" class="quick-join-input" placeholder="Nhập mã PT..." aria-label="Nhập mã phòng thi">
        <button type="submit" class="quick-join-btn">Vào</button>
      </form>

      <div class="user-profile" title="Tài khoản cá nhân">
        <div class="avatar-circle">M</div>
        <span class="user-display-name">Minh (Lớp 12)</span>
      </div>
    </div>
  </div>
</header>
```

- **Quy tắc hiển thị:** Xuất hiện đồng nhất 100% trên các màn hình chính (`02_home_screen`, `03_search_screen`, `04_exam_detail`, `06_result_screen`, `08_teacher_exams`, `10_student_leaderboard`).
- **Liên kết thật:** Nhấp vào bất kỳ mục nào đều chuyển trang mượt mà giữa các tệp HTML.

---

## 2. Rút Ra Ý Tưởng Thiết Kế Của Stitch vs Giữ Nguyên Logic Thực Tế Trong Từng Màn Hình

| Màn Hình | Ý Tưởng Thiết Kế Kế Thừa Từ Stitch | Logic Nghiệp Vụ Của App Phải Giữ Nguyên 100% |
| :--- | :--- | :--- |
| **01 Đăng Nhập** (`01_auth_greeting.html`) | Bố cục 2 cột: Cột trái tím phát sáng Glowing Book, chip thống kê. Cột phải form thẻ hiện đại bo tròn 18px. | **Đầy đủ 3 luồng đăng nhập:** (1) Email/Mật khẩu; (2) **Đăng nhập Google** (logo Google); (3) **Chế độ Khách** (vào thẳng app). |
| **02 Trang Chủ** (`02_home_screen.html`) | Hero banner chào mừng có nút chuyển workspace, danh mục môn học dạng chip, lưới thẻ đề thi nổi bật. | Giữ nguyên **TopNavBar 4 mục** (Home, Tìm kiếm, Quản lí đề, Tạo phòng thi), **8 môn học chuẩn**, **2 Smart Navigation Cards** ("Bài Đang Làm Dở Dang" & "Phòng Thi Đang Diễn Ra"), Nút Trợ lý AI nổi. |
| **03 Tìm Kiếm** (`03_search_screen.html`) | Thanh tìm kiếm bo góc lớn có biểu tượng kính lúp, bộ lọc chip môn học, thẻ kết quả ngang hiện đại bo góc 16px. | Giữ nguyên **TopNavBar chuẩn có ô nhập mã PT + Avatar**, thanh phân trang **GooglePaginationBar** thực tế của app, hiển thị thời gian tương đối động `formatRelativeTime`. |
| **04 Chi Tiết Đề** (`04_exam_detail.html`) | *(Stitch bỏ sót)* Tự xây dựng theo hệ màu Stitch: Hero banner đề thi Deep Violet, Breadcrumbs hiện đại, hộp thông tin tác giả. | **Giữ nguyên 2 luồng:** (A) Ô nhập mã PIN phòng thi giáo viên yêu cầu; (B) Nút "Tự luyện tập" làm bài offline ngay. Hộp thông tin quy chế giám sát phòng thi. |
| **05 Làm Bài Thi** (`05_taking_exam.html`) | Thanh làm bài thi chuyên dụng với đồng hồ đếm ngược Fira Code hộp màu hồng/đỏ có nhịp đập, thẻ câu hỏi thoáng đãng, lựa chọn A-B-C-D. | **Khắc phục lỗi Stitch:** Sửa lỗi lưới 40 câu hỏi bị nút nộp bài đè lên. Giữ nguyên **banner giám sát toàn màn hình 0/3 lần vi phạm (lần 4 tự động thu bài)**, chống copy câu hỏi. |
| **06 Kết Quả** (`06_result_screen.html`) | Hero Score Card màu Ink Navy `#24233A` sang trọng với điểm số cỡ lớn `8.50/10`, 4 thẻ phân tích kết quả bài thi. | Giữ nguyên **TopNavBar 4 mục chuẩn ở trên**, nút "Luyện tập lại câu sai", chi tiết lời giải từng câu đối chiếu đáp án chọn và đáp án đúng. |
| **07 Soạn Đề** (`07_create_exam.html`) | Giao diện 3 cột: Cây câu hỏi bên trái, Visual Math Editor ở giữa với thanh công cụ toán học nhanh, cấu hình đề bên phải. | **Khắc phục lỗi Stitch:** Không cắt cụt tiêu đề trên TopBar; **khôi phục toàn bộ các công tắc bảo mật ở cột phải** (Trộn câu hỏi, Trộn đáp án, Giám sát chống gian lận) mà Stitch đã tự ý xóa bỏ! |
| **08 Quản Lý Đề** (`08_teacher_exams.html`) | 4 thẻ thống kê kho đề thi, 3 tabs trạng thái (Tất cả, Đã xuất bản, Bản nháp), thẻ đề thi có nút hành động màu gradient. | Giữ nguyên **TopNavBar 4 mục chuẩn** (bỏ nút trùng lặp `+ Tạo đề mới` trên navbar), khôi phục ô tìm kiếm & lọc môn ở thanh tab, các hành động: Mở phòng thi, Sửa đề, Xem chi tiết, Xóa đề. |
| **09 Giám Sát** (`09_live_dashboard.html`) | *(Stitch bỏ sót)* Tự xây dựng theo ngôn ngữ Stitch: Badge chấm xanh trực tiếp `pulse-dot`, 4 thẻ metric thời gian thực, bảng học sinh trực tuyến. | Giữ nguyên **mã PIN phòng thi `PTxxxxxx`**, theo dõi tiến độ câu hỏi thực tế X/Y (từ `questions` và `attempt_answers`), **cờ vi phạm rời tab 🚩**, nút thu bài cưỡng chế ⛔. |
| **10 Bảng Vàng** (`10_student_leaderboard.html`) | Bục Top 1-2-3 Podium với hiệu ứng vương miện và màu Vàng/Bạc/Đồng, bảng điểm xếp hạng. | Giữ nguyên **TopNavBar 4 mục chuẩn ở trên**, nhãn `(Khách)` phân biệt thí sinh vãng lai và học sinh chính thức, thanh ghim vị trí của người dùng ở đáy màn hình. |

---

## 3. Kiến Trúc Thư Mục & Kế Hoạch Xuất Bản Hoàn Thiện (`stitch_design_redesign/`)

Toàn bộ 11 tệp HTML sẽ được xây dựng mới hoàn toàn, đồng bộ 100% trong thư mục `stitch_design_redesign/`:

```
stitch_design_redesign/
├── index.html                   # Showcase Hub: Giới thiệu toàn bộ 10 màn hình, hướng dẫn và link tương tác
├── 01_auth_greeting.html        # Đầy đủ Email + Mật khẩu + Google Login + Chế độ Khách
├── 02_home_screen.html          # TopNav 4 mục (Home, Tìm kiếm, Quản lí đề, Tạo phòng thi) + Smart Cards
├── 03_search_screen.html        # TopNav 4 mục + Google Pagination + 8 môn học
├── 04_exam_detail.html          # Dựng mới chuẩn Stitch: TopNav 4 mục + Nhập mã PIN + Tự luyện
├── 05_taking_exam.html          # Top Exam Bar + Sửa lỗi overlap bảng câu hỏi + Chống gian lận 0/3
├── 06_result_screen.html        # TopNav 4 mục + Thang điểm 10 + Thống kê 4 thẻ + Lời giải
├── 07_create_exam.html          # Visual Math Editor + Khôi phục toàn bộ công tắc bảo mật ở cột phải
├── 08_teacher_exams.html        # TopNav 4 mục + Bỏ nút trùng lặp + Khôi phục tìm kiếm kho đề
├── 09_live_dashboard.html       # Dựng mới chuẩn Stitch: Mã PIN PTxxxxxx + Cờ vi phạm 🚩 + Thu bài ⛔
└── 10_student_leaderboard.html  # TopNav 4 mục + Bục Top 1-2-3 + Sticky rank bar ở đáy
```

---

## 4. Lộ Trình Triển Khai 2 Giai Đoạn

1. **Giai Đoạn 1: Xuất bản trọn vẹn bộ HTML `stitch_design_redesign/` (Deliverable ngay):**
   - Viết toàn bộ 11 tệp HTML tự chứa CSS (Vanilla CSS + Be Vietnam Pro + Fira Code).
   - Kiểm tra liên kết click chuyển trang giữa tất cả các màn hình (100% working links).
   - Người dùng trực tiếp mở trên trình duyệt kiểm tra và nghiệm thu.
2. **Giai Đoạn 2: Lập Kế Hoạch TDD & Đồng Bộ Sang Mã Nguồn Flutter (`lib/`):**
   - Viết Implementation Plan chi tiết theo quy trình `writing-plans`.
   - Cập nhật Design System trong `lib/core/theme/app_theme.dart`.
   - Cập nhật `lib/shared/widgets/top_nav_bar.dart` theo mẫu TopNavBar chuẩn đã thống nhất.
   - Nâng cấp giao diện từng màn hình tương ứng.
   - Chạy kiểm thử hồi quy xác nhận 173/173 tests PASS.
   - Git commit và auto-push lên GitHub theo quy định của dự án.
