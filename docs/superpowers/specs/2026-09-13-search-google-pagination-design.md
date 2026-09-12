# Thiết Kế Chi Tiết: Phân Trang 15 Đề/Trang & Điều Hướng Chuẩn Google Trong Tìm Kiếm

## 1. Mục Tiêu & Bối Cảnh
- **Mục tiêu:** Giới hạn hiển thị tối đa 15 đề thi trên mỗi trang trong màn hình Tìm kiếm (`SearchScreen`). Khi tổng số đề thi vượt quá 15, hiển thị thanh phân trang chuẩn phong cách tìm kiếm Google (`< Trước  1  2  3  ... 10  Tiếp >`) ở cuối danh sách.
- **Trải nghiệm:** Tự động hiển thị dòng thông tin số lượng kết quả ở đầu danh sách, tự động cuộn mượt (*smooth scroll*) lên đầu danh sách khi chuyển trang và tự động quay về trang 1 khi người dùng thay đổi bộ lọc tìm kiếm.

---

## 2. Kiến Trúc Thành Phần

### 2.1. Component `GooglePaginationBar`
- **File:** `lib/shared/widgets/google_pagination_bar.dart`
- **Mục đích:** Widget tái sử dụng độc lập, tính toán dải số trang và hiển thị thanh điều hướng theo chuẩn Google.
- **Thuộc tính:**
  - `final int currentPage`: Số trang hiện tại (1-indexed).
  - `final int totalPages`: Tổng số trang (yêu cầu $\ge 1$).
  - `final ValueChanged<int> onPageChanged`: Hàm callback khi chọn trang mới.
- **Thuật toán tạo dải trang (Page Window Algorithm):**
  - Trả về danh sách `List<dynamic>` gồm các số nguyên `int` và ký hiệu `'...'`.
  - Nếu `totalPages <= 7`: Trả về `[1, 2, ..., totalPages]`.
  - Nếu `totalPages > 7`:
    - Nếu `currentPage <= 4`: `[1, 2, 3, 4, 5, '...', totalPages]`.
    - Nếu `currentPage >= totalPages - 3`: `[1, '...', totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages]`.
    - Nếu ở giữa: `[1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages]`.
- **Giao diện:**
  - Nút `< Trước`: Nhãn text kèm icon mũi tên trái, mờ đi và `onTap: null` khi `currentPage == 1`.
  - Nút `Tiếp >`: Nhãn text kèm icon mũi tên phải, mờ đi và `onTap: null` khi `currentPage == totalPages`.
  - Nút trang hiện tại: Nền màu chính `AppTheme.primary`, chữ trắng, bo góc tròn 8-10px, có đổ bóng nhẹ.
  - Nút trang thường: Nền trong suốt hoặc màu xám nhạt, hiệu ứng hover, chữ xám đậm.
  - Ký hiệu `'...'`: Hiển thị dạng text `Text('...', style: TextStyle(color: AppTheme.textSecondary))`, không thể bấm.

---

### 2.2. Tích Hợp Vào `SearchScreen`
- **File:** `lib/screens/home/search_screen.dart`
- **Biến trạng thái mới:**
  - `static const int _pageSize = 15;`
  - `int _currentPage = 1;`
  - `final ScrollController _scrollController = ScrollController();`
- **Logic cắt dữ liệu (Slicing):**
  - Lấy danh sách sau lọc `final results = _filteredItems;`
  - Tính tổng số trang: `final totalPages = (results.length / _pageSize).ceil().clamp(1, 99999);`
  - Bảo vệ biên: nếu `_currentPage > totalPages` thì `_currentPage = totalPages;`
  - Cắt 15 phần tử của trang hiện tại:
    ```dart
    final startIndex = (_currentPage - 1) * _pageSize;
    final pageItems = results.skip(startIndex).take(_pageSize).toList();
    ```
- **Header thông số kết quả:**
  - Nếu danh sách có kết quả:
    - Hiển thị Text: *"Tìm thấy khoảng ${results.length} đề thi • Đang hiện ${startIndex + 1} - ${math.min(startIndex + _pageSize, results.length)} (Trang $_currentPage / $totalPages)"*
- **Tương tác mượt mà:**
  - Khi gõ từ khóa (`_controller.onChanged`), chọn/bỏ môn học (`onSubjectChanged`), đổi sắp xếp (`onSortChanged`): Gán `_currentPage = 1`.
  - Khi chọn trang qua `GooglePaginationBar`:
    ```dart
    setState(() => _currentPage = page);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    ```
  - Khi `totalPages <= 1`: Ẩn thanh phân trang; chỉ hiện khi `totalPages > 1`.

---

## 3. Kịch Bản Kiểm Thử (Testing Plan)

### 3.1. Unit Test `GooglePaginationBar`: `test/widgets/google_pagination_bar_test.dart`
- Kiểm tra tạo dải số trang khi `totalPages <= 7` (ví dụ 5 trang: hiện đủ `1 2 3 4 5`).
- Kiểm tra tạo dải số trang khi `totalPages = 10`, `currentPage = 1` (hiện `1 2 3 4 5 ... 10 Tiếp >`).
- Kiểm tra tạo dải số trang khi `totalPages = 10`, `currentPage = 6` (hiện `< Trước 1 ... 5 6 7 ... 10 Tiếp >`).
- Kiểm tra click vào trang khác kích hoạt `onPageChanged`.
- Kiểm tra nút `< Trước` bị disable khi ở trang 1, nút `Tiếp >` bị disable khi ở trang cuối.

### 3.2. Widget Test `SearchScreen`: `test/screens/search_screen_test.dart`
- Kiểm tra khi danh sách có $> 15$ đề thi:
  - Chỉ hiển thị tối đa 15 card đề thi trên trang 1.
  - Hiển thị thanh `GooglePaginationBar` ở chân danh sách.
  - Hiển thị dòng đếm số lượng kết quả ở đầu danh sách.
- Kiểm tra khi bấm nút trang 2:
  - Danh sách chuyển sang hiển thị các đề thi tiếp theo (từ đề 16 đến 30).
- Kiểm tra khi gõ tìm kiếm hoặc lọc môn học:
  - Số trang tự động reset về trang 1.

---

## 4. Quy Trình Cam Kết & Tự Động Push (CI/CD)
- Sau khi viết mã và kiểm thử tự động đạt 100% PASS, tự động `git commit` và `git push` cho submodule `thi_nhanh` và kho chính `CODE` để GitHub Actions kích hoạt deploy tự động.
