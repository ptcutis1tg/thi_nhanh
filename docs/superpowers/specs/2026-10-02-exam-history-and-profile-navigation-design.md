# Thiết Kế Chi Tiết: Màn Hình Lịch Sử Làm Bài Thi & Cải Tiến Điều Hướng Profile

**Ngày:** 02/10/2026  
**Trạng thái:** Đã duyệt (Approved)  
**Tác giả:** Antigravity  

---

## 1. Mục Tiêu & Bối Cảnh (Context & Goals)

### Vấn đề hiện tại:
1. **Lỗi điều hướng Profile:** Trong `ProfileScreen`, ở mục "🕘 Bài thi gần đây", nút "Chi tiết" hiện tại chỉ gọi hiển thị `SnackBar` giả lập (`_showSnackBar('Xem chi tiết bài thi: $title')`) mà không chuyển hướng người dùng đến màn hình xem lại kết quả chi tiết của đề thi đã nộp.
2. **Quá tải danh sách:** `ProfileScreen` hiển thị toàn bộ bài thi đã làm thay vì giới hạn số lượng hợp lý, gây dài dòng cho trang hồ sơ cá nhân. Nút "Xem tất cả lịch sử" cũng chỉ hiển thị `SnackBar`.
3. **Thiếu màn hình chuyên biệt:** Người học cần một không gian chuyên biệt để quản lý, tìm kiếm, lọc và xem lại toàn bộ lịch sử thi cử của mình với trải nghiệm tương tự trang Tìm kiếm đề thi (`SearchScreen`), bao gồm phân trang 20 đề/trang với thanh chuyển số trang 1, 2, 3...

### Mục tiêu đạt được:
- Sửa triệt để nút "Chi tiết" tại Profile để chuyển hướng chính xác tới `/result?attemptId=...`.
- Giới hạn mục "🕘 Bài thi gần đây" tại Profile tối đa 10 đề mới nhất.
- Bấm nút "Xem tất cả lịch sử" sẽ mở màn hình **Lịch sử làm bài thi** (`StudentHistoryScreen`).
- Màn hình Lịch sử làm bài có:
  - Thanh tìm kiếm theo tên đề / môn học ở trên cùng.
  - Bộ lọc đa tiêu chí dạng Chip / Danh mục: Môn thi, Ngày thi (Hôm nay, 7 ngày, 30 ngày, tùy chọn ngày), Điểm thi (>= 8.0, 5.0 - 7.9, < 5.0), Sắp xếp.
  - Phân trang 20 đề mỗi trang, sử dụng `GooglePaginationBar` hiển thị các số 1, 2, 3...
  - Bấm vào bất kỳ bài thi nào hoặc nút "Xem kết quả" sẽ mở ngay màn hình kết quả bài thi.

---

## 2. Kiến Trúc & Cấu Trúc Dữ Liệu (Architecture & Data Model)

### 2.1 Mở rộng `StudentTestHistoryData` ([`lib/core/services/profile_service.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/core/services/profile_service.dart))
Thêm các thuộc tính mới để hỗ trợ tìm kiếm và lọc chính xác:
```dart
class StudentTestHistoryData {
  final String id;
  final String subjectIcon;
  final String title;
  final String date;
  final String score;
  final double scoreValue;
  final String subject;
  final DateTime? submittedAt;

  StudentTestHistoryData({
    required this.id,
    required this.subjectIcon,
    required this.title,
    required this.date,
    required this.score,
    required this.scoreValue,
    this.subject = 'Khác',
    this.submittedAt,
  });
}
```

### 2.2 Cấu hình Route trong [`lib/main.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/main.dart)
Tích hợp `StudentHistoryScreen` vào `ShellRoute` (có `TopNavBar`):
```dart
GoRoute(
  path: '/student/history',
  pageBuilder: (context, state) => buildPageWithSlideTransition(
    context: context,
    state: state,
    child: const StudentHistoryScreen(),
  ),
),
```

---

## 3. Cải Tiến `ProfileScreen` ([`lib/screens/profile/profile_screen.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/profile/profile_screen.dart))

1. **Giới hạn 10 đề gần nhất:**
   ```dart
   final displayedRecentTests = _studentData.recentTests.take(10).toList();
   ```
2. **Điều hướng nút "Chi tiết":**
   ```dart
   InkWell(
     onTap: () => context.go('/result?attemptId=${Uri.encodeComponent(test.id)}'),
     ...
   )
   ```
3. **Điều hướng nút "Xem tất cả lịch sử":**
   ```dart
   TextButton.icon(
     onPressed: () => context.go('/student/history'),
     icon: const Text('Xem tất cả lịch sử'),
     label: const Icon(Icons.arrow_forward_rounded, size: 16),
   )
   ```

---

## 4. Thiết Kế Màn Hình Lịch Sử Làm Bài (`StudentHistoryScreen`)

### 4.1 Cấu trúc Giao diện (Layout)
- **Top Header:**
  - Nút Mũi tên Back quay lại `/profile`.
  - Tiêu đề: "📊 Lịch Sử Làm Bài Thi".
  - Thanh tìm kiếm `_SearchBox` (TextField bo tròn, nút Tìm kiếm, tìm tức thì theo tiêu đề và môn học).
  - 3 Thẻ chỉ số tổng quan: Tổng số bài đã làm, Điểm trung bình, Điểm cao nhất.
- **Thân trang (Responsive Layout):**
  - Cột trái (Desktop 260px, hoặc Collapsible trên Mobile): `_HistoryFilterPanel`
    - Bộ lọc Môn học (Chips): Tất cả, Toán, Vật lý, Hóa học, Sinh học, Tiếng Anh, Ngữ văn, Lịch sử, Địa lý, Tin học, GDCD...
    - Bộ lọc Ngày thi (Chips): Tất cả, Hôm nay, 7 ngày qua, 30 ngày qua, Tùy chọn ngày (hiển thị DateRangePicker).
    - Bộ lọc Điểm thi (Chips): Tất cả, Giỏi/Xuất sắc (>= 8.0), Khá/Trung bình (5.0 - 7.9), Dưới trung bình (< 5.0).
    - Sắp xếp (Dropdown): Mới nhất, Cũ nhất, Điểm cao nhất, Điểm thấp nhất.
    - Nút Đặt lại bộ lọc.
  - Cột phải (Expanded):
    - Dòng trạng thái: "Tìm thấy X bài thi • Đang hiện A - B (Trang P / T)".
    - Danh sách thẻ bài thi: Mỗi thẻ hiển thị icon môn, ngày giờ nộp bài, tiêu đề đề thi, huy hiệu điểm số (`8.0 điểm` xanh lá, `5.5 điểm` tím, `3.0 điểm` đỏ cam), nút "Xem kết quả".
    - Nhấn vào thẻ hoặc nút "Xem kết quả" -> `context.go('/result?attemptId=${test.id}')`.
    - Thanh phân trang cuối trang: `GooglePaginationBar(currentPage: _currentPage, totalPages: totalPages, onPageChanged: ...)`.
    - Khi đổi trang, tự động cuộn mượt về đầu danh sách: `_scrollController.animateTo(0, ...)`.

---

## 5. Chiến Lược Kiểm Thử (Testing Strategy)

1. **Unit Tests (`test/models/student_history_test.dart`):**
   - Kiểm tra `StudentTestHistoryData` chứa đúng `subject`, `submittedAt`.
   - Kiểm tra logic lọc: theo từ khóa, môn học, khoảng thời gian, xếp loại điểm.
   - Kiểm tra logic phân trang: 20 mục mỗi trang, tính toán số trang chính xác.
2. **Widget Tests (`test/screens/student_history_screen_test.dart` & `test/screens/profile_screen_test.dart`):**
   - ProfileScreen: chỉ render tối đa 10 đề gần nhất; nhấn "Chi tiết" gọi router với `/result?attemptId=...`; nhấn "Xem tất cả lịch sử" mở `/student/history`.
   - StudentHistoryScreen: tìm kiếm từ khóa, chọn chip bộ lọc môn/ngày/điểm, bấm chuyển trang qua `GooglePaginationBar`.
3. **Quy Tắc Auto-Push:** Chạy `flutter test` toàn diện, tự động commit và `git push origin main`.
