# Thiết Kế Kỹ Thuật: Hoàn Thiện Trình Soạn Thảo Đề Thi, Hiệu Ứng Khối & Vòng Đời Phòng Thi

- **Ngày lập:** 11/10/2026
- **Trạng thái:** Đã thống nhất thiết kế
- **Dự án:** Thi Nhanh (`c:\Users\ADMINE\Desktop\CODE\thi_nhanh`)

---

## 1. Mục Tiêu & Phạm Vi (Goals & Scope)

Giải quyết trọn vẹn 6 yêu cầu người dùng đề ra nhằm nâng cao tính tiện dụng, thẩm mỹ và độ tin cậy của ứng dụng:
1. **Đa dạng môn học & Tag `none`:** Hỗ trợ danh mục môn học toàn diện theo chương trình GDPT, cho phép để trống môn học khi tạo đề; nếu không có tag môn học thì gắn thẻ là `none`.
2. **Chỉnh sửa thông tin đề trong Editor:** Cho phép sửa Tên đề, Môn học và Thời lượng trực tiếp trong màn hình soạn thảo đề thi mà không cần quay lại từ đầu.
3. **Hiệu ứng Glow Xám Nhẹ Dưới Mỗi Khối:** Bổ sung hiệu ứng bóng mờ xám nhẹ (`softGlowShadow`) dưới các khối tiếp xúc trực tiếp với nền (Editor container, sidebar cards, exam cards) giúp các khối nổi bật, sang trọng.
4. **Popup Kiểm Tra Đủ 10 Điểm Khi Xuất Bản:** Bắt buộc tổng điểm bằng đúng 10 điểm mới cho xuất bản đề; cung cấp 2 tùy chọn: Sửa tiếp hoặc Tự động chia đều điểm thành 10.
5. **Tự Động Nộp & Điều Hướng Khi Host Đóng Phòng:** Khi host kết thúc phòng thi, học sinh đang ở màn hình làm bài (`TakingExamScreen`) được tự động phát hiện, nộp bài và điều hướng ngay sang màn hình kết quả (`/result`).
6. **Sửa Lỗi Không Xóa Được Đề Đang Làm Trong Lịch Sử:** Sửa lỗi enum `attempt_status` và quyền RLS để học sinh hủy / xóa được các bài thi dở dang khỏi mục Lịch sử làm bài.

---

## 2. Thiết Kế Kiến Trúc & Chi Tiết Triển Khai

### 2.1. Đa Dạng Môn Học & Gắn Thẻ `none`
- **Danh sách môn học hỗ trợ:**
  `['none', 'Toán', 'Ngữ văn', 'Tiếng Anh', 'Vật lý', 'Hóa học', 'Sinh học', 'Lịch sử', 'Địa lý', 'Giáo dục công dân', 'Tin học', 'Công nghệ', 'Khoa học tự nhiên', 'Lịch sử & Địa lý', 'Ngoại ngữ khác']`.
- **Luồng khởi tạo đề thi (`CreateExamScreen`):**
  - Trường "Môn học" không bắt buộc `*`. Giá trị mặc định hoặc khi chọn "Không phân loại / Không chọn" là `'none'`.
  - Hàm validate `_configureExam()` chỉ yêu cầu tên đề thi (>= 3 ký tự) và thời lượng (1-360 phút). Nếu `_selectedSubject == null` hoặc trống, tự động gán `_selectedSubject = 'none'`.
- **Hiển thị Badge / Tag:**
  - Khi hiển thị ở màn hình chi tiết, xem trước học sinh, hoặc danh sách đề thi: Nếu `subject == 'none'` hoặc rỗng, hiển thị Chip nhãn `'none'` với nền xám nhạt (`#F1F5F9`) và chữ xám (`#475569`).

---

### 2.2. Chỉnh Sửa Thông Tin Đề Ngay Trong Màn Hình Soạn Thảo
- **Điểm chạm (Touchpoints):**
  1. Nút icon cây bút chì `IconButton(icon: Icon(Icons.edit_outlined))` đặt cạnh Tên đề thi tại `_buildTopHeader()`.
  2. Khối thông tin đề thi ở `ExamRightSidebar` được bọc `InkWell` với tooltip trực quan.
- **Hộp thoại chỉnh sửa (`EditExamInfoDialog`):**
  - Cho phép sửa:
    - Tên đề thi (`TextFormField`, validate >= 3 ký tự).
    - Môn học (`DropdownButtonFormField` danh sách môn học + tùy chọn `'none'`).
    - Thời lượng (`TextFormField` dạng số, 1 - 360 phút).
  - Khi người dùng bấm "Cập nhật":
    - Cập nhật state cục bộ (`_examNameController`, `_selectedSubject`, `_durationController`).
    - Cập nhật danh mục khoa học `_scientificCategory = _categoryForSubject(_selectedSubject)`.
    - Tự động gọi `_saveDraft()` để lưu thay đổi lên cơ sở dữ liệu.

---

### 2.3. Hiệu Ứng Glow Xám Nhẹ Dưới Mỗi Khối (`softGlowShadow`)
- **Token giao diện tại `AppTheme`:**
  ```dart
  static final List<BoxShadow> softGlowShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  ```
- **Các vị trí áp dụng:**
  - Khối soạn câu hỏi trung tâm (`_buildCenterEditor`).
  - Khối card thông tin và danh sách câu hỏi trong `ExamLeftSidebar` & `ExamRightSidebar`.
  - Khối thẻ lịch sử thi dở dang / đã hoàn thành trong `StudentHistoryScreen`.
  - Khối thẻ đề thi trong `HomeScreen`.

---

### 2.4. Popup Kiểm Tra Tổng Điểm 10 Khi Xuất Bản
- **Điều kiện kiểm tra:**
  - Trước khi gọi `repo.publish(_examId!)`, kiểm tra `(_totalPoints - 10.0).abs() > 0.01`.
- **Giao diện Popup cảnh báo (`AlertDialog`):**
  - **Tiêu đề:** Icon cảnh báo cam + *"Tổng điểm bài thi chưa đạt 10 điểm"*.
  - **Nội dung:** *"Hiện tại tổng điểm là ${_totalPoints.toStringAsFixed(1)}/10 điểm. Đề thi cần đạt đúng 10 điểm để có thể xuất bản."*
  - **Lựa chọn 1 ("Sửa tiếp"):** Đóng dialog, đưa tiêu điểm về trình soạn thảo.
  - **Lựa chọn 2 ("Tự động chia đều 10 điểm"):**
    - Thực thi hàm `_distributePointsEvenly()`.
    - Điểm từng câu được chia đều (ví dụ 10 câu -> mỗi câu 1.0; 4 câu -> mỗi câu 2.5).
    - Hiển thị SnackBar *"Đã chia đều 10 điểm thành công."*.
    - Đóng dialog để giáo viên quan sát lại tổng điểm và các câu hỏi trước khi bấm Xuất bản lại.

---

### 2.5. Tự Động Nộp & Điều Hướng Khi Host Đóng Phòng
- **Lắng nghe sự kiện trong `TakingExamScreen`:**
  - Nếu `widget.roomId != null`, khởi tạo kênh Realtime Supabase lắng nghe bảng `rooms` với filter `id = eq.${widget.roomId}`.
  - Kết hợp Polling dự phòng mỗi 4 giây (kiểm tra `room.status == 'closed'`).
  - Hủy subscription và timer khi `dispose()`.
- **Xử lý khi Host đóng phòng:**
  - Ngay khi nhận được `status == 'closed'` và `!_hasSubmitted`:
    - Hủy bộ đếm thời gian.
    - Hiển thị thông báo nổi: *"Phòng thi đã kết thúc bởi giáo viên. Hệ thống đang tự động nộp bài..."*.
    - Gọi `_submitExam()` để lưu kết quả và tính điểm.
    - Chuyển hướng người dùng sang `/result?attemptId=${_attemptId}&roomId=${widget.roomId}`.

---

### 2.6. Khắc Phục Lỗi Xóa Bài Thi Dở Dang Trong Lịch Sử
- **Nguyên nhân gốc rễ:**
  - `ProfileService.cancelOrDeleteAttempt` gán `status: 'cancelled'`, vi phạm check enum `attempt_status` trong Postgres (`in_progress`, `submitted`, `expired`).
  - Bảng `attempts` thiếu policy RLS cho phép lệnh `DELETE` của học sinh.
- **Giải pháp:**
  - **Database Migration (`202610110001_fix_cancel_or_delete_student_attempt.sql`):**
    - Tạo RPC `cancel_or_delete_student_attempt(p_attempt_id uuid)` có `SECURITY DEFINER` kiểm tra quyền sở hữu bài làm của user/guest, cập nhật trạng thái `status = 'expired'` hoặc xóa triệt để attempt nếu chưa nộp.
    - Bổ sung RLS Policy `allow deleting own unfinished attempts` trên bảng `attempts` với điều kiện `status = 'in_progress' and (user_id = auth.uid() or guest_name is not null)`.
  - **Tầng Service (`ProfileService.cancelOrDeleteAttempt`):**
    - Gọi RPC trước, fallback cập nhật `status = 'expired'` và xóa record.
    - Dọn dẹp cache local và làm mới dữ liệu `_loadData()` ngay lập tức.

---

## 3. Kế Hoạch Kiểm Thử (Testing Strategy)
1. **Unit & Widget Tests:**
   - Test `CreateExamScreen`: Cho phép tạo đề với môn học `none` hoặc trống; mở modal sửa thông tin đề và cập nhật state thành công; chặn xuất bản nếu tổng điểm khác 10 và kiểm tra nút chia đều điểm.
   - Test `TakingExamScreen`: Mô phỏng sự kiện đóng phòng thi (`status == 'closed'`), xác nhận kích hoạt nộp bài tự động và điều hướng.
   - Test `StudentHistoryScreen`: Xác nhận thao tác bấm "Hủy bài" / "Xóa bài" gọi hàm service thành công và làm mới danh sách.
2. **Static Analysis & Regression:**
   - Đảm bảo 0 cảnh báo `flutter analyze`.
   - Chạy toàn bộ test suite (>= 234 tests pass 100%).
