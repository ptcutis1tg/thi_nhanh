# Thiết Kế Nâng Cấp Toàn Diện Tính Năng Lịch Sử Làm Bài (Student Test History Overhaul)

- **Ngày tạo:** 04/10/2026
- **Tài liệu đặc tả:** Design Specification
- **Trạng thái:** Chờ phê duyệt (Pending Approval)

---

## 1. Tổng Quan & Mục Tiêu

Tính năng **Lịch sử làm bài** đóng vai trò trung tâm trong hành trình học tập của học sinh trên nền tảng Ôn Thi Nhanh. Đây là nơi học sinh nhìn lại toàn bộ quá trình ôn luyện, đánh giá sự tiến bộ qua từng môn học, theo dõi kết quả các phòng thi trực tiếp do giáo viên tổ chức và xác định các lỗ hổng kiến thức cần củng cố.

Tuy nhiên, qua rà soát chi tiết hiện trạng, hệ thống hiện tồn tại nhiều điểm bất hợp lý nghiêm trọng về mặt dữ liệu (bỏ sót các bài thi khi giáo viên đóng phòng), điều hướng (nút quay lại bị gán cứng vào hồ sơ, trùng lặp route), giao diện bị tràn vỡ trên thiết bị di động (overflow màn hình nhỏ), và thiếu các tính năng giá trị gia tăng giúp học sinh học tập từ chính các lỗi sai của mình.

### Mục tiêu nâng cấp:
1. **Khắc phục triệt để các lỗi Logic & Dữ liệu:** Đảm bảo 100% bài thi hợp lệ (cả nộp bình thường `submitted` và nộp khi hết giờ/giáo viên đóng phòng `expired`) hiển thị đầy đủ, chính xác, tôn trọng trạng thái công bố kết quả (`result_released_at`).
2. **Chuẩn hóa Phân luồng & Điều hướng (User Flow):** Loại bỏ trùng lặp route, hỗ trợ quay lại thông minh (`canPop`), thêm lối tắt truy cập trực tiếp từ Menu Avatar trên thanh điều hướng (`TopNavBar`), và có luồng dẫn dắt thân thiện cho khách vãng lai.
3. **Hiện đại hóa Giao diện & Tối ưu Responsive Mobile:** Thiết kế giao diện thẻ bài thi giàu thông tin (Huy hiệu chế độ thi, thời gian làm, số câu đúng/tổng số câu, trạng thái công bố), giải quyết dứt điểm lỗi tràn viền (RenderFlex Overflow) của hàng chỉ số trên di động, và tối ưu bộ lọc bằng thanh cuộn ngang kết hợp ModalBottomSheet trên màn hình hẹp.
4. **Bổ sung Tính năng Học tập Chuyên sâu:** Tích hợp tính năng "Luyện lại câu sai" trực tiếp từ lịch sử bài làm và tính năng "Xuất / Lưu báo cáo kết quả bài thi" để học sinh và phụ huynh lưu trữ.

---

## 2. Phân Tích Các Điểm Bất Hợp Lý & Giải Pháp

### 2.1. Logic & Dữ liệu (Backend & Service)

| Hiện trạng & Lỗi phát hiện | Hậu quả | Giải pháp kỹ thuật |
| :--- | :--- | :--- |
| **Bỏ sót bài thi trạng thái `expired`:** Truy vấn `ProfileService` chỉ lấy `where((a) => a['status'] == 'submitted')`. | Khi giáo viên bấm "Kết thúc phòng thi", hàm RPC `close_teacher_room` cập nhật các bài thi của học sinh sang trạng thái `expired`. Do đó, toàn bộ các bài thi học sinh tham gia trong phòng thi khi bị giáo viên đóng sẽ **biến mất hoàn toàn** khỏi lịch sử thi! | Mở rộng điều kiện lọc: Chấp nhận cả `status in ('submitted', 'expired')` có điểm số hợp lệ (`score != null`). |
| **Không kiểm tra `result_released_at`:** Dữ liệu điểm số hiển thị trực tiếp mà không xét quyền công bố điểm. | Trong các phòng thi trực tiếp chưa kết thúc hoặc chưa được giáo viên cho phép xem điểm, điểm số có thể bị lộ sớm hoặc hiển thị không đồng bộ với màn hình phòng chờ. | Bổ sung kiểm tra `result_released_at`: Nếu phòng thi chưa công bố điểm, hiển thị huy hiệu "Đang chờ công bố" thay vì hiển thị điểm số; chỉ kích hoạt xem chi tiết đáp án khi kết quả đã được giải phóng. |
| **Thiếu thông tin phòng thi & thời gian làm bài:** `StudentTestHistoryData` chỉ lưu icon, tiêu đề, ngày, điểm, môn học. | Người dùng không biết bài thi đó là tự luyện hay thi trong phòng thi của giáo viên nào, làm trong bao lâu (duration). | Bổ sung vào model `StudentTestHistoryData`: `roomId`, `roomCode`, `durationSeconds`, `durationFormatted`, `isLiveRoom`, `resultReleased`. |
| **Truy vấn toàn bộ không phân trang ở database:** Tải toàn bộ lượt làm bài của người dùng về client rồi mới cắt trang. | Gây chậm trễ khi tài khoản có hàng trăm lượt làm bài. | Giữ client-side filtering mượt mà cho tập dữ liệu hiện tại, nhưng tối ưu cấu trúc select gọn nhẹ và thiết lập giới hạn tải hợp lý. |

### 2.2. Phân luồng người dùng & Điều hướng (User Flow)

| Hiện trạng & Điểm bất hợp lý | Giải pháp kỹ thuật |
| :--- | :--- |
| **Nút Back bị gán cứng vào `/profile`:** `IconButton(onPressed: () => context.go('/profile'))`. Khi học sinh đến từ màn hình Kết quả thi (`/result`) hoặc Trang chủ (`/home`), bấm Back lại bị chuyển sang Hồ sơ. | Sử dụng cơ chế điều hướng thông minh: `if (context.canPop()) context.pop(); else context.go('/profile');`. |
| **Trùng lặp Route trong `main.dart`:** Khai báo `/student/history` 2 lần tại dòng 272-279 và 320-327. | Dọn dẹp bỏ định nghĩa route trùng lặp trong GoRouter để tránh xung đột routing. |
| **Truy cập lịch sử gián tiếp:** Người dùng phải bấm vào Avatar chuyển sang `/profile`, cuộn xuống dưới rồi mới bấm "Xem tất cả lịch sử". | Bổ sung PopupMenuButton tại Avatar góc phải `TopNavBar` cho tài khoản đã đăng nhập: Bao gồm "Hồ sơ của tôi", "Lịch sử làm bài", và "Đăng xuất". |
| **Khách vãng lai (Guest) vào màn hình lịch sử:** Khách chưa đăng nhập không có `userId`, màn hình chỉ hiện rỗng không có hướng dẫn. | Hiển thị Banner thân thiện trên đầu trang dành cho Guest: *"Bạn đang duyệt ở chế độ khách. Đăng nhập để lưu trữ và đồng bộ toàn bộ lịch sử bài thi vĩnh viễn trên đám mây!"* kèm nút "Đăng nhập ngay". |

### 2.3. Giao diện & Trải nghiệm (UI/UX)

| Điểm bất hợp lý trên giao diện | Giải pháp thiết kế |
| :--- | :--- |
| **Lỗi tràn viền (RenderFlex Overflow) trên Mobile:** Hàng 3 thẻ chỉ số (Tổng bài, Điểm TB, Điểm cao nhất) dùng `Row` 3 phần tử cố định. Trên màn hình < 600px, chữ và icon bị đè nát hoặc báo lỗi đỏ tràn khung. | Sử dụng `LayoutBuilder`: Trên desktop giữ hàng 3 thẻ; trên màn hình hẹp/mobile tự động chuyển sang `Wrap` hoặc hàng cuộn ngang (Horizontal scrollable chips) với kích thước co giãn linh hoạt. |
| **Bảng bộ lọc (Filter Panel) choán hết màn hình di động:** Trên màn hình hẹp (< 900px), toàn bộ panel bộ lọc bị xếp chồng lên trên danh sách bài thi, khiến người dùng phải cuộn qua 11 chip môn học, ngày, điểm, sắp xếp mới thấy được bài thi đầu tiên. | Trên Mobile (< 768px): Thay thế panel dọc bằng thanh chip ngang chọn nhanh Môn học + 1 nút "Bộ lọc nâng cao" mở `ModalBottomSheet` hiện đại, giúp danh sách bài thi luôn nằm ngay trong tầm nhìn. |
| **Thiếu Tab chuyển nhanh chế độ thi:** Học sinh khó phân biệt đâu là bài thi giáo viên giao trong phòng thi trực tiếp, đâu là bài mình tự luyện. | Đặt 3 Tab chuyển đổi nhanh 1 chạm ở ngay đầu trang: **"Tất cả"** | **"Phòng thi trực tiếp"** | **"Tự luyện tập"**. |
| **Thẻ bài thi (History Card) đơn điệu:** Chỉ có tiêu đề, môn học và điểm số. | Thiết kế lại Thẻ bài thi hiện đại: Bổ sung huy hiệu phân loại chế độ thi (badge màu xanh dương `Phòng thi: PTxxxxxx` hoặc màu tím `Tự luyện`), hiển thị thời gian làm bài (ví dụ `18:45`), điểm số phân loại màu (Xanh lá >=8, Tím 5-7.9, Cam <5), trạng thái công bố điểm, và các nút thao tác nhanh. |

---

## 3. Kiến Trúc Tính Năng & Chi Tiết Triển Khai

Lộ trình triển khai được phân định rõ ràng làm 2 giai đoạn:

### Giai đoạn 1: Nền Tảng Cốt Lõi, Khắc Phục Lỗi Logic & Đại Tu UI/UX

1. **Cập nhật Mô hình Dữ liệu (`StudentTestHistoryData`):**
   - Thêm các trường:
     ```dart
     final String? roomId;
     final String? roomCode;
     final int? durationSeconds;
     final bool isLiveRoom;
     final bool resultReleased;
     ```
   - Thêm getter:
     ```dart
     String get durationFormatted => ...; // "15 phút 30 giây" hoặc "15:30"
     ```

2. **Cập nhật `ProfileService.fetchStudentData`:**
   - Điều chỉnh truy vấn Supabase lấy thêm `room_id`, `rooms(code, name, status)`, `result_released_at`.
   - Nới rộng điều kiện lọc bài làm đã hoàn thành:
     ```dart
     final submittedAttempts = attemptsList.where((a) {
       final status = a['status'] as String?;
       final score = a['score'];
       return (status == 'submitted' || status == 'expired') && score != null;
     }).toList();
     ```
   - Tính toán chính xác `durationSeconds` từ `started_at` và `submitted_at`.

3. **Tối ưu Điều hướng & TopNavBar:**
   - Dọn dẹp route trùng lặp `/student/history` trong `lib/main.dart`.
   - Cập nhật nút quay lại trong `StudentHistoryScreen`:
     ```dart
     IconButton(
       onPressed: () {
         if (context.canPop()) {
           context.pop();
         } else {
           context.go('/profile');
         }
       },
       icon: const Icon(Icons.arrow_back_rounded),
     )
     ```
   - Thêm `PopupMenuButton` tại Avatar trên `TopNavBar` hỗ trợ truy cập 1 chạm vào "Lịch sử làm bài".
   - Bổ sung Banner nhắc nhở đăng nhập cho khách vãng lai.

4. **Tái Cấu Trúc Giao Diện `StudentHistoryScreen`:**
   - **Hàng chỉ số (Metric Cards):** Sử dụng `LayoutBuilder` hỗ trợ chế độ Grid / Wrap trên di động.
   - **Thanh 3 Tab chế độ thi:** [Tất cả] - [Phòng thi trực tiếp] - [Tự luyện tập].
   - **Bộ lọc đa nền tảng:**
     - Desktop (>= 900px): Sidebar bộ lọc hiện đại bên trái.
     - Mobile (< 900px): Thanh cuộn ngang các môn học thịnh hành + Nút mở `ModalBottomSheet` chứa đầy đủ bộ lọc thời gian, mức điểm, sắp xếp.
   - **Thiết kế Thẻ bài thi mới (`_buildHistoryCard`):**
     - Huy hiệu chế độ thi (`Phòng thi PTxxxxxx` vs `Tự luyện`).
     - Thời gian làm bài (`15:20`).
     - Badge điểm số viền màu sắc bắt mắt.
     - Nút hành động: "Xem kết quả" (dẫn tới `/result?attemptId=...`).

---

### Giai đoạn 2: Tính Năng Học Tập Chuyên Sâu

1. **Tính Năng "Luyện Lại Câu Sai" (Retake Wrong Questions):**
   - Khi xem một bài thi trong lịch sử có số câu làm sai hoặc bỏ qua (`wrongCount > 0` hoặc điểm < 10):
   - Xuất hiện nút **"Luyện lại câu sai"** (icon `Icons.replay_rounded` hoặc `Icons.auto_fix_high_rounded`).
   - Khi bấm vào nút này:
     - Hệ thống tải review payload của bài thi thông qua `AssessmentRepository.loadReview(attemptId)`.
     - Lọc danh sách các câu hỏi mà học sinh trả lời sai hoặc chưa trả lời.
     - Khởi tạo một phiên tự luyện tập tập trung (Practice session) chỉ gồm các câu hỏi sai đó, cho phép học sinh làm lại và kiểm tra ngay giải thích đáp án.

2. **Tính Năng "Xuất Báo Cáo / In Kết Quả Bài Thi" (Export & Share):**
   - Tại màn hình xem chi tiết kết quả hoặc từ thẻ bài thi lịch sử:
   - Cung cấp nút "In / Tải báo cáo PDF" hoặc tạo ảnh tóm tắt kết quả (Scorecard) chuẩn thẩm mỹ, bao gồm:
     - Tên học sinh, tên đề thi, ngày thi, thời gian làm bài.
     - Điểm số tổng kết, số câu đúng/sai/bỏ qua.
     - Biểu đồ hình tròn hoặc thanh tiến độ trực quan.
     - Mã QR kiểm tra tính xác thực của bài thi.

---

## 4. Kế Hoạch Kiểm Thử (Testing & Verification)

Toàn bộ quy trình phát triển sẽ tuân thủ nghiêm ngặt phương pháp luận **TDD (Test-Driven Development)**:
1. **Unit Tests:**
   - Kiểm thử mô hình `StudentTestHistoryData` phân tích đúng các trường mới (`roomId`, `durationSeconds`, `isLiveRoom`, `durationFormatted`).
   - Kiểm thử logic lọc trong `ProfileService` nhận diện chính xác cả bài thi `submitted` và `expired`.
2. **Widget Tests:**
   - Kiểm thử `StudentHistoryScreen` hiển thị hàng chỉ số co giãn tốt trên màn hình nhỏ (360x640px) không có lỗi tràn viền (RenderFlex overflow).
   - Kiểm thử 3 Tab chế độ thi lọc đúng danh sách bài thi tương ứng.
   - Kiểm thử nút Back quay lại thông minh bằng `context.pop()` khi có thể.
   - Kiểm thử menu Popup trên `TopNavBar` điều hướng chính xác vào `/student/history`.
   - Kiểm thử hiển thị huy hiệu trạng thái và các nút hành động trên Thẻ bài thi.
3. **Integration & Regression:**
   - Đảm bảo toàn bộ 129 bài kiểm thử hiện có của dự án tiếp tục vượt qua 100%.

---

## 5. Kết Luận & Chờ Phê Duyệt

Bản thiết kế này giải quyết triệt để tất cả các vấn đề bất cập được phát hiện qua quá trình rà soát mã nguồn, đồng thời nâng tầm tính năng Lịch sử làm bài thành một công cụ học tập chủ động và thông minh cho học sinh.
