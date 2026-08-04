# BẢN THIẾT KẾ CHI TIẾT UI/UX VÀ LUỒNG NGƯỜI DÙNG (MVP VERSION)
## ỨNG DỤNG THI NHANH (FLUTTER WEB & MOBILE)

---

## 1. CƠ CHẾ CỐT LÕI: ĐỀ THI VÀ PHÒNG THI ĐỘC LẬP

Hệ thống được thiết kế với 2 thực thể hoàn toàn riêng biệt để phục vụ đa dạng mục đích ôn luyện và thi đấu:

### 1.1 Đề thi (Exam - Mã `DTxxxxxx`)
* **Tính chất**: Bất đồng bộ (Asynchronous), làm bài cá nhân.
* **Mô tả**: Giáo viên (hoặc người dùng có quyền) tạo ra bộ câu hỏi, hệ thống sẽ cấp một mã định dạng `DTxxxxxx`.
* **Luồng làm bài**: Học sinh có thể lấy mã `DT` này nhập vào app để tự luyện tập, làm bài cá nhân vào bất cứ lúc nào. 

### 1.2 Phòng thi (Room - Mã `PTxxxxxx`)
* **Tính chất**: Đồng bộ (Synchronous), thi đấu trực tiếp.
* **Mô tả**: Giáo viên tạo một Phòng thi và **gắn mã Đề thi (`DTxxxxxx`)** vào phòng đó. Hệ thống sẽ sinh ra mã phòng định dạng `PTxxxxxx`.
* **Luồng làm bài**: 
  1. Học sinh nhập mã `PTxxxxxx` để vào phòng.
  2. Học sinh sẽ ở trạng thái **Phòng chờ (Waiting Room)**.
  3. Tất cả phải đợi đến khi Giáo viên bấm nút **"Bắt đầu"**, lúc này bài thi mới đồng loạt mở ra cho tất cả học sinh trong phòng.

---

## 2. PHÂN QUYỀN VÀ LUỒNG NGƯỜI DÙNG CHUYÊN SÂU (USER ROLES & FLOWS)

### 2.1 Giáo viên đã có tài khoản (Teacher)
* **Quyền hạn cốt lõi**: Tạo đề thi, tạo phòng thi, quản trị, tổ chức kỳ thi và giám sát.
* **Luồng trải nghiệm**:
  * **Tạo Đề**: Vào "Tạo đề thi" -> Tạo câu hỏi -> Lưu đề thi -> Nhận mã `DTxxxxxx`.
  * **Tạo Phòng**: Bấm "Tạo phòng thi" -> Điền mã `DTxxxxxx` và cấu hình phòng -> Nhận mã phòng `PTxxxxxx`.
  * **Tổ chức thi**: Chuyển đến **Phòng chờ (Waiting Room)**, theo dõi danh sách học sinh đang join vào. Khi đã đủ người, bấm **"Bắt đầu làm bài"**.
  * Sau khi bấm Bắt đầu, Giáo viên lập tức được chuyển hướng tới **Live Dashboard (Màn hình Giám sát)** để xem trực tiếp tiến độ của học sinh.
  * **Trang Profile**: Sở hữu tab "Đề đã tạo" và "Phòng đã mở" để quản lý.

### 2.2 Học sinh đã có tài khoản (Student)
* **Quyền hạn cốt lõi**: Làm bài thi, thi đua xếp hạng, lưu trữ lịch sử học tập.
* **Luồng trải nghiệm**:
  * **Thi cá nhân**: Nhập mã `DTxxxxxx` -> Xem chi tiết đề -> Bấm Bắt đầu -> Làm bài đếm ngược -> Xem kết quả cá nhân.
  * **Thi phòng đồng bộ**: Nhập mã `PTxxxxxx` -> Được đưa vào **Phòng chờ** -> Chờ đợi Giáo viên -> Khi màn hình tự động chuyển sang làm bài, đồng hồ bắt đầu chạy. 
  * **Trang Profile**: Có tab "Lịch sử làm bài", hiển thị toàn bộ đề/phòng đã làm.

### 2.3 Guest (Người dùng chưa đăng nhập)
* **Quyền hạn cốt lõi**: Thi nhanh không cần tài khoản, tính năng bị giới hạn.
* **Luồng trải nghiệm**:
  * Mở app lần đầu -> Bắt buộc thấy **Greeting Screen** (Màn hình chào mừng). 
  * Thanh điều hướng hiển thị nút "Đăng nhập" thay cho Avatar.
  * Có thể nhập mã `DT` hoặc `PT` để thi trực tiếp. Trước khi thi sẽ bị yêu cầu "Nhập tên hiển thị tạm thời".
  * Lịch sử làm bài của Guest sẽ bị mất sau khi thoát trình duyệt.

---

## 3. THIẾT KẾ CHI TIẾT TỪNG COMPONENT (VỊ TRÍ & KÍCH THƯỚC)

*Hệ màu sử dụng (Design Tokens):*
* Nền chính (Background): `#f8f8fc` (Paper)
* Màu thương hiệu (Primary): `#6557e8` (Violet)
* Màu chữ chính (Ink): `#24233a`
* Màu chữ phụ (Muted): `#74748b`
* Màu viền (Border): `#e7e6ef`

### 3.1 Thanh Điều Hướng Đỉnh (Top Navigation Bar)
* **Vị trí**: Cố định ở mép trên màn hình (`top: 0`, `left: 0`, `right: 0`), Height `72px` (Desktop).
* **Cụm Giữa (Menu)**:
  * Text Buttons: Home, Tìm kiếm, Tạo đề thi, Tạo phòng thi.
* **Cụm Phải (Hành động & Avatar)**:
  * `Container Nhập Mã`: Hình chữ nhật bo góc tròn, Width `180px`, Height `40px`, nền `#f8f8fc`, viền 1px `#e7e6ef`. Placeholder "Nhập mã PT... hoặc DT..." (Hệ thống tự động điều hướng dựa trên tiền tố).

### 3.2 Màn hình Chào mừng (Greeting Screen)
* **Nửa trái (Giới thiệu)**: Nền gradient tím nhạt, Illustration lớn.
* **Nửa phải (Login Form)**: Form Đăng nhập Google/Email và nút "Thi ngay với mã phòng (Guest)".

### 3.3 Màn hình Trang chủ (Home Screen)
* **Hero Banner**: Chiều cao `200px`, gradient nền tím, Title chào mừng.
* **Recent & Đề Hot**: Các Card Đề Thi Width `280px`, Height `160px`, `border-radius: 16px`, shadow `0 8px 24px rgba(0,0,0,0.06)`. Hiển thị nhãn Badge phân biệt "Đề cá nhân" hoặc "Phòng đang mở".

### 3.4 Màn hình Tạo Đề Thi (Dành cho Giáo viên)
* **Main (Chỉnh sửa câu hỏi)**: Form tạo câu hỏi không có cấu hình phòng thi ở đây.
* **Nút Action**: Dưới cùng bấm "Lưu & Khởi tạo Đề". Pop-up hiện ra thông báo mã **DTxxxxxx** để chia sẻ.

### 3.5 Màn hình Tạo Phòng Thi
* **Vị trí**: Click từ "Tạo phòng thi" trên Navbar.
* **Form Cấu hình**:
  * Input "Nhập mã đề thi gốc (DTxxxxxx)": Để copy nội dung từ đề đã tạo vào phòng.
  * Input "Tên phòng thi": Mặc định lấy tên của đề thi nhưng có thể đổi.
  * Toggle Switch "Hiện Realtime Leaderboard cho học sinh".
  * Nút "Mở Phòng Thi". Cấp ngay mã **PTxxxxxx** và chuyển sang Màn hình Phòng Chờ.

### 3.6 Màn hình Phòng Chờ (Waiting Room)
* **Dành cho Học sinh**: 
  * Căn giữa màn hình là hình ảnh loading, Text: "Vui lòng chờ giáo viên bắt đầu...". 
  * Danh sách nhỏ hiển thị những ai đang ở trong phòng cùng mình.
* **Dành cho Giáo viên**:
  * Mã phòng **PTxxxxxx** to chính giữa.
  * Bảng danh sách thí sinh đã join (Có đếm tổng số lượng). Có nút "Đuổi/Kick" bên cạnh tên.
  * Nút Primary siêu to: **"Bắt đầu làm bài"** (Bấm phát đồng loạt chuyển màn hình cho tất cả).

### 3.7 Màn hình Giám sát Phòng thi (Live Dashboard)
* **Vị trí**: Chỉ xuất hiện cho Giáo viên sau khi bấm "Bắt đầu làm bài".
* **Danh sách Học sinh (Live Table)**:
  * Mỗi Row cao `64px`, viền dưới `#e7e6ef`.
  * **Thanh Tiến độ (Progress Bar)**: Thanh ngang dài. Tỷ lệ màu Xanh (`#27885e` - đúng), Cam (`#c87909` - sai). Thay đổi realtime.
* **Nút Đóng Phòng**: Thu bài sớm tất cả thí sinh.

### 3.8 Màn hình Làm bài & Kết quả
* **Trong khi làm bài**: Học sinh thấy Timer đếm ngược. Trạng thái realtime ranking hiển thị góc phải nếu được cấp quyền.
* **Sau khi nộp bài (Cá nhân hoặc Phòng)**: Màn hình Summary (Vòng tròn điểm), tóm tắt số câu đúng/sai. Nếu là thi phòng (`PT`) thì thấy thứ hạng của mình.

### 3.9 Màn hình Profile
* **Tab View**: "Lịch sử thi", "Đề đã tạo (DT)", "Phòng đã mở (PT)". Giúp tách bạch rõ ràng luồng quản lý nội dung và luồng tổ chức thi đấu.
