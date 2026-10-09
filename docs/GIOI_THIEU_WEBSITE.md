# THI NHANH (ONTHI COMMUNITY) - NỀN TẢNG KIỂM TRA & THI TRỰC TUYẾN THỜI GIAN THỰC

> **Bản Giới Thiệu Sản Phẩm Công Nghệ Giáo Dục (EdTech Product Overview)**  
> **Tệp tài liệu:** `docs/GIOI_THIEU_WEBSITE.md`  
> **Phiên bản hệ thống:** 1.0.0+1 (Thiết kế hiện đại Stitch EdTech Modern UI/UX)

---

## 1. GIỚI THIỆU TỔNG QUAN

### 1.1. Tên sản phẩm & Ý tưởng hình thành
**Thi Nhanh** (OnThi Community) là nền tảng kiểm tra, thi thử và đánh giá năng lực học tập trực tuyến thời gian thực dành cho giáo viên và học sinh. Trong bối cảnh chuyển đổi số giáo dục đang diễn ra mạnh mẽ, việc tổ chức các kỳ thi trắc nghiệm, kiểm tra định kỳ hay thi thử thường gặp nhiều thách thức: giáo viên tốn nhiều thời gian soạn đề và chấm bài, học sinh thiếu môi trường thi thử trực quan, còn các hệ thống trực tuyến thông thường lại dễ bị gian lận và thiếu sự tương tác thời gian thực.

**Thi Nhanh** ra đời với sứ mệnh đơn giản hóa toàn bộ quy trình kiểm tra đánh giá: từ khâu soạn đề thi tích hợp công thức toán học phức tạp, tạo phòng thi tức thì qua mã PIN / mã QR, đến việc giám sát trực tiếp thời gian thực và chấm điểm tự động ngay khi học sinh nộp bài.

### 1.2. Mục tiêu và Vấn đề sản phẩm giải quyết
- **Xóa bỏ rào cản soạn đề công thức phức tạp:** Cung cấp bộ công cụ soạn thảo công thức Toán học & Ký hiệu khoa học trực quan (Visual Math Compiler & LaTeX), cho phép giáo viên nhập nhanh câu hỏi từ bản thô mà không cần cài đặt phần mềm cầu kỳ.
- **Tổ chức phòng thi thời gian thực nhanh chóng:** Tạo phòng thi chỉ trong vài giây với mã PIN chuẩn hóa (dạng `PTxxxxxx`) hoặc mã QR trực quan. Học sinh có thể tham gia ngay tức thì từ máy tính, tablet hoặc điện thoại thông minh.
- **Bảo mật học thuật & Chống gian lận đa tầng:** Giải quyết triệt để tình trạng học sinh gian lận khi thi online thông qua cơ chế giám sát rời tab 4 cấp độ, xáo trộn đề tất định cho từng thí sinh và khóa sao chép nội dung câu hỏi.
- **Chấm điểm tự động & Phân tích tức thì:** Bảng điểm được xử lý ngay lập tức theo thang điểm 10. Giáo viên sở hữu bảng giám sát trực tiếp (Live Dashboard) để theo dõi tiến độ từng học sinh, trong khi học sinh nhận được báo cáo chi tiết kèm lời giải và tính năng ôn luyện câu sai chuyên biệt.

---

## 2. ĐỐI TƯỢNG SỬ DỤNG VÀ VAI TRÒ

Hệ thống **Thi Nhanh** được thiết kế tối ưu hóa trải nghiệm người dùng cho hai nhóm đối tượng chính trong môi trường giáo dục:

### 2.1. Giáo viên (Người ra đề & Tổ chức phòng thi)
- **Vai trò:** Người quản lý kho đề thi, khởi tạo các phòng kiểm tra trực tuyến, điều phối buổi thi thời gian thực và đánh giá kết quả học tập của học sinh.
- **Nhu cầu giải quyết:** Tiết kiệm thời gian ra đề và chấm bài; công khai đề thi hoặc mở phòng thi trực tiếp có bảo mật; giám sát tính trung thực của học sinh trong giờ thi; nắm bắt chính xác những kiến thức học sinh còn yếu để điều chỉnh phương pháp giảng dạy.

### 2.2. Học sinh (Thí sinh làm bài & Người tự rèn luyện)
- **Vai trò:** Người tham gia làm bài thi trong các phòng thi do giáo viên tổ chức, hoặc tự ôn luyện thông qua kho đề thi công khai trên hệ thống.
- **Nhu cầu giải quyết:** Trải nghiệm làm bài thi trực quan, mượt mà trên mọi thiết bị; xem kết quả và lời giải chi tiết ngay sau khi hoàn nộp bài; tự ôn luyện lại những câu hỏi làm sai; theo dõi thứ hạng trên bảng xếp hạng thời gian thực để tăng động lực học tập.

> **Lưu ý đặc biệt:** Nền tảng hỗ trợ cả hai hình thức truy cập: **Đăng nhập bằng tài khoản chính thức** (Email/Password hoặc Google) để lưu trữ lịch sử học tập lâu dài, và **Chế độ Khách (Guest Mode)** giúp học sinh tham gia làm bài thi tức thì chỉ bằng cách nhập tên mà không bắt buộc tạo tài khoản.

---

## 3. CÁC TÍNH NĂNG NỔI BẬT THEO NHÓM CHỨC NĂNG

### 3.1. Phân hệ Xác thực & Quản lý Tài khoản Cá nhân
- **Đăng nhập đa phương thức:** Hỗ trợ đăng nhập qua Email/Mật khẩu, xác minh mã OTP khôi phục mật khẩu, và đăng nhập 1 chạm bằng Google Sign-In.
- **Chế độ Khách (Guest Mode):** Cho phép học sinh tham gia phòng thi tức thì mà không bị rào cản bởi thủ tục đăng ký tài khoản.
- **Hồ sơ cá nhân & Thống kê tổng quan:** Hiển thị thông tin cá nhân, cập nhật avatar (từ thiết bị, URL hoặc ảnh đại diện mặc định), kèm bảng chỉ số thống kê số lượt thi đã hoàn thành, điểm trung bình, số đề thi đã tạo và số phòng thi đã mở.
- **Chuyển đổi không gian làm việc con nhộng (Workspace Switcher):** Cho phép người dùng chuyển đổi linh hoạt giữa hai chế độ `🎓 Học tập & Thi thử` (dành cho học sinh) và `📝 Soạn đề & Quản lý` (dành cho giáo viên) ngay tại giao diện chính.

### 3.2. Phân hệ Soạn đề & Quản lý Đề thi (Giáo viên)
- **Bộ soạn thảo công thức Toán học trực quan (Visual Math Editor):** Tích hợp thanh công cụ ký hiệu khoa học (căn thức, phân số, tích phân, mũ, ký hiệu Hy Lạp...) cùng bộ biên dịch `VisualMathCompiler` giúp giáo viên nhập công thức dễ dàng kèm tính năng xem trước trực tiếp (Live LaTeX Preview).
- **Trình nhập nhanh hàng loạt (Bulk Import Parser):** Hỗ trợ chuyển đổi nhanh dữ liệu văn bản thô chứa câu hỏi và các phương án thành đề thi chuẩn chỉ trong một thao tác.
- **Quản lý kho đề thi đa trạng thái:** Phân loại đề thi theo 3 tab con nhộng (`Tất cả`, `Đề nháp`, `Đã xuất bản`). Giáo viên có thể xem chi tiết, chỉnh sửa bản nháp, xóa đề hoặc công khai đề thi để toàn bộ học sinh có thể tiếp cận.
- **Xem trước góc nhìn học sinh (Student Exam Preview):** Hỗ trợ giáo viên kiểm tra chính xác giao diện hiển thị của đề thi dưới góc nhìn học sinh trước khi xuất bản hoặc mở phòng thi.

### 3.3. Phân hệ Tổ chức & Giám sát Phòng thi Trực tiếp (Realtime Ecosystem)
- **Tạo phòng thi linh hoạt:** Khởi tạo phòng thi với mã PIN chuẩn hóa 6 chữ số (dạng `PTxxxxxx`), cài đặt thời gian bắt đầu/kết thúc, mật khẩu bảo vệ phòng thi và bật/tắt các tính năng chống gian lận.
- **Chia sẻ phòng thi qua mã QR:** Tự động tạo mã QR phát sáng kèm nút sao chép mã PIN một chạm để giáo viên dễ dàng chia sẻ lên màn hình chiếu hoặc nhóm lớp.
- **Phòng chờ thời gian thực & Đồng bộ đếm ngược:** Học sinh vào phòng chờ sẽ được hiển thị danh sách thời gian thực. Khi giáo viên nhấn "Bắt đầu", hiệu ứng đếm ngược đồng bộ 3-2-1 (`CountdownOverlayWidget`) sẽ kích hoạt toàn màn hình trước khi chuyển vào đề thi.
- **Bảng giám sát trực tiếp (Live Dashboard):** Giao diện sẫm màu Indigo chuyên nghiệp giúp giáo viên theo dõi tiến độ nộp bài của từng học sinh, nhận phát hiện cờ đỏ vi phạm thời gian thực (`🚩 X vi phạm`) và thực hiện thao tác **Thu bài cưỡng chế (`⛔ Thu bài`)** đối với học sinh vi phạm quy chế.

### 3.4. Phân hệ Làm bài thi & Chống Gian Lận Đa Tầng (Học sinh)
- **Giao diện làm bài hiện đại:** Thanh trạng thái cố định chứa đồng hồ đếm ngược Fira Code font, bảng Sidebar lưới câu hỏi 3 màu trực quan (Màu tím nhạt: câu đang chọn, Màu tím đậm: câu đã trả lời, Màu cam: câu nghi vấn/đánh dấu).
- **Bộ máy chống gian lận đa tầng (Anti-Cheat Engine):**
  1. *Giám sát rời tab/ứng dụng 4 cấp độ:* Bắt sự kiện chuyển window/chuyển tab. Cảnh báo lần 1 đến lần 3, và tự động thu bài cưỡng chế ở lần thứ 4.
  2. *Khóa sao chép câu hỏi (`SelectionContainer.disabled`):* Chặn hoàn toàn thao tác bôi đen, copy nội dung câu hỏi hoặc bấm chuột phải.
  3. *Xáo trộn đề thi tất định (`ExamShuffleHelper`):* Mỗi học sinh nhận được một thứ tự câu hỏi và thứ tự phương án trả lời được xáo trộn ngẫu nhiên dựa trên seed riêng, đảm bảo học sinh ngồi cạnh nhau không thể chép bài.

### 3.5. Phân hệ Chấm điểm, Báo cáo & Ôn luyện Sau Thi
- **Chấm điểm tự động chuẩn xác:** Ngay khi nộp bài, hệ thống tính toán điểm số chính xác trên thang điểm 10 Fira Code cỡ lớn kèm phân tích số câu Đúng / Sai / Bỏ qua.
- **Xem chi tiết đáp án & Lời giải:** Học sinh có thể xem lại từng câu hỏi, đáp án đã chọn, đáp án đúng và lời giải chi tiết do giáo viên cung cấp.
- **Luyện tập câu sai (Wrong Questions Practice):** Tự động gom tất cả các câu hỏi học sinh làm sai trong bài thi thành một bài luyện tập riêng biệt để học sinh khắc phục lỗ hổng kiến thức.
- **Bảng xếp hạng Vinh danh (Realtime Leaderboard):** Hiển thị bục vinh danh Top 1-2-3 (Huy chương Vàng, Bạc, Đồng) và danh sách thứ hạng thí sinh được cập nhật thời gian thực.
- **Lịch sử làm bài & Phân tích học tập:** Lưu trữ danh sách bài thi đã làm, hỗ trợ lọc theo môn học, thời gian và phân trang kiểu Google.

---

## 4. TRẢI NGHIỆM DÀNH CHO GIÁO VIÊN

Một buổi tổ chức thi của giáo viên trên **Thi Nhanh** diễn ra vô cùng đơn giản, khoa học và chuyên nghiệp:

1. **Soạn đề thi nhanh chóng:** Giáo viên truy cập phân hệ `Soạn đề & Quản lý`, nhập tên đề thi, chọn môn học và thời gian làm bài. Sử dụng thanh công cụ **Visual Math Editor** để nhập các công thức Toán/Lý/Hóa phức tạp hoặc dán câu hỏi thô qua công cụ nhập hàng loạt.
2. **Kiểm tra & Xuất bản:** Dùng tính năng *Xem trước góc nhìn học sinh* để rà soát lỗi chính tả và định dạng công thức, sau đó nhấn xuất bản đề thi.
3. **Mở phòng thi & Chia sẻ:** Tạo phòng thi trực tiếp, cài đặt bảo mật (mật khẩu phòng, kích hoạt chống gian lận). Hệ thống sinh mã PIN `PTxxxxxx` và mã QR. Giáo viên chiếu mã QR lên bảng hoặc gửi mã PIN cho học sinh.
4. **Giám sát phòng thi thời gian thực:** Tại giao diện **Live Dashboard**, giáo viên quan sát danh sách thí sinh đã tham gia, phát lệnh bắt đầu thi đồng bộ 3-2-1. Trong quá trình làm bài, hệ thống sẽ tự động giơ cờ đỏ cảnh báo nếu học sinh nào cố tình rời tab hoặc mở tài liệu khác. Giáo viên có quyền thu bài ngay lập tức nếu cần thiết.
5. **Đánh giá & Thống kê:** Khi buổi thi kết thúc, giáo viên xem ngay bảng thống kê điểm trung bình, tỷ lệ hoàn thành và danh sách các câu hỏi có tỷ lệ làm sai cao nhất để lên kế hoạch ôn tập lại cho học sinh.

---

## 5. TRẢI NGHIỆM DÀNH CHO HỌC SINH

Học sinh tiếp cận việc học và thi trên **Thi Nhanh** với tinh thần chủ động, hào hứng và không gặp rào cản kỹ thuật:

1. **Vào phòng thi tức thì:** Học sinh truy cập Trang chủ, nhập mã PIN phòng thi (ví dụ: `892341` - hệ thống tự chuẩn hóa thành `PT892341`) hoặc chọn chế độ Khách nhập tên.
2. **Chờ thi đồng bộ:** Học sinh xuất hiện trong phòng chờ trực tuyến và trải nghiệm hiệu ứng đếm ngược 3-2-1 sinh động khi giáo viên phát lệnh bắt đầu.
3. **Làm bài thi tập trung:** Giao diện thi tối giản, hiển thị công thức toán rõ nét. Đồng hồ đếm ngược giúp học sinh phân bổ thời gian. Bảng điều hướng Sidebar giúp học sinh dễ dàng theo dõi những câu chưa làm hoặc đánh dấu câu nghi vấn để xem lại.
4. **Nộp bài & Nhận kết quả ngay:** Sau khi nộp bài, học sinh biết ngay điểm số thang điểm 10, độ chính xác (%) và thứ hạng của mình trên Bảng xếp hạng.
5. **Ôn luyện củng cố:** Học sinh mở mục *Luyện tập câu sai* để làm lại các câu chưa đúng và đọc lời giải chi tiết để rút kinh nghiệm cho các lần thi sau.

---

## 6. QUY TRÌNH HOẠT ĐỘNG TỔNG THỂ CỦA HỆ THỐNG

Dưới đây là hành trình sử dụng tổng thể từ khi người dùng bắt đầu đến khi hoàn thành một bài thi trên hệ thống:

```
[Đăng nhập / Vào chế độ Khách] 
             │
             ├──► (Giáo viên) ──► [Soạn đề thi & Ký hiệu Math] ──► [Tạo Phòng thi & Mã QR/PIN] ──► [Bắt đầu & Giám sát Live Dashboard]
             │                                                                                              │
             └──► (Học sinh)  ──► [Nhập mã PIN PTxxxxxx / Quét QR] ──► [Phòng chờ & Đếm ngược 3-2-1] ──────┼──► [Làm bài & Chống gian lận 4 cấp]
                                                                                                            │
                                                                                                            ▼
                                                                                            [Nộp bài & Chấm điểm tự động]
                                                                                                            │
                                                                                                            ├──► [Xem Bảng xếp hạng Realtime]
                                                                                                            ├──► [Xem Đáp án & Lời giải chi tiết]
                                                                                                            └──► [Luyện tập các câu trả lời sai]
```

---

## 7. CÔNG NGHỆ CỐT LÕI ĐƯỢC SỬ DỤNG

Hệ thống **Thi Nhanh** được xây dựng trên nền tảng công nghệ hiện đại, đảm bảo hiệu năng cao, tốc độ phản hồi nhanh và khả năng tương thích đa nền tảng:

- **Frontend Application:** Framework **Flutter** (Dart 3.x), vận hành mượt mà trên trình duyệt Web, máy tính Windows/macOS và thiết bị di động Android/iOS.
- **Backend Service & Database:** **Supabase Cloud** dựa trên cơ sở dữ liệu **PostgreSQL 15+**, tích hợp cơ chế bảo mật phân quyền Row Level Security (RLS) và hệ thống Stored Procedures (RPC).
- **Thời gian thực (Realtime Engine):** Kết nối **WebSockets (Supabase Realtime Broadcast & Presence)** phục vụ việc truyền tải danh sách thí sinh phòng chờ, trạng thái nộp bài và tín hiệu vi phạm thời gian thực.
- **Điều hướng & Quản lý Trạng thái:** Kiến trúc **GoRouter** kết hợp bộ chuyển cảnh mượt mà, cùng mô hình **Provider** và **Repository Pattern** giúp ứng dụng hoạt động ổn định.
- **Trình bày Ký hiệu & Công thức:** Thư viện `flutter_math_fork` xử lý công thức LaTeX kết hợp bộ biên dịch `VisualMathCompiler` độc quyền của hệ thống.
- **Tầng Phục hồi Kỹ thuật (Resilience Layer):** Tích hợp `SupabaseRetryHelper` tự động bắt và xử lý lỗi lệch đồng hồ server (`PGRST303`), lỗi hết hạn phiên làm việc (`PGRST301`) và ngắt kết nối mạng ngẫu nhiên với cơ chế tự động thử lại (exponential backoff).

---

## 8. ĐIỂM NỔI BẬT VÀ GIÁ TRỊ THỰC TIỄN

1. **Thẩm mỹ Hiện đại Stitch EdTech Modern:** Giao diện sử dụng bảng màu tím violet cao cấp (`#6557E8`), kết hợp font Be Vietnam Pro thanh lịch cho văn bản và font Fira Code cho các thông số kỹ thuật (mã PIN, điểm số, đồng hồ đếm ngược). Hiệu ứng đổ bóng quang học (Luminescence Shadows) và các tab con nhộng mang lại cảm giác vô cùng chuyên nghiệp.
2. **Trải nghiệm Người dùng Tối ưu (UX First):** Nhập mã PIN thông minh (tự động chuyển `892341` thành `PT892341`), nút sao chép 1 chạm, thông báo lỗi thân thiện bằng tiếng Việt (triệt tiêu mã lỗi kỹ thuật thô).
3. **Bảo vệ Tính Trung thực Học thuật:** Bộ máy chống gian lận đa tầng giúp giáo viên hoàn toàn yên tâm khi tổ chức các bài kiểm tra trực tuyến.
4. **Giá trị Giáo dục Thực tiễn:** Không chỉ là công cụ chấm điểm, **Thi Nhanh** giúp học sinh tự nhận biết lỗ hổng kiến thức thông qua tính năng *Luyện tập câu sai* và phân tích chi tiết kết quả.

---

## 9. TÌNH TRẠNG PHÁT TRIỂN HỆ THỐNG

Để đảm bảo tính minh bạch và chính xác, dưới đây là phân định rõ ràng giữa các tính năng **đã hoàn thiện 100%** và các tính năng **đang nằm trong lộ trình phát triển**:

### 9.1. Các tính năng ĐÃ HOÀN THIỆN & HOẠT ĐỘNG THỰC TẾ (100% Verified)
- ✅ Đăng nhập / Đăng ký qua Email, Google Sign-In và Chế độ Khách (Guest Mode).
- ✅ Trang chủ hiện đại với Hero Banner, 8 môn học phổ thông và bộ chuyển đổi không gian làm việc con nhộng.
- ✅ Trình soạn thảo đề thi tích hợp Visual Math Compiler, live LaTeX preview và công cụ dán câu hỏi hàng loạt (Bulk Import).
- ✅ Quản lý đề thi (Tất cả / Đề nháp / Đã công khai), xem trước bài thi góc nhìn học sinh.
- ✅ Tạo phòng thi bảo mật, mã QR chia sẻ và tự động sinh mã PIN `PTxxxxxx`.
- ✅ Phòng chờ thời gian thực với màn hình đếm ngược 3-2-1 đồng bộ trước khi phát lệnh thi.
- ✅ Màn hình làm bài thi tích hợp bộ máy chống gian lận 4 cấp độ cảnh báo, khóa copy câu hỏi và xáo trộn đề tất định.
- ✅ Chấm điểm tự động thang điểm 10, hiển thị lời giải chi tiết và tính năng *Luyện tập câu sai*.
- ✅ Bảng giám sát thời gian thực Live Dashboard dành cho giáo viên (theo dõi cờ đỏ vi phạm và thu bài cưỡng chế).
- ✅ Bảng xếp hạng vinh danh Realtime Top 1-2-3 (Podium).
- ✅ Hồ sơ cá nhân, đổi avatar và xem lịch sử làm bài thi.
- ✅ Tầng phục hồi kết nối `SupabaseRetryHelper` và Developer Mode theo dõi log ứng dụng.

### 9.2. Các tính năng ĐANG PHÁT TRIỂN & HẠN CHẾ HIỆN TẠI (In Roadmap)
- 🔄 **Quản lý Lớp học cố định (Classroom Management):** Hiện tại hệ thống tổ chức thi theo từng *Phòng thi trực tiếp* hoặc *Đề thi công khai*. Chức năng quản lý danh sách học sinh theo từng Lớp học cố định và gán bài tập về nhà theo lớp đang được thiết kế.
- 🔄 **Xuất báo cáo PDF/Word & Excel:** Chức năng xuất đề thi ra tệp PDF/Word (.docx) để in ấn giấy và xuất bảng điểm phòng thi ra tệp Excel (.xlsx) đang nằm trong lộ trình hoàn thiện ở phiên bản tiếp theo.
- 🔄 **Chế độ Thi Offline hoàn toàn (Offline Exam Cache):** Hiện tại hệ thống tự động thử lại khi mất mạng tạm thời; chế độ tải toàn bộ gói câu hỏi về máy để thi offline 100% khi không có mạng đang được nghiên cứu tích hợp SQLite.

---

## 10. KẾT LUẬN

**Thi Nhanh (OnThi Community)** là một giải pháp công nghệ giáo dục toàn diện, hiện đại và giàu tính thực tiễn. Với sự kết hợp hoàn hảo giữa giao diện người dùng thẩm mỹ cao, công cụ soạn thảo công thức toán học mạnh mẽ, hệ thống chống gian lận đa tầng đáng tin cậy và khả năng tương tác thời gian thực, **Thi Nhanh** không chỉ giúp giáo viên giải phóng sức lao động trong việc kiểm tra đánh giá, mà còn mang đến cho học sinh một môi trường thi thử trực quan, công bằng và đầy hứng khởi.

Dự án sở hữu nền tảng kiến trúc vững chắc, chất lượng kiểm thử tự động đạt độ tin cậy cao và hoàn toàn sẵn sàng để tiếp tục mở rộng phát triển thành một hệ sinh thái EdTech hàng đầu.
