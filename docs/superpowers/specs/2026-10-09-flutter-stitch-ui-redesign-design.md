# Bản Thiết Kế Kiến Trúc: Hiện Đại Hóa Giao Diện Flutter Trực Tiếp Từ Ý Tưởng Stitch AI (EdTech Assessment Modern)

- **Ngày ban hành:** 2026-10-09
- **Phiên bản:** 1.0.0
- **Trạng thái:** Đã phê duyệt (Approved)
- **Mục tiêu:** Nâng cấp toàn diện giao diện ứng dụng Flutter (`lib/`) đạt chuẩn thẩm mỹ cao cấp của bộ thiết kế Stitch AI (EdTech Assessment Modern), áp dụng đầy đủ bố cục (layout) và hiệu ứng thị giác hiện đại, đồng thời **bảo toàn tuyệt đối 100% logic nghiệp vụ cốt lõi, bảo vệ quyền hạn, cấu trúc điều hướng 4 mục và tỷ lệ kiểm thử 173/173 tests PASS**.

---

## 1. Bối Cảnh & Nguyên Tắc Cốt Lõi

### 1.1. Quyết định kiến trúc
* **Không duy trì mã HTML mockup:** Bỏ qua hoàn toàn việc tạo hay chỉnh sửa các file HTML tĩnh; áp dụng trực tiếp các ý tưởng thẩm mỹ, bảng màu, bố cục thẻ và typography từ Stitch AI vào mã nguồn Flutter (`lib/`).
* **Bảo toàn 100% logic nghiệp vụ:** Mọi luồng xử lý dữ liệu qua `Provider`, `Repository`, Supabase RPC, Realtime presence, Local storage (SharedPreferences) và cơ chế chống gian lận (Anti-cheat proctoring) phải hoạt động chính xác nguyên bản.
* **Không làm gãy bộ kiểm thử:** 173 test case hiện tại trong thư mục `test/` phải tiếp tục vượt qua 100% (`flutter test`).

---

## 2. Hệ Thống Design Tokens & Theme Toàn Cục (`lib/core/theme/app_theme.dart`)

### 2.1. Bảng màu chuẩn (Palette)
```dart
class AppTheme {
  // Primary & Accents
  static const Color primary = Color(0xFF6557E8);         // Stitch Violet
  static const Color primaryDark = Color(0xFF4C3BCE);     // Hover/Active State
  static const Color primaryLight = Color(0xFF9B91F5);    // Soft Violet
  static const Color primaryContainer = Color(0xFFE4DFFF);// Pill active background
  
  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8F8FC);      // Paper Background
  static const Color surface = Color(0xFFFFFFFF);         // Pure Card White
  static const Color surfaceLavender = Color(0xFFF7F5FE); // Subtle Accent Surface
  
  // Ink & Text
  static const Color textMain = Color(0xFF24233A);        // Deep Ink
  static const Color textSecondary = Color(0xFF74748B);   // Muted Slate
  static const Color textPlaceholder = Color(0xFFA1A0B5); // Disabled/Hint
  
  // Borders & Dividers
  static const Color border = Color(0xFFE7E6EF);          // Subtle Outline
  static const Color borderFocused = Color(0xFF6557E8);   // Active Border
  
  // Status & Feedback
  static const Color success = Color(0xFF27885E);         // Green
  static const Color warning = Color(0xFFC87909);         // Amber/Orange
  static const Color error = Color(0xFFBA1A1A);           // Crimson Red
}
```

### 2.2. Hệ thống đổ bóng (Luminescence Shadows) & Bán kính bo góc (Radii)
* `luminescenceShadow`: `BoxShadow(color: Color(0x146557E8), blurRadius: 16, offset: Offset(0, 4))` - tạo cảm giác nổi phát sáng nhẹ màu tím lavender.
* `cardShadow`: `BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))` - bóng nhẹ cho các thẻ nội dung.
* `cardRadius`: `16.0` (Thẻ nội dung, Modal dialogs).
* `pillRadius`: `100.0` (Nút bấm, Tabs điều hướng, Badge, Thanh tìm kiếm).
* `inputRadius`: `12.0` (Ô nhập liệu).

### 2.3. Typography
* Toàn bộ văn bản tiếng Việt: `GoogleFonts.beVietnamProTextTheme()`.
* Dữ liệu kỹ thuật, Mã phòng thi, Đồng hồ đếm ngược, Chỉ số, Công thức Toán: `GoogleFonts.firaCode()`.

---

## 3. Kiến Trúc Thanh Điều Hướng (`lib/shared/widgets/top_nav_bar.dart`)

### 3.1. Thiết kế trực quan
* Header nền `surface` có bóng đổ dưới nhẹ `0 2px 8px rgba(0,0,0,0.03)`.
* Logo "Thi Nhanh" với biểu tượng squircle tím gradient.
* **Các mục điều hướng trung tâm (Desktop / Tablet):** Dạng pill capsule bo tròn 100px.
  - Tab đang active: Nền `surfaceLavender` (`#F7F5FE`), chữ `primary` đậm (`#6557E8`), padding `(horizontal: 16, vertical: 8)`.
  - Tab không active: Chữ `textSecondary`, hiệu ứng hover nền nhẹ.
* **Cụm thao tác bên phải:**
  - Ô nhập mã phòng thi nhanh (`Nhập mã PT...`) bo tròn 100px, font `Fira Code`, nút mũi tên tím tương tác.
  - Nút biểu tượng trợ giúp (`help_outline_rounded`) mở modal Hướng dẫn nhanh.
  - Trạng thái chưa đăng nhập: Nút bấm "Đăng nhập" pill tím nổi bật.
  - Trạng thái đã đăng nhập: `CircleAvatar` kèm viền tím mảnh, bấm vào mở menu 4 mục: *Hồ sơ cá nhân*, *Lịch sử làm bài*, *Phòng thi đã tạo*, *Đăng xuất*.

### 3.2. Logic cốt lõi bắt buộc bảo toàn
1. **4 Mục điều hướng cố định:**
   * `Home` -> `/home`
   * `Tìm kiếm` -> `/search`
   * `Quản lí đề` -> `/teacher_exams`
   * `Tạo phòng thi` -> `/create_room`
2. **Kiểm tra quyền hạn Khách (`_showGuestRestrictedDialog`):**
   * Nếu là Khách và click vào `Quản lí đề` hoặc `Tạo phòng thi`: Tự động hiện dialog thông báo yêu cầu đăng nhập.
3. **Xử lý nhanh mã phòng thi (`_handleQuickJoinRoom`):**
   * Chuẩn hóa ký tự mã phòng (`PT...` hoặc số).
   * Tra cứu phòng qua `RoomRepository.getRoomByCode()`.
   * Kiểm tra trạng thái phòng (`closed`, `waiting`, `in_progress`).
   * Nếu có mật khẩu: Hiển thị dialog yêu cầu nhập mật khẩu.
   * Nếu là khách: Hiển thị dialog `JoinRoomGuestDialog` thu thập họ tên.
4. **Phòng thi biệt lập:**
   * Màn hình làm bài (`taking_exam_screen.dart`) KHÔNG dùng TopNav đầy đủ để ngăn học sinh vô tình click thoát, mà sử dụng `FocusedExamBar` tinh gọn.

---

## 4. Chi Tiết Kiến Trúc Từng Phân Hệ Màn Hình

### 4.1. Nhóm Màn Hình Học Sinh Khám Phá

#### A. Khởi Động & Đăng Nhập (`lib/screens/auth/greeting_screen.dart`)
* **Bố cục Stitch:** Hero 2 cột cân xứng (Desktop). Cột trái: Hình ảnh Glowing Book phát sáng viền tím và khẩu hiệu EdTech truyền cảm hứng. Cột phải: Thẻ xác thực bo góc 24px với bóng luminescence.
* **Logic bảo toàn:**
  - Đăng nhập Email / Password có kiểm tra định dạng và báo lỗi chuẩn.
  - Đăng nhập Google qua Firebase/Supabase (`assets/images/google_logo.png`).
  - Nút **"Trải nghiệm ngay (Chế độ Khách)"**: Khởi tạo session khách qua `authProvider.continueAsGuest()`, điều hướng vào `/home`.

#### B. Trang Chủ Học Sinh (`lib/screens/home/home_screen.dart`)
* **Bố cục Stitch:**
  - Hero search bar bo tròn lớn ở giữa.
  - Hàng 8 môn học dạng chip tròn bo góc với icon pastel.
  - **2 Thẻ Điều Hướng Thông Minh (Smart Navigation Cards):**
    1. *Bài Đang Làm Dở Dang:* Hiển thị tên bài thi, thanh tiến độ % tím gradient, nút "Tiếp tục làm bài".
    2. *Phòng Thi Trực Tiếp Đang Mở:* Hiển thị mã phòng, thời gian đếm ngược, nút "Tham gia ngay".
  - Danh sách đề thi đề xuất hiển thị dạng card lưới với bóng đổ luminescence.
  - Nút Floating AI Navigation ở góc phải dưới (`AiNavigationButton`).
* **Logic bảo toàn:**
  - Đọc nháp đề thi chưa hoàn tất từ local cache (`ExamStorageService`).
  - Lắng nghe realtime các phòng thi đang diễn ra từ Supabase.
  - Tải đề thi phân loại theo môn học khi click vào các chip môn.

#### C. Tìm Kiếm & Chi Tiết Đề Thi (`search_screen.dart` & `exam_detail_screen.dart`)
* **Bố cục Stitch:**
  - Thanh tìm kiếm kèm bộ lọc đa chiều (Lớp, Môn học, Thời lượng).
  - Thẻ đề thi hiển thị metadata: thời gian tương đối (`formatRelativeTime`), số lượng câu hỏi, số lượt làm bài.
  - Phân trang dạng Google đa trang (`GooglePaginationBar`).
  - Màn hình `exam_detail_screen`: Thẻ Hero tóm tắt thông số bài thi, danh sách các chủ đề kiến thức, và 2 nút hành động lớn: **"Luyện tập tự do"** (Bắt đầu làm bài tự luyện) & **"Vào phòng thi có mã"** (Mở popup nhập mã PT).
* **Logic bảo toàn:**
  - Bộ lọc tìm kiếm debounce không spam request.
  - Xử lý phân trang chính xác số trang và vị trí trang hiện tại.

---

### 4.2. Nhóm Màn Hình Thi Cử & Đánh Giá

#### A. Màn Hình Làm Bài Thi (`lib/screens/exam/taking_exam_screen.dart`)
* **Bố cục Stitch (Đã khắc phục hoàn toàn lỗi của bản AI):**
  - **Focused Exam Bar:** Nằm cố định trên cùng gồm Logo nhỏ, Tên bài thi, Đồng hồ đếm ngược viền nổi font `Fira Code`, Nút nộp bài viền tím nổi bật.
  - **Bố cục 2 cột chia tỉ lệ 7:3 (Desktop) hoặc tab chuyển đổi (Mobile):**
    - Cột trái (70%): Nội dung câu hỏi hiện tại, công thức Toán học định dạng LaTeX mượt mà, danh sách 4 lựa chọn A/B/C/D có hiệu ứng hover và active viền tím phát sáng.
    - Cột phải (30%): Bảng 40 câu hỏi (Lưới 5 cột x 8 hàng) được đặt trong vùng cuộn độc lập (`SingleChildScrollView`). **Nút "Nộp bài thi ngay" được đặt cố định ở đáy cột phải bằng `Container` có nền và viền ngăn cách riêng, đảm bảo 100% không bao giờ che khuất các câu hỏi 21-25.**
  - Trạng thái 4 màu của ô số câu hỏi: Xám (Chưa làm), Tím viền sáng (Đang xem), Tím đậm (Đã chọn đáp án), Cam (Đánh dấu xem lại).
* **Logic bảo toàn:**
  - **Hệ thống Giám thị Chống gian lận 4 Cấp (Anti-cheat Proctoring):** Lắng nghe sự kiện mất tiêu điểm cửa sổ (`AppLifecycleState` / Window blur). Vi phạm lần 1, 2, 3 hiển thị cảnh báo đỏ và ghi nhận vi phạm (`0/3 vi phạm`). Vi phạm lần 4 tự động thu bài cưỡng chế và gửi bản ghi về phòng thi.
  - **Thuật toán xáo trộn câu hỏi ngẫu nhiên:** Sử dụng `ExamShuffleHelper` theo seed cố định.
  - **Chống sao chép nội dung:** Bọc toàn bộ nội dung đề thi trong `SelectionContainer.disabled`.
  - **Lưu nháp cục bộ tự động:** Lưu câu trả lời sau mỗi lần chọn vào SharedPreferences để khôi phục khi reload trang.

#### B. Màn Hình Kết Quả Bài Thi (`lib/screens/exam/result_screen.dart`)
* **Bố cục Stitch:**
  - Thẻ Hero điểm số lớn (Thang điểm 10) viền gradient phát sáng, nhãn xếp loại học lực (Xuất sắc / Giỏi / Khá / Cần cố gắng).
  - Lưới 4 chỉ số thống kê phân tích: Số câu đúng/sai, Thời gian hoàn thành, Điểm quy đổi, Tốc độ trung bình.
  - Nút kêu gọi hành động chính: **"Luyện tập lại các câu sai"** (Nút tím nổi bật) & **"Xem chi tiết lời giải"** (Nút viền mảnh).
* **Logic bảo toàn:**
  - Tính điểm theo hệ số câu và chuẩn thang 10.
  - Luồng luyện tập lại câu sai: Lọc chính xác danh sách các câu làm sai và chuyển sang giao diện ôn luyện tập trung.
  - Điều hướng xem Bảng xếp hạng phòng thi nếu bài làm thuộc về một phòng thi trực tiếp.

#### C. Bảng Vàng Vinh Danh (`lib/screens/exam/student_leaderboard_screen.dart`)
* **Bố cục Stitch:**
  - **Bục Vinh Quang Top 1-2-3 (Podium):** Hạng 1 ở giữa cao nhất (Vương miện vàng hoàng gia), Hạng 2 bên trái (Bạc sáng), Hạng 3 bên phải (Đồng ấm).
  - Bảng danh sách thí sinh từ hạng 4 trở xuống hiển thị rõ Avatar, Họ tên, Điểm số `Fira Code`, Thời gian nộp bài.
  - **Sticky Bottom Personal Rank Bar:** Thanh cố định ở đáy ghim chính xác thứ hạng và điểm của thí sinh hiện tại.
* **Logic bảo toàn:**
  - Nhận diện thí sinh đăng nhập vs. thí sinh khách (gắn tag `(Khách)`).
  - Tự động sắp xếp thứ hạng theo điểm số (giảm dần) và thời gian nộp bài (tăng dần).

---

### 4.3. Nhóm Màn Hình Quản Trị Giáo Viên & Giám Thị Realtime

#### A. Quản Lý Đề Thi (`lib/screens/teacher/teacher_exams_screen.dart`)
* **Bố cục Stitch (Đã loại bỏ lỗi trùng lặp nút tạo đề của AI):**
  - Thanh tab lọc 3 trạng thái: *Tất cả*, *Đã xuất bản*, *Bản nháp*.
  - Thanh tìm kiếm và bộ lọc môn học trực quan.
  - Duy nhất 1 nút CTA chính "+ Tạo đề mới" ở góc trên bên phải.
  - Thẻ đề thi có menu thao tác nhanh: Sửa đề, Mở phòng thi trực tiếp (`Launch Live Room`), Nhân bản, Xóa.
* **Logic bảo toàn:**
  - Liên kết trực tiếp sang `CreateRoomScreen` truyền sẵn `examId`.
  - Phân quyền chỉ cho phép giáo viên sở hữu đề thi thao tác sửa/xóa.

#### B. Soạn Thảo Đề Thi (`lib/screens/exam/create_exam_screen.dart`)
* **Bố cục Stitch (Đã sửa lỗi tiêu đề bị cắt cụt và void trắng cài đặt):**
  - Cột trái: Nhập tên đề thi mở rộng không giới hạn chiều dài, danh sách câu hỏi trực quan với trình soạn thảo công thức Toán học (`VisualMathBlock`).
  - Thanh công cụ ký hiệu khoa học 5 danh mục cố định ở đáy (`ScientificBottomToolbar`).
  - Cột phải: Toàn bộ panel cài đặt đề thi được hiển thị đầy đủ (thời gian làm bài, điểm qua môn, tags môn học, chế độ riêng tư).
* **Logic bảo toàn:**
  - Dialog nhập nhanh 40 câu hỏi trắc nghiệm từ văn bản thô (`QuickBulkImportDialog`).
  - Dialog xem trước giao diện học sinh (`StudentPreviewDialog`).
  - Dialog kiểm tra tính hợp lệ trước khi xuất bản (`PublishConfirmDialog`).

#### C. Tạo Phòng Thi & Giám Thị Trực Tiếp (`create_room_screen.dart` & `live_dashboard_screen.dart`)
* **Bố cục Stitch:**
  - Hộp thoại mã QR chia sẻ phòng thi (`RoomQrDialog`) đẹp mắt để học sinh quét vào thi ngay trên điện thoại.
  - Thẻ phòng thi hiển thị mã PIN to bản (`PT######`) kèm nút bấm 1 chạm sao chép link/mã.
  - Lưới thí sinh trực tiếp (Live Grid): Avatar, Tên, Tiến độ làm bài hiện tại (ví dụ: `28/40 câu`), Trạng thái kết nối.
  - **Hệ thống cảnh báo gian lận trực quan:** Thí sinh có vi phạm hiển thị cờ đỏ cảnh báo 🚩 kèm số lần rời tab (`1/3`, `2/3`).
  - Nút thu bài cưỡng chế ⛔ với biểu tượng cảnh báo màu đỏ cho từng thí sinh hoặc thu bài toàn phòng thi.
* **Logic bảo toàn:**
  - Cấu hình phòng: Mật khẩu, giới hạn số lượng, xáo đề, cho phép xem lại bài.
  - Kênh Realtime Supabase Broadcast/Presence đồng bộ từng giây trạng thái nộp bài và vi phạm về máy giáo viên.

---

## 5. Kế Hoạch Đảm Bảo Chất Lượng & Kiểm Thử (Verification)

* **Bộ kiểm thử tự động:** Trước và sau mỗi tác vụ sửa mã nguồn, bắt buộc chạy:
  ```bash
  flutter test
  ```
  Tất cả 173 test cases phải đạt 100% `All tests passed!`.
* **Quy tắc Git:** Sau khi hoàn thành mỗi mốc, tự động chạy `git commit` và `git push` lên cả 2 kho lưu trữ (`thi_nhanh` và `CODE`).
* **Đồng bộ tài liệu:** Cập nhật `docs/system_architecture_and_deep_evaluation.md` và artifact tương ứng.
