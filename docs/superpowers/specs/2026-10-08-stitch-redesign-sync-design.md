# Thiết Kế Chi Tiết: Chuẩn Hóa & Hoàn Thiện Toàn Diện Bộ Giao Diện Stitch AI Redesign và Lộ Trình Đồng Bộ Sang Flutter Code

> **Ngày tạo:** 08/10/2026 (Cập nhật sau phiên phỏng vấn chuyên sâu chi tiết /grill-me)  
> **Trạng thái:** Đã thống nhất & Phê duyệt phương án kiến trúc  
> **Tài liệu tham chiếu:** `edtech_assessment_modern/DESIGN.md`, `stitch_web_redesign_html_mockups.zip`, `lib/shared/widgets/top_nav_bar.dart`  

---

## 1. Đánh Giá Chuyên Sâu Các Khiếm Khuyết Trong Bản Của Stitch AI

Qua kiểm tra đối soát từng dòng mã nguồn giữa các thư mục do Stitch AI tạo ra và ứng dụng Flutter thực tế, phát hiện các khuyết tật kỹ thuật nghiêm trọng cần được khắc phục:

### 1.1. Bảng So Sánh Sự Bất Nhất & Phân Mảnh Của Top Navigation Bar

| Màn Hình | Logo & Thương Hiệu | Menu Điều Hướng (Nav Links) | Cụm Hành Động Bên Phải (Nav Actions) | Đánh Giá Khuyết Tật |
| :--- | :--- | :--- | :--- | :--- |
| **01 Chào Mừng** | `<div class="brand-logo">⚡</div> Thi Nhanh` | Không có (Màn Auth) | Không có | ✅ Hợp lý cho màn chào mừng/đăng nhập. |
| **02 Trang Chủ** | `<div class="nav-logo">⚡</div> Thi Nhanh` | **4 mục:** `Trang Chủ`, `Khám Phá Đề`, `Bảng Xếp Hạng`, `Kênh Giáo Viên` | Ô nhập PIN `[Mã phòng PT...]` + Nút `Vào` + Avatar `M` | ⚠️ Menu đầy đủ nhất nhưng tất cả link đều là `href="#"`. |
| **03 Tìm Kiếm** | `<div class="nav-logo">⚡</div> Thi Nhanh` | **4 mục:** như trên | **MẤT TOÀN BỘ:** Không có ô nhập PIN, không có Avatar người dùng | ❌ **Lỗi:** Bị mất sạch cụm hành động bên phải so với Trang Chủ. |
| **04 Chi Tiết Đề** | *(Bị Stitch bỏ sót)* | *(Không được tạo thư mục)* | *(Không được tạo thư mục)* | ❌ **Lỗi nghiêm trọng:** Stitch quên hẳn màn hình này. |
| **05 Làm Bài Thi** | Không có logo thương hiệu | Không có menu (Dạng Full-screen Exam) | Nút Thoát + Đồng hồ đếm ngược + Nút Nộp bài | ⚠️ Hợp lý cho phòng thi nhưng thiếu nhận diện thương hiệu. |
| **06 Kết Quả** | `<div class="nav-logo">⚡</div> Thi Nhanh` | **MẤT SẠCH MENU 4 MỤC:** Thay bằng 2 nút outline `🏆 Bảng Xếp Hạng` và `🏠 Trang Chủ` | Không có avatar hay ô nhập PIN | ❌ **Lỗi:** Bẻ gãy cấu trúc TopNav, người dùng không thể bấm sang màn khác. |
| **07 Soạn Đề** | Không có logo thương hiệu | Thanh công cụ soạn thảo: Nút trở về + Tên đề + Badge Nháp | Nút `💾 Lưu tạm` + Nút `🚀 Xuất bản` | ⚠️ Hợp lý cho màn hình Editor chuyên sâu. |
| **08 Quản Lý Đề** | `<span class="logo-icon">⚡</span> ThiNhanh` *(Viết dính liền)* | **ĐỔI CÒN 3 MỤC:** `Trang Chủ`, `Kho Đề Thi` *(Đổi tên)*, `Kênh Giáo Viên` *(Mất Bảng Xếp Hạng)* | Thay thế ô nhập PIN bằng nút `+ Tạo đề mới`, **không có Avatar** | ❌ **Lỗi nặng:** Tự ý đổi tên menu, xóa bớt mục, đổi cả cách viết tên thương hiệu. |
| **09 Giám Sát** | *(Bị Stitch bỏ sót)* | *(Không được tạo thư mục)* | *(Không được tạo thư mục)* | ❌ **Lỗi nghiêm trọng:** Stitch quên hẳn màn hình Realtime này. |
| **10 Bảng Vàng** | `<span class="logo-icon">⚡</span> ThiNhanh` *(Viết dính liền)* | **MẤT TOÀN BỘ MENU:** Chỉ còn 1 dòng text `🏠 Về Trang Chủ` | **Không có gì** | ❌ **Lỗi:** Giao diện bị cô lập, không chuyển trang được. |

### 1.2. Các Lỗi Kỹ Thuật Khác Của Stitch AI
1. **Liên kết chết (`href="#"`):** Toàn bộ các thẻ `<a>` ở menu điều hướng đều không có đường dẫn thực tế, người dùng nhấp chuột chỉ bị giật màn hình lên đầu trang.
2. **Xung đột kiến trúc Flutter `ShellRoute`:** Trong Flutter (`lib/shared/widgets/top_nav_bar.dart` và `lib/main.dart`), toàn bộ các trang chính được bọc trong một `TopNavBar` dùng chung. Nếu HTML bị phân mảnh 5 kiểu, khi chuyển sang Flutter sẽ phá vỡ tính kế thừa và tái sử dụng component.
3. **Bỏ quên 2 màn hình quan trọng:** Màn hình 04 (Chi tiết đề & Nhập PIN phòng) và 09 (Giám sát phòng thi realtime của giáo viên) bị Stitch AI bỏ quên hoàn toàn.
4. **Lỗi đặt tên thư mục & Font tiếng Việt:** Tên thư mục bị băm mất dấu tiếng Việt (`01_m_n_h_nh_...`, `07_so_n_th_o_...`).

---

## 2. Chuẩn Hóa Kiến Trúc Giao Diện: Phương Án A (Global ShellRoute)

Hệ thống sẽ được chuẩn hóa thành **2 hệ thống Header duy nhất và nhất quán 100%**:

### 2.1. Hệ Thống 1: Global App TopNavBar (Áp dụng cho 02, 03, 04, 06, 08, 10)
Tất cả 6 màn hình chính đều sử dụng chung một cấu trúc TopNav duy nhất, đồng bộ tuyệt đối về HTML markup và CSS styling:

```html
<header class="top-nav" role="banner">
  <div class="nav-container">
    <!-- Brand Logo & Title -->
    <a href="02_home_screen.html" class="nav-brand" aria-label="Về trang chủ Thi Nhanh">
      <div class="nav-logo">⚡</div>
      <span class="brand-title">Thi Nhanh</span>
    </a>

    <!-- Unified 4 Menu Links with Working Relative URLs -->
    <nav class="nav-links" aria-label="Điều hướng chính">
      <a href="02_home_screen.html" class="nav-link {active-if-02}">Trang Chủ</a>
      <a href="03_search_screen.html" class="nav-link {active-if-03}">Khám Phá Đề</a>
      <a href="08_teacher_exams.html" class="nav-link {active-if-08}">Kênh Giáo Viên</a>
      <a href="10_student_leaderboard.html" class="nav-link {active-if-10}">Bảng Xếp Hạng</a>
    </nav>

    <!-- Unified Right Actions: Quick Join Room PIN + User Profile -->
    <div class="nav-actions">
      <form class="quick-join-group" action="05_taking_exam.html" method="get">
        <input type="text" class="quick-join-input" placeholder="Mã phòng PT..." aria-label="Nhập mã phòng thi">
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

- **Màu sắc & Active State:** Mục menu của trang hiện tại có class `.active` mang màu tím Primary `#6557E8`, nền nhẹ Lavender `#EEECFF` và font-weight 700.
- **Liên kết thực tế:** Nhấp vào bất kỳ link nào trên TopNav đều chuyển ngay lập tức sang trang đích tương ứng trong bộ HTML.

### 2.2. Hệ Thống 2: Focused Workspace Headers (Dành riêng cho 3 màn hình chuyên biệt)
Các màn hình này không nằm trong ShellRoute thông thường mà đòi hỏi không gian tập trung cao độ:
1. **`01_auth_greeting.html`:** Không có TopNav (Màn chào mừng đăng nhập, thiết kế Hero Banner & Form đăng nhập).
2. **`05_taking_exam.html`:** Top Exam Bar chuyên dụng:
   - Nút Thoát (có xác nhận) $\rightarrow$ Về `04_exam_detail.html`.
   - Tiêu đề đề thi & Mã đề.
   - Đồng hồ đếm ngược thời gian thực `42:15` font Fira Code với hiệu ứng đập nhịp (pulsating).
   - Nút Nộp bài thi nổi bật màu tím $\rightarrow$ Chuyển sang `06_result_screen.html`.
   - Banner cảnh báo chống gian lận & giám sát toàn màn hình.
3. **`07_create_exam.html`:** Top Editor Bar chuyên dụng:
   - Nút Trở về `← Quản lý đề` $\rightarrow$ Về `08_teacher_exams.html`.
   - Ô nhập tiêu đề đề thi trực tiếp.
   - Badge trạng thái `Bản nháp / Đã xuất bản`.
   - Nút `💾 Lưu tạm` và nút `🚀 Xuất bản đề thi`.
4. **`09_live_dashboard.html`:** Top Proctoring Bar chuyên dụng:
   - Nút `← Thoát phòng` $\rightarrow$ Về `08_teacher_exams.html`.
   - Trạng thái chấm xanh phát sáng `🔴 Trực tiếp`.
   - Tiêu đề phòng thi và Mã PIN phòng cỡ lớn kèm nút bấm 1-chạm sao chép.
   - Timer đếm ngược thời gian thi phòng.
   - Nút `⛔ Thu bài toàn phòng`.

---

## 3. Cấu Trúc Bộ Thư Mục Hoàn Thiện Chuẩn Mực (`stitch_design_redesign/`)

Toàn bộ 11 tệp HTML sẽ được đặt trong thư mục chuẩn `stitch_design_redesign/` (tên thư mục chuẩn tiếng Anh/không dấu, không bị băm ký tự):

```
stitch_design_redesign/
├── index.html                   # Showcase Hub điều hướng trung tâm, liên kết toàn bộ 10 màn
├── 01_auth_greeting.html        # Chào mừng & Đăng nhập (Hero Glowing Book, Google, Guest)
├── 02_home_screen.html          # Trang chủ học tập (TopNav chuẩn, Smart Nav Cards, 8 môn học)
├── 03_search_screen.html        # Tìm kiếm đề thi (TopNav chuẩn, Bộ lọc môn, Google Pagination)
├── 04_exam_detail.html          # Chi tiết đề thi (MỚI: Chuẩn hóa theo Stitch, TopNav chuẩn, Nhập PIN)
├── 05_taking_exam.html          # Phòng thi trực tuyến (Focused Exam Bar, LaTeX, Lưới 40 câu)
├── 06_result_screen.html        # Kết quả thi (TopNav chuẩn, Thang điểm 10, Lời giải chi tiết)
├── 07_create_exam.html          # Soạn đề thi (Focused Editor Bar, Visual Math, 3 cột)
├── 08_teacher_exams.html        # Quản lý kho đề (TopNav chuẩn, 4 stats cards, 3 tabs lọc)
├── 09_live_dashboard.html       # Giám sát trực tiếp (MỚI: Chuẩn hóa theo Stitch, Realtime metrics, Cờ vi phạm)
└── 10_student_leaderboard.html  # Bảng vàng vinh danh (TopNav chuẩn, Bục Top 1-2-3 Podium)
```

---

## 4. Lộ Trình Thực Hiện & Tiêu Chí Nghiệm Thu (Implementation & Acceptance)

### Giai Đoạn 1: Xuất Bản & Nghiệm Thu Trọn Vẹn Bộ HTML Redesign
1. Tạo thư mục `stitch_design_redesign/` với đầy đủ 11 file HTML.
2. Áp dụng chuẩn **Global App TopNavBar** đồng nhất cho cả 6 màn hình (`02`, `03`, `04`, `06`, `08`, `10`).
3. Hoàn thiện xuất sắc 2 màn hình 04 & 09 theo phong cách Stitch cao cấp.
4. Đảm bảo toàn bộ menu và nút bấm đều có liên kết qua lại hoạt động mượt mà (không có link chết `href="#"`).
5. Người dùng nghiệm thu trực quan bộ giao diện trên trình duyệt.

### Giai Đoạn 2: Lập Kế Hoạch TDD & Đồng Bộ Sang Mã Nguồn Flutter (`lib/`)
1. Viết Implementation Plan chi tiết theo kỹ năng `writing-plans`.
2. Đồng bộ Design System Tokens vào `lib/core/theme/app_theme.dart`.
3. Chuẩn hóa `lib/shared/widgets/top_nav_bar.dart` theo mẫu TopNavBar chuẩn đã thống nhất.
4. Cập nhật lần lượt các màn hình Flutter tương ứng.
5. Chạy kiểm thử tự động xác nhận 173/173 tests PASS.
6. Git commit và auto-push lên GitHub theo quy định của dự án.
