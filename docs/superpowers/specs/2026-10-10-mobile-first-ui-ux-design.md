# Thiết Kế Chi Tiết: Tối Ưu Hóa Toàn Diện Giao Diện Mobile (Full Mobile-First UI/UX Overhaul)

- **Ngày tạo:** 2026-10-10
- **Tác giả:** Antigravity AI & Pair Programmer
- **Trạng thái:** Chờ phê duyệt (Pending Approval)

---

## 1. Bối Cảnh & Mục Tiêu

### 1.1. Hiện trạng
- Ứng dụng Thi Nhanh đã hoàn thiện đầy đủ hệ thống tính năng nghiệp vụ cốt lõi: thi trực tiếp, chống gian lận, quản lý đề thi, lưu đề cộng đồng, lọc môn học, và phân hệ lịch sử 2 tab.
- Tuy nhiên, thanh điều hướng `TopNavBar` và một số màn hình chính (như `TakingExamScreen`, `SearchScreen`, `ExamDetailScreen`) được thiết kế chủ yếu theo bố cục desktop ngang (width > 800px).
- Trên màn hình điện thoại di động (chiều rộng 360px - 450px):
  - Thanh `TopNavBar` quá dày đặc khi nhồi nhét cả Logo, 4 menu chữ cuộn ngang, ô nhập PIN và Avatar trên cùng một dòng.
  - Màn hình làm bài thi có thanh sidebar câu hỏi chiếm nhiều diện tích hoặc khó thao tác bằng một tay.
  - Người dùng cần một trải nghiệm di động chuẩn mực (Mobile-First): thanh điều hướng Bottom Navigation Bar ở đáy màn hình, nút bấm lớn dễ thao tác bằng ngón tay cái (Thumb-Friendly), và header tinh gọn với nút quay lại rõ ràng.

### 1.2. Mục tiêu thiết kế
1. **Thanh điều hướng Mobile chuẩn mực:**
   - Khi ở trên thiết bị di động (`width < 600px`), thanh điều hướng chính được chuyển xuống đáy màn hình (**Mobile Bottom Navigation Bar**) với **5 tab thiết yếu bằng ICON** (không text để tối giản không gian).
   - **Quy tắc hiển thị rõ ràng:** Thanh Bottom Navigation Bar **chỉ hiển thị trên 5 tab chính** (`/home`, `/search`, `/teacher_exams`, `/create_room`, `/student/history`).
   - Khi chuyển sang bất kỳ màn hình nào ngoài 5 tab chính (làm bài thi, chi tiết đề, kết quả, tạo đề, xem phòng thi...): **ẩn hoàn toàn Bottom Bar**, thay vào đó ở góc trên cùng bên trái của Top Header hiển thị **nút mũi tên quay lại/thoát ra** (`Icons.arrow_back_rounded`).
2. **Trải nghiệm Làm bài thi Mobile (`TakingExamScreen`):**
   - Ẩn Bottom Bar. Thanh Quick-Strip số câu hỏi (1..N) cuộn ngang ở phía trên + nút mở Bottom Sheet xem lưới toàn bộ câu hỏi.
   - Thanh hành động đáy (Bottom Action Bar) cố định gồm Câu trước, Đánh dấu cờ, Câu sau / Nộp bài tối ưu cho ngón tay cái.
3. **Trải nghiệm Khám phá & Tìm kiếm Mobile (`SearchScreen` & `HomeScreen`):**
   - Hàng chip 8 môn học cuộn ngang 1 chạm nằm ngay dưới thanh tìm kiếm.
   - Nút mở bộ lọc nâng cao (Collapsible Filter Panel / Bottom Sheet) tinh gọn.
   - Thẻ đề thi responsive 1 cột, nút "Vào thi" và "Lưu đề" to rõ.
4. **Màn hình Chi tiết đề (`ExamDetailScreen`) & Quản lý:**
   - Chuyển thanh Navigator bên phải thành Bottom Sheet / Quick-Strip cuộn ngang.
   - 2 nút "Bắt đầu làm bài" & "Lưu đề" nổi bật, dễ bấm.
   - Danh sách câu hỏi xem trước hiển thị thoáng, không tràn công thức toán.

---

## 2. Kiến Trúc Điều Hướng & Giao Diện Mobile Shell

### 2.1. Phân loại Màn hình & Quy tắc Navigation Shell

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 5 TAB THIẾT YẾU (Core Tabs)                                                 │
│ 1. Trang chủ (/home)                                                        │
│ 2. Tìm đề (/search)                                                         │
│ 3. Quản lý đề (/teacher_exams)                                              │
│ 4. Tạo phòng (/create_room)                                                 │
│ 5. Lịch sử (/student/history)                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│ • Desktop (width >= 600px): Hiển thị TopNavBar chuẩn (Logo + Text Menu + Avatar)│
│ • Mobile (width < 600px):                                                   │
│   - Top Header: Logo tinh gọn + Nút PIN nhanh (mở dialog) + Avatar          │
│   - Bottom Navigation Bar: 5 Icon Tabs (Home, Search, Book, Plus, History) │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ MÀN HÌNH NGOÀI 5 TAB CHÍNH (Sub-Screens & Workspaces)                       │
│ • /taking_exam, /exam_detail, /result, /create_exam, /live_dashboard,       │
│   /student_waiting_room, /teacher_waiting_room, /profile, ...               │
├─────────────────────────────────────────────────────────────────────────────┤
│ • Mobile (width < 600px):                                                   │
│   - ẨN HOÀN TOÀN Bottom Navigation Bar.                                    │
│   - Top Header: Nút mũi tên quay lại/thoát ở góc trên cùng bên trái.       │
│   - Toàn bộ không gian màn hình dành riêng cho luồng tác vụ hiện tại.       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2. Chi tiết 5 Icon Tab trên Mobile Bottom Navigation Bar

| Thứ tự | Tab | Đường dẫn | Icon (Inactive / Active) | Ý nghĩa |
|---|---|---|---|---|
| 1 | **Trang chủ** | `/home` | `Icons.home_outlined` / `Icons.home_rounded` | Về trang chủ khám phá |
| 2 | **Tìm đề** | `/search` | `Icons.search_rounded` / `Icons.search` | Tìm kiếm & lọc đề thi |
| 3 | **Quản lý đề** | `/teacher_exams` | `Icons.menu_book_outlined` / `Icons.menu_book_rounded` | Kho đề của tôi & đề đã lưu |
| 4 | **Tạo phòng** | `/create_room` | `Icons.add_circle_outline_rounded` / `Icons.add_circle_rounded` | Tạo phòng thi trực tiếp |
| 5 | **Lịch sử** | `/student/history` | `Icons.history_rounded` / `Icons.manage_history_rounded` | Lịch sử đã làm & dở dang |

- **Thiết kế Visual Bottom Bar:**
  - Chiều cao: 60px - 64px + `MediaQuery.paddingOf(context).bottom` (an toàn trên iPhone & Android notch).
  - Màu nền: `AppTheme.surface` (trắng thuần `#FFFFFF` hoặc Dark Mode), viền trên mờ `Border(top: BorderSide(color: AppTheme.border))`, đổ bóng nhẹ `luminescenceShadow`.
  - Icon Active: Tô màu tím Stitch `#6557E8`, có nền capsule tím nhạt `#F4F3FE` bao quanh với viền bo tròn 12px hoặc chấm indicator phát sáng phía dưới.
  - Icon Inactive: Màu xám thanh lịch `#9CA3AF`, hiệu ứng chuyển tab mượt 200ms.

### 2.3. Top Header Tinh Gọn trên Mobile (`TopNavBar` & `MobileAppBar`)
- Chiều cao: 56px.
- **Trên 5 tab chính:**
  - Trái: Logo Icon vuông phát sáng bo góc (32x32px) + Tên "Thi Nhanh" (17px Bold).
  - Phải: Nút icon mã PIN phòng thi (khi nhấn mở `JoinRoomDialog`), Nút Avatar người dùng có viền tím (khi nhấn mở dropdown menu Cá nhân/Đăng xuất).
- **Trên màn hình phụ (Sub-Screens):**
  - Trái: Nút icon mũi tên tròn quay lại (`Icons.arrow_back_rounded`), kích thước chạm tối thiểu 44x44px. Khi bấm gọi `if (context.canPop()) context.pop() else context.go('/home')` (hoặc dialog xác nhận nếu đang làm bài).
  - Giữa: Tiêu đề màn hình rút gọn (VD: "Chi tiết đề thi", "Soạn đề kiểm tra").
  - Phải: Nút hành động phụ tùy màn hình (VD: Icon chia sẻ, Menu 3 chấm hoặc để trống).

---

## 3. Tối Ưu Hóa Chi Tiết Từng Màn Hình Trên Mobile

### 3.1. Màn hình Làm bài thi (`TakingExamScreen`)
1. **Header bài thi:**
   - Nút mũi tên thoát ở góc trái (mở dialog cảnh báo thoát).
   - Tên đề thi rút gọn giữa màn hình.
   - Timer Countdown dạng Pill nổi bật: font Fira Code, chữ màu tím hoặc đỏ khi < 5 phút, nhấp nháy nhẹ.
   - Cờ vi phạm: huy hiệu đỏ nhỏ nếu có vi phạm.
2. **Thanh ma trận câu hỏi Quick-Strip:**
   - Nằm ngay dưới Header, cuộn ngang mượt mà chứa các ô số câu hỏi 1, 2, ..., N (kích thước 34x34px).
   - Màu sắc trạng thái:
     - Xám nhạt: Chưa trả lời.
     - Xanh lá / Tím: Đã chọn đáp án.
     - Viền tím đậm: Câu đang làm hiện tại.
     - Góc có chấm vàng: Đã đánh dấu cờ cần xem lại.
   - Nút icon mở rộng ma trận (Grid Icon) ở cuối thanh: Khi bấm mở **Modal Bottom Sheet** hiển thị toàn bộ lưới câu hỏi (4-5 cột) để học sinh nắm toàn cảnh bài làm.
3. **Khu vực hiển thị câu hỏi & đáp án:**
   - Tiêu đề câu: "Câu X / N" (14px Bold tím).
   - Nội dung câu hỏi: Font Be Vietnam Pro 15px, hỗ trợ công thức toán học tự động xuống dòng và co giãn linh hoạt, không bị vỡ bố cục.
   - 4 Card lựa chọn đáp án (A, B, C, D):
     - Xếp dọc 1 cột, chiều cao tối thiểu 52px, padding 14px.
     - Khi chọn: Viền tím 2px, nền tím nhạt `#F4F3FE`, icon check phát sáng.
4. **Bottom Action Bar (Cố định ở đáy màn hình):**
   - Vùng an toàn đáy `SafeArea`.
   - Nút "Câu trước" (Icon mũi tên trái, xám).
   - Nút "Đánh dấu cờ" (Icon cờ, viền cam khi bật).
   - Nút "Câu sau" (Icon mũi tên phải, tím).
   - Nút "Nộp bài" (Nổi bật màu xanh lá/tím) khi ở câu cuối cùng hoặc bấm bất cứ lúc nào.

### 3.2. Màn hình Tìm kiếm & Khám phá (`SearchScreen`)
1. **Thanh tìm kiếm & Bộ lọc nhanh:**
   - Thanh Search Bar bo tròn `pillRadius` cố định ở đỉnh.
   - Nút icon "Bộ lọc" bên cạnh ô tìm kiếm: bấm mở **Collapsible Filter Panel** / **Bottom Sheet** để lọc khối lớp (10, 11, 12), thời lượng, sắp xếp.
   - Hàng chip 8 môn học cuộn ngang (Toán, Lý, Hóa, Sinh, Văn, Sử, Địa, Anh) với hiệu ứng chạm nảy, tự động lọc danh sách đề thi theo môn đã chọn.
2. **Danh sách thẻ đề thi (Exam Cards):**
   - Bố cục 1 cột tối ưu chiều rộng 100%.
   - Tiêu đề đề thi 2 dòng có `TextOverflow.ellipsis`.
   - Tags môn học, số lượng câu hỏi, thời gian làm bài, tác giả.
   - 2 nút hành động lớn:
     - Nút **"Vào thi"** (Màu tím chính, 1 chạm vào làm bài).
     - Nút **"Lưu đề"** / **"Đã lưu"** (Icon bookmark kèm text rõ ràng, phản hồi tức thì).

### 3.3. Màn hình Chi tiết đề thi (`ExamDetailScreen`)
1. **Header & Thông tin đề:**
   - Nút mũi tên quay lại góc trái.
   - Banner tóm tắt: Tên đề, môn học, thời lượng, số câu hỏi, lượt thi.
   - 2 nút bấm hành động lớn đặt ngang hoặc dọc: Nút "Bắt đầu làm bài" to rộng và Nút "Lưu đề về kho".
2. **Xem trước câu hỏi & Ma trận câu:**
   - Nút chuyển nhanh "Xem danh sách câu hỏi" dạng Bottom Sheet thay vì sidebar 300px desktop.
   - Toggle switch "Hiện/Ẩn đáp án & lời giải chi tiết".
   - Danh sách câu hỏi xem trước cuộn dọc mượt mà, highlight đáp án đúng màu xanh lá dịu mắt.

### 3.4. Trang chủ (`HomeScreen`)
1. **Hero Banner:**
   - Gradient tím Stitch sâu thẳm, tiêu đề ngắn gọn "Thi Nhanh — Nền tảng luyện thi thông minh".
   - Ô nhập mã PIN phòng thi nhanh 6 số bo tròn, nút mũi tên vào phòng 1 chạm.
2. **Khối môn học nhanh:**
   - Hàng 8 chips môn học cuộn ngang, chạm vào tự động điều hướng sang `/search?subject=...`.
3. **Thẻ tiến độ thông minh:**
   - Thẻ "BÀI THI CHƯA HOÀN TẤT" và "PHÒNG THI ĐANG DIỄN RA" xếp chồng dọc (Vertical Stack), padding 16px, nút bấm "Xem bài dở dang" dẫn thẳng vào Lịch sử.
4. **Lưới tính năng:**
   - Bố cục 2 cột mini cards trực quan (Tìm đề, Lịch sử, Thành tích, Bảng xếp hạng).

### 3.5. Màn hình Lịch sử (`StudentHistoryScreen`) & Quản lý đề (`TeacherExamsScreen`)
- Bộ chọn 2 Tab: Thiết kế flex co giãn chống tràn viền (`Flexible` + `TextOverflow.ellipsis`).
- Danh sách thẻ bài thi: Hiển thị đầy đủ trạng thái "Đã nộp" / "Đang làm dở" / "Đã hết hạn", các nút thao tác (Tiếp tục, Hủy, Nộp điểm, Xóa) bố trí vừa vặn ngón tay.

---

## 4. Kế Hoạch Triển Khai (Phases)

1. **Giai đoạn 1: Xây dựng `MobileBottomNavBar` & Tái cấu trúc Navigation Shell:**
   - Tạo widget `MobileBottomNavBar` chuẩn 5 icon tabs.
   - Tối ưu `TopNavBar` cho mobile (ẩn menu text ngang, hiện nút PIN + Avatar trên 5 tab chính, hiện nút mũi tên Back trên sub-screens).
   - Tự động ẩn `MobileBottomNavBar` khi không ở 5 tab chính.
2. **Giai đoạn 2: Tối ưu Màn hình Làm bài thi (`TakingExamScreen`):**
   - Xây dựng thanh Quick-Strip câu hỏi cuộn ngang + Bottom Sheet ma trận câu.
   - Thiết kế lại Bottom Action Bar cố định cho ngón tay cái.
   - Chống tràn công thức toán và tối ưu kích thước card đáp án.
3. **Giai đoạn 3: Tối ưu Tìm kiếm (`SearchScreen`) & Trang chủ (`HomeScreen`):**
   - Hàng chip môn học cuộn ngang + Collapsible Filter Panel.
   - Thẻ đề thi responsive 1 cột.
4. **Giai đoạn 4: Tối ưu Chi tiết đề (`ExamDetailScreen`) & Các màn hình Quản lý:**
   - Chuyển sidebar thành Bottom Sheet trên mobile, tối ưu kích thước nút bấm.
5. **Giai đoạn 5: Kiểm thử Toàn diện & Tự động Đẩy code:**
   - Viết widget tests kiểm tra hiển thị trên kích thước màn hình điện thoại (360x640, 390x844, 412x915).
   - Đảm bảo 100% test pass.
   - Cập nhật tài liệu kiến trúc & tự động commit/push.

---

## 5. Tiêu Chí Nghiệm Thu (Acceptance Criteria)

- [ ] Trên mobile (<600px), 5 tab chính (`/home`, `/search`, `/teacher_exams`, `/create_room`, `/student/history`) hiển thị `MobileBottomNavBar` 5 icon tab sạch sẽ và Top Header tinh gọn.
- [ ] Khi truy cập các màn hình ngoài 5 tab chính (`/taking_exam`, `/exam_detail`, v.v.), `MobileBottomNavBar` tự động ẩn, Top Header hiển thị nút mũi tên quay lại/thoát ở góc trên bên trái.
- [ ] Màn hình làm bài thi (`TakingExamScreen`) thao tác mượt mà bằng 1 tay: thanh số câu cuộn ngang ở trên, nút chuyển câu/nộp bài ở đáy cố định, không bị che khuất nội dung.
- [ ] Màn hình tìm kiếm (`SearchScreen`) có hàng chip môn học cuộn ngang và nút mở bộ lọc nâng cao.
- [ ] Không có bất kỳ lỗi tràn viền nào (`RenderFlex overflowed`) trên kích thước màn hình 360px.
- [ ] Toàn bộ test suite chạy đạt 100% PASS.
