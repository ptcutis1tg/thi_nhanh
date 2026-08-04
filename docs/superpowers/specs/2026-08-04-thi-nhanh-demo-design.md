# BẢN THIẾT KẾ CHI TIẾT UI/UX VÀ LUỒNG NGƯỜI DÙNG (MVP VERSION)
## ỨNG DỤNG THI NHANH (FLUTTER WEB & MOBILE)

---

## 1. PHÂN QUYỀN VÀ LUỒNG NGƯỜI DÙNG CHUYÊN SÂU (USER ROLES & FLOWS)

Hệ thống phân chia rõ ràng 3 nhóm người dùng để tối ưu hóa trải nghiệm:

### 1.1 Giáo viên đã có tài khoản (Teacher)
* **Quyền hạn cốt lõi**: Quản trị, tổ chức kỳ thi và giám sát.
* **Luồng trải nghiệm**:
  * Đăng nhập thành công -> Trang Home.
  * Có nút **"Tạo đề thi"** trên thanh điều hướng. Mở trình tạo câu hỏi thủ công (nhập từng câu).
  * Được quyền thiết lập phòng thi: Thời gian làm bài, **Cài đặt cho phép thí sinh xem Realtime Leaderboard hay không**.
  * Khi bấm "Mở phòng", Giáo viên lập tức được chuyển hướng tới **Live Dashboard (Màn hình Giám sát)** để xem trực tiếp học sinh nào đang làm, đúng/sai bao nhiêu câu, thứ hạng thay đổi realtime.
  * **Trang Profile**: Sở hữu tab "Quản lý đề đã tạo", có thể lấy lại mã phòng cũ, xuất danh sách điểm (Export kết quả) hoặc xem tổng quan chất lượng bài thi của học sinh.

### 1.2 Học sinh đã có tài khoản (Student)
* **Quyền hạn cốt lõi**: Làm bài thi, thi đua xếp hạng, lưu trữ lịch sử học tập.
* **Luồng trải nghiệm**:
  * Đăng nhập thành công -> Trang Home (thấy các đề "Hot", đề vừa làm "Recent", và gợi ý Chủ đề).
  * Vào phòng thi thông qua việc click thẻ đề ở Home HOẶC nhập mã phòng (được GV cung cấp) vào ô nhập mã trên thanh điều hướng.
  * **Trải nghiệm làm bài**: Có đồng hồ bấm giờ, giao diện chọn đáp án. Tùy thuộc vào cài đặt của Giáo viên mà Học sinh có thấy bảng xếp hạng realtime bên góc màn hình hay không.
  * Khi nộp bài -> Xem thứ hạng chung cuộc, vòng tròn tổng kết điểm.
  * **Trang Profile**: Có tab "Lịch sử làm bài", hiển thị toàn bộ đề đã làm, số điểm đạt được để học sinh tự đánh giá tiến độ bản thân. Không có tính năng "Tạo đề thi".

### 1.3 Guest (Người dùng chưa đăng nhập)
* **Quyền hạn cốt lõi**: Thi nhanh không cần tài khoản, tính năng bị giới hạn.
* **Luồng trải nghiệm**:
  * Mở app lần đầu -> Bắt buộc thấy **Greeting Screen** (Màn hình chào mừng). Bên trái là giới thiệu, bên phải là form đăng nhập.
  * Guest có thể bỏ qua đăng nhập để tiếp tục. 
  * Thanh điều hướng hiển thị nút "Đăng nhập" thay cho Avatar. Không có nút "Tạo đề thi".
  * **Vào phòng thi**: Có thể nhập mã phòng để thi trực tiếp. Trước khi vào phòng sẽ bị yêu cầu "Nhập tên hiển thị tạm thời".
  * Lịch sử làm bài của Guest sẽ bị **xóa (hoặc mất đi)** sau khi đóng trình duyệt. App sẽ liên tục gợi ý "Đăng nhập để lưu lại kết quả này".

---

## 2. THIẾT KẾ CHI TIẾT TỪNG COMPONENT (VỊ TRÍ & KÍCH THƯỚC)

*Hệ màu sử dụng (Design Tokens):*
* Nền chính (Background): `#f8f8fc` (Paper)
* Màu thương hiệu (Primary): `#6557e8` (Violet)
* Màu chữ chính (Ink): `#24233a`
* Màu chữ phụ (Muted): `#74748b`
* Màu viền (Border): `#e7e6ef`

### 2.1 Thanh Điều Hướng Đỉnh (Top Navigation Bar)
* **Vị trí**: Nằm cố định ở sát mép trên màn hình (`top: 0`, `left: 0`, `right: 0`), `z-index: 50`.
* **Kích thước**: Chiều cao (Height) `72px` trên Desktop, `64px` trên Mobile. Padding ngang `32px`.
* **Thiết kế Component**:
  * `Nền`: Trắng (`#ffffff`).
  * `Đổ bóng (Shadow)`: `0 2px 10px rgba(0,0,0,0.05)` giúp tách biệt với nền trang.
  * **Cụm Trái (Logo)**: Icon vuông 32x32px (nền `#6557e8`, dấu check trắng) + Text "Thi Nhanh" (Font 20px, ExtraBold).
  * **Cụm Giữa (Menu)**:
    * Các nút Text (Home, Tìm kiếm, Tạo đề thi).
    * `Khoảng cách (Gap)`: 24px.
    * `Trạng thái`: Chữ mặc định 16px màu `#74748b`. Khi hover có nền xám nhạt `border-radius: 8px`. Khi Active chữ màu `#6557e8` và có gạch chân 2px.
  * **Cụm Phải (Hành động & Avatar)**:
    * `Container Nhập Mã Phòng`: Hình chữ nhật bo góc tròn (`border-radius: 20px`), Width `180px`, Height `40px`, nền `#f8f8fc`, viền 1px `#e7e6ef`. Bên trong có placeholder "Nhập mã phòng..." (14px) và icon mũi tên (submit) ở góc phải.
    * `Avatar`: Hình tròn `Width/Height 42px`, `border-radius: 50%`, nằm cách ô nhập mã 16px. Bấm vào ra menu Dropdown (Profile, Logout).

### 2.2 Màn hình Chào mừng (Greeting Screen)
* **Vị trí**: Hiển thị đầu tiên khi user chưa có phiên đăng nhập (Guest session).
* **Thiết kế Component**: Bố cục chia đôi màn hình (50-50 trên Desktop, trượt dọc trên Mobile).
  * **Nửa trái (Giới thiệu)**: Nền gradient tím nhạt. Căn giữa hình ảnh minh họa (Illustration lớn) + Title "Ôn thi thần tốc, xếp hạng thời gian thực" (Font 48px, Bold, màu `#24233a`).
  * **Nửa phải (Login Form)**: Nền trắng, căn giữa dọc. Thẻ Card form rộng `400px`. Các nút "Tiếp tục với Google" (Outline button, height `48px`, viền `#e7e6ef`, icon Google bên trái) và ô nhập Email/Mật khẩu truyền thống. Có nút "Bỏ qua & thi ngay (Guest)".

### 3.3 Màn hình Trang chủ (Home Screen)
* **Vị trí**: Nằm ngay dưới Navbar. `max-width: 1200px`, căn giữa màn hình (margin auto).
* **Thiết kế Component**:
  * **Recent (Đề đã làm gần nhất)**: 
    * `Layout`: Dạng cuộn ngang (Horizontal ListView).
    * `Card Đề Thi`: Hình chữ nhật Width `280px`, Height `160px`, `border-radius: 16px`, nền trắng, shadow `0 8px 24px rgba(0,0,0,0.06)`. Nửa trên ghi "Tên đề thi" (18px, Bold, max 2 dòng), nửa dưới hiển thị điểm số vừa đạt (Text to màu `#6557e8`) và thời gian làm (vd: "2 ngày trước").
  * **Đề Hot**: 
    * `Layout`: CSS Grid (3 cột trên Desktop, 1 cột trên Mobile).
    * `Card Đề Hot`: Padding `20px`. Phía trên cùng có một Badge nhỏ nền đỏ chữ trắng "🔥 HOT". Thông tin gồm: Tên đề, Số lượng câu, Tên tác giả (kèm avatar nhỏ).
  * **Gợi ý Chủ đề (Topic Chips)**:
    * Nằm ở vị trí đầu trang (dưới banner). Dạng danh sách các viên nhộng (Pill). `Height 36px`, padding ngang `16px`, bo tròn `18px`. Màu nền `#eeecff`, chữ màu `#6557e8` font 14px. Bấm vào sẽ trigger thanh Search trên Navbar.

### 3.4 Màn hình Tạo Đề Thi (Dành cho Giáo viên)
* **Vị trí**: Chiếm toàn bộ không gian làm việc. Bố cục Split (Sidebar trái 25% + Main phải 75%).
* **Thiết kế Component**:
  * **Sidebar (Danh sách câu hỏi)**: Nền trắng, viền phải `#e7e6ef`. Các hàng câu hỏi (Câu 1, Câu 2...). Trạng thái Active: Nền `#eeecff` đổ tràn lề. Dưới cùng có nút "+ Thêm câu hỏi" dạng ngắt quãng (Dashed border, chữ tím).
  * **Main (Chỉnh sửa câu hỏi)**:
    * Vùng trống padding `40px`.
    * `Khung TextArea câu hỏi`: Width `100%`, Min-height `120px`, viền 1px `#e7e6ef`, bo góc `12px`. Text size `16px`.
    * `Các ô đáp án (Options)`: Mỗi đáp án là 1 row `Height 56px`, `margin-bottom 12px`, bo góc `10px`. Radio button đầu dòng size `20x20px` màu `#6557e8`. Input text điền đáp án không viền.
  * **Cài đặt phòng (Góc phải trên)**: Toggle Switch (Nút gạt) "Hiển thị xếp hạng cho học sinh", kích thước switch 48x24px, on màu `#6557e8`, off xám.
  * **Nút "Mở phòng"**: Nằm ở góc phải dưới (FAB hoặc cố định bottom). Kích thước to, Height `52px`, `border-radius: 12px`, Shadow màu tím.

### 3.5 Màn hình Giám sát Phòng thi (Live Dashboard)
* **Vị trí**: Chỉ xuất hiện sau khi Giáo viên bấm "Mở phòng".
* **Thiết kế Component**:
  * **Hero Header**: Nền tối `#24233a`, chứa Mã Phòng siêu to (Font 64px, chữ trắng) ở chính giữa để giáo viên chiếu lên bảng. Text phụ: "Sử dụng app Thi Nhanh hoặc nhập mã này để vào thi".
  * **Danh sách Học sinh (Live Table)**:
    * Nằm dưới Header. Giao diện dạng danh sách hàng dọc.
    * Mỗi Row cao `64px`, viền dưới `#e7e6ef`.
    * Hiển thị: Hạng 1, 2, 3... (Font to, màu nổi cho top 3). Tên học sinh, Điểm/Tổng điểm. 
    * **Thanh Tiến độ (Progress Bar)**: Một thanh ngang dài (vd: Width `200px`, Height `10px`, bo góc). Tỷ lệ màu Xanh (`#27885e` - đúng), Cam (`#c87909` - sai), Xám (chưa làm).
  * **Nút Đóng Phòng**: Outline button viền đỏ, chữ đỏ ở góc màn hình.

### 3.6 Màn hình Làm bài & Xem Xếp hạng
* **Vị trí**: Màn hình làm bài của học sinh (như Demo HTML gốc).
* **Thiết kế Component Bổ sung**:
  * **Panel Realtime Leaderboard (Nằm trong lúc thi)**: 
    * Dành riêng cho học sinh khi được GV cấp quyền. Nằm lơ lửng góc phải dưới (hoặc thu nhỏ trong một tab Sidebar). 
    * Box nhỏ width `220px`. Hiển thị Top 3 người dẫn đầu (Chỉ tên & Điểm). 
    * `Hiệu ứng`: Nhấp nháy nhẹ màu xanh khi bảng xếp hạng có sự đổi ngôi.

### 3.7 Màn hình Profile
* **Vị trí**: Chuyển đến khi bấm Avatar. Căn giữa `max-width 1000px`.
* **Thiết kế Component**:
  * **Khung Info Đầu trang**: Hình Avatar to (80x80px), Tên người dùng (24px), Nút "Sửa hồ sơ".
  * **Tab View**: 2 Tabs ngang "Lịch sử thi" và "Đề đã tạo" (chỉ hiện nếu là Giáo viên). 
  * **Lịch sử thi (History Tab)**: List các thẻ dọc (Vertical Cards). Mỗi thẻ hiện: Tên đề, Ngày thi, Tổng điểm (vòng tròn điểm mini), Xếp hạng đạt được trong phòng hôm đó.
  * **Quản lý đề (My Exams Tab)**: Các thẻ đề thi của mình tạo. Kèm theo nút "Mở lại phòng" (màu tím) và "Xuất Excel Kết quả" (màu xám nhạt).
