# Design Specification: Chuẩn Hóa Phân Hệ "Bài Đang Làm" — Quản Lý Tab Lịch Sử & Xử Lý Bài Thi Hết Hạn

**Ngày lập:** 2026-10-09  
**Trạng thái:** Đã phê duyệt qua Brainstorming / Grill-Me  
**Phạm vi áp dụng:** `thi_nhanh` Flutter App (Student Learning Flow & Profile/History)

---

## 1. Bối cảnh & Vấn đề Cần Khắc Phục

1. **Hiện tượng kẹt bài thi cũ:**
   - Tại `HomeScreen`, thẻ "Bài Đang Làm" truy vấn các bài thi có `status = 'in_progress'` mà không kiểm tra hạn chót làm bài (`expires_at`).
   - Nếu học sinh thoát trình duyệt khi đang làm bài dở, bài thi đó vẫn giữ trạng thái `in_progress` trong cơ sở dữ liệu Supabase hàng tuần/tháng.
   - Thẻ tại trang chủ liên tục hiển thị "BÀI THI CHƯA HOÀN TẤT - Bạn đang có bài thi chưa nộp".
2. **Hiện tượng lỗi khi bấm "Tiếp tục làm bài":**
   - Khi bấm vào bài thi đã hết hạn, hệ thống chuyển sang `/taking_exam?attemptId=...`.
   - Tại `TakingExamScreen`, hệ thống phát hiện thời gian làm bài đã âm/hết hạn và lập tức kích hoạt nộp bài tự động hoặc bị từ chối với ngoại lệ `Attempt is closed` / `PostgrestException`, gây giật lag và trải nghiệm tiêu cực.
3. **Thiếu không gian quản lý bài thi dở dang:**
   - Học sinh không có nơi nào để xem danh sách toàn bộ các bài mình đang làm dở, không biết bài nào còn hạn, bài nào đã quá giờ, và không có nút hủy bỏ bài làm bị kẹt.

---

## 2. Mục tiêu Thiết kế

1. **Minh bạch hóa lịch sử:** Thêm tab **"Chưa hoàn thành"** tại màn hình Lịch sử làm bài (`/student/history`) song song với tab **"Đã hoàn thành"**, hiển thị đầy đủ các bài thi dở dang, hạn làm bài và trạng thái.
2. **Điều hướng thông minh từ Trang chủ:** Thẻ "Bài Đang Làm" tại `HomeScreen` hiển thị số lượng bài dở dang và tên bài gần nhất. Khi bấm, điều hướng thẳng sang `/student/history?tab=in_progress` để học sinh chủ động quản lý.
3. **Trao quyền kiểm soát cho học sinh:**
   - Với bài **còn hạn**: Cho phép `[Tiếp tục làm bài]` hoặc `[Hủy bài]`.
   - Với bài **đã hết hạn**: Hiển thị nhãn *"Đã hết hạn"*, cho phép `[Nộp bài chấm điểm]` hoặc `[Xóa khỏi danh sách]`.
4. **Phòng vệ an toàn tại phòng thi:** `TakingExamScreen` xử lý êm đẹp các bài thi hết hạn, không phát sinh lỗi ngoại lệ thô, cung cấp lựa chọn nộp bài hoặc quay về màn hình lịch sử.

---

## 3. Kiến Trúc & Luồng Dữ Liệu (Architecture & Flow)

```
[HomeScreen]
  │
  ├── Thẻ "Bài Đang Làm"
  │     ├── Có bài dở dang: Hiển thị Badge số lượng + Tên đề gần nhất + Nút "Xem bài dở dang"
  │     │     └── Bấm ──► context.go('/student/history?tab=in_progress')
  │     └── Không có bài: Hiển thị "Tiến độ học tập sạch sẽ" + Nút "Khám phá đề thi"
  │           └── Bấm ──► context.go('/search')
  │
[StudentHistoryScreen (/student/history?tab=in_progress)]
  │
  ├── Tab 1: "Đã hoàn thành (N)"
  │     └── Danh sách các bài thi đã nộp, có điểm số, xem chi tiết & ôn tập câu hỏi sai
  │
  └── Tab 2: "Chưa hoàn thành (M)" (Active nếu URL có ?tab=in_progress)
        ├── Phân loại từng bài thi:
        │     ├── [Trường hợp 1: Còn hạn (now < expires_at)]
        │     │     ├── Trạng thái: "Đang làm dở" (Màu cam) + Đếm ngược / phút còn lại
        │     │     ├── Nút "Tiếp tục làm bài" ──► /taking_exam?attemptId=...
        │     │     └── Nút "Hủy bài" ──► Xác nhận Dialog ──► Cập nhật 'cancelled' / xóa bản ghi
        │     └── [Trường hợp 2: Hết hạn (now >= expires_at)]
        │           ├── Trạng thái: "Đã hết hạn làm bài" (Màu xám/đỏ)
        │           ├── Nút "Nộp để chấm điểm" ──► Gọi submit_attempt RPC ──► /result
        │           └── Nút "Xóa bài" ──► Xác nhận Dialog ──► Cập nhật 'cancelled' / xóa bản ghi
        └── Trạng thái rỗng: Icon minh họa + Nút "Tìm đề luyện tập ngay"
```

---

## 4. Chi Tiết Kỹ Thuật

### 4.1. Core Services & Models ([`profile_service.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/core/services/profile_service.dart))

1. **`StudentTestHistoryData` Model:**
   ```dart
   class StudentTestHistoryData {
     final String id;
     final String title;
     final String subject;
     final String subjectIcon;
     final String date;
     final String score;
     final double scoreValue;
     final String status; // 'in_progress', 'submitted', 'expired', 'cancelled'
     final DateTime? submittedAt;
     final DateTime? startedAt;
     final DateTime? expiresAt;
     final String? roomId;
     final String? roomCode;
     final int? durationSeconds;
     final bool isLiveRoom;
     final bool resultReleased;

     bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
     // ...
   }
   ```
2. **`StudentProfileData` Model:**
   ```dart
   class StudentProfileData {
     final int completedTestsCount;
     final double averageScore;
     final int streakDays;
     final List<double> chartValues;
     final List<String> chartLabels;
     final double highestScore;
     final Duration totalTimeSpent;
     final List<AchievementItemData> achievements;
     final List<StudentTestHistoryData> recentTests;
     final List<StudentTestHistoryData> inProgressTests; // Mới: danh sách bài dở dang
     // ...
   }
   ```
3. **`fetchStudentData`:**
   - Truy vấn toàn bộ attempts của học sinh.
   - Lọc bài dở dang: `status == 'in_progress'` hoặc `(status == 'expired' && score == null)`.
   - Điền đầy đủ vào `inProgressTests`.
4. **`fetchActiveAttempt`:**
   - Bổ sung điều kiện `expires_at > now()` để đảm bảo bài trả về cho Home card luôn là bài còn hiệu lực.
   - Trả về `inProgressCount` để thẻ hiển thị đúng số lượng.
5. **`cancelOrDeleteAttempt(String attemptId)`:**
   - Thực thi cập nhật status thành `'cancelled'` trên Supabase và dọn dẹp các cache cục bộ tương ứng.

### 4.2. Giao diện Lịch sử làm bài ([`student_history_screen.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/student/student_history_screen.dart))

1. Nhận tham số `initialTab`:
   ```dart
   class StudentHistoryScreen extends StatefulWidget {
     const StudentHistoryScreen({
       super.key,
       this.testData,
       this.initialTab, // 'completed' hoặc 'in_progress'
     });
     final StudentProfileData? testData;
     final String? initialTab;
   ```
2. Thêm thanh Tab con nhộng chuyển đổi:
   - "Đã hoàn thành (${recentTests.length})"
   - "Chưa hoàn thành (${inProgressTests.length})"
3. Thiết kế card bài dở dang:
   - Thẻ bo góc `cardRadius`, viền màu amber nếu còn giờ, viền xám nếu hết giờ.
   - Thể hiện rõ thời gian bắt đầu làm, thời lượng dự kiến, trạng thái hết hạn.
   - Nút hành động tương ứng:
     - Còn giờ: `Tiếp tục làm` (ElevatedButton) & `Hủy bài` (OutlinedButton).
     - Hết giờ: `Nộp bài chấm điểm` (ElevatedButton vàng/cam) & `Xóa bài` (OutlinedButton đỏ).

### 4.3. Thẻ Trang Chủ ([`home_screen.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/home/home_screen.dart))

1. Thẻ "Bài Đang Làm" hiển thị số lượng bài dở dang thực tế (`_inProgressCount` hoặc `_activeAttemptId != null`).
2. Nhãn hiển thị: "Có N bài thi chưa hoàn tất" kèm tên đề thi dở dang gần nhất.
3. Nút hành động: "Xem bài dở dang" -> gọi `context.go('/student/history?tab=in_progress')`.

### 4.4. Phòng vệ tại Phòng Thi ([`taking_exam_screen.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/exam/taking_exam_screen.dart))

1. Khi nạp bài thi mà phát hiện `attempt.status == 'expired'` hoặc `expiresAt <= now()`:
   - Không throw exception thô.
   - Hiển thị AlertDialog giải thích nhẹ nhàng:
     - "Bài thi này đã hết thời gian làm bài quy định."
     - Nút 1: "Nộp bài & Xem kết quả" (gọi `_submitExam()`).
     - Nút 2: "Về lịch sử bài làm" (`context.go('/student/history?tab=in_progress')`).

### 4.5. Định tuyến Router ([`main.dart`](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/main.dart))

- Cấu hình route `/student/history`:
  ```dart
  GoRoute(
    path: '/student/history',
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: StudentHistoryScreen(
        initialTab: state.uri.queryParameters['tab'],
      ),
    ),
  ),
  ```

---

## 5. Chiến lược Kiểm thử (Testing Strategy)

1. **Unit & Widget Test:**
   - Test `StudentProfileData` khởi tạo và phân loại đúng `inProgressTests`.
   - Test `StudentHistoryScreen` khi nhận `initialTab: 'in_progress'` thì mở đúng tab "Chưa hoàn thành".
   - Test hiển thị đúng nút "Tiếp tục làm bài", "Hủy bài", "Nộp để chấm điểm" tùy theo `isExpired`.
   - Test `HomeScreen` điều hướng sang `/student/history?tab=in_progress` khi bấm thẻ "Bài Đang Làm".
   - Test `TakingExamScreen` hiển thị dialog êm đẹp khi attempt đã hết hạn.
2. **Kiểm thử hồi quy toàn diện:** Đảm bảo toàn bộ 194+ bài test hiện tại tiếp tục PASS 100%.
