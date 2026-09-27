# Thiết Kế Khắc Phục Lỗi RLS 42501 Khi Nộp Bài & Cơ Chế Nộp Bài Kiên Cường (Resilient Attempts Submission & RLS Fix)

## 1. Tổng quan
- **Vấn đề**: Khi học sinh nộp bài thi trên ứng dụng **Thi Nhanh** ở chế độ Khách (Guest) hoặc chưa có phiên đăng nhập Supabase, hệ thống gặp lỗi:
  `PostgrestException(message: new row violates row-level security policy for table "attempts", code: 42501, details: , hint: null)`
  khiến học sinh bị kẹt lại màn hình làm bài, không thể xem điểm và bị gián đoạn trải nghiệm thi cử.
- **Nguyên nhân**:
  1. Chính sách Row Level Security (RLS) trên bảng `public.attempts` của Supabase hiện tại chỉ cho phép người dùng có `user_id = auth.uid()` được phép `INSERT`. Khi thi ở chế độ Khách, `user_id = null` dẫn đến `null = auth.uid()` trả về false/null, kích hoạt lỗi RLS 42501.
  2. Ràng buộc `check (user_id is not null or guest_access_token_hash is not null)` không hỗ trợ trường hợp khách nộp bài trực tiếp với `guest_name`.
  3. Ứng dụng Flutter tại `TakingExamScreen._submitExam` chưa có cơ chế bắt lỗi kiên cường (fallback), khi gặp lỗi từ Supabase thì hiện thanh lỗi màu đỏ và chặn không cho chuyển sang màn hình xem kết quả.
- **Mục tiêu**:
  1. Cập nhật RLS Policy trên Supabase để cho phép cả người dùng đã đăng nhập lẫn khách (`user_id is null and guest_name is not null`) lưu bài làm.
  2. Triển khai cơ chế nộp bài kiên cường (Resilient Submit) phía Flutter: nếu Supabase bị lỗi (RLS, mạng, máy chủ), tự động lưu kết quả vào bộ nhớ máy (`SharedPreferences`) và cho phép học sinh vào ngay màn hình `/result` để xem điểm.
  3. Đảm bảo toàn bộ test suite vượt qua 100%.

---

## 2. Kiến trúc và Chi tiết Kỹ thuật

### 2.1. Migration Cơ sở dữ liệu Supabase (`supabase/migrations/202609270002_allow_guest_attempts_rls.sql`)
1. **Chính sách INSERT:**
   ```sql
   drop policy if exists "users create their own attempts" on public.attempts;
   create policy "allow creating attempts" on public.attempts
     for insert with check (
       (user_id is not null and user_id = auth.uid())
       or
       (user_id is null and (guest_name is not null or guest_access_token_hash is not null))
     );
   ```
2. **Chính sách UPDATE:**
   ```sql
   drop policy if exists "users update active own attempts" on public.attempts;
   create policy "allow updating active attempts" on public.attempts
     for update using (
       (user_id is not null and user_id = auth.uid() and status = 'in_progress')
       or
       (user_id is null and status = 'in_progress')
     );
   ```
3. **Chính sách SELECT:**
   ```sql
   drop policy if exists "users read their own attempts" on public.attempts;
   create policy "allow reading attempts" on public.attempts
     for select using (
       (user_id is not null and user_id = auth.uid())
       or
       (user_id is null)
       or
       (exists (select 1 from public.exams e where e.id = attempts.exam_id and e.teacher_id in (
         select t.id from public.teachers t where t.owner_user_id = auth.uid()
       )))
     );
   ```
4. **Nới lỏng ràng buộc `attempts_guest_token_required`:**
   ```sql
   alter table public.attempts drop constraint if exists attempts_guest_token_required;
   alter table public.attempts add constraint attempts_guest_token_required
     check (user_id is not null or guest_name is not null or guest_access_token_hash is not null);
   ```

### 2.2. Xử lý Client Flutter (`TakingExamScreen`)
1. Trong `_submitExam()` của [taking_exam_screen.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/exam/taking_exam_screen.dart):
   * Bọc khối lưu trữ Supabase trong khối `try/catch` có xử lý fallback:
     ```dart
     bool savedToCloud = false;
     try {
       if (widget.onSubmitAttempt != null) {
         await widget.onSubmitAttempt!(payload);
         savedToCloud = true;
       } else {
         final client = Supabase.instance.client;
         final user = client.auth.currentUser;
         payload['user_id'] = user?.id;
         if (user == null) {
           payload['guest_name'] = 'Học sinh';
         }
         if (widget.attemptId != null && widget.attemptId!.isNotEmpty) {
           await client.from('attempts').update({
             'status': 'submitted',
             'score': finalScore,
             'submitted_at': DateTime.now().toIso8601String(),
           }).eq('id', widget.attemptId!);
         } else {
           await client.from('attempts').insert(payload);
         }
         savedToCloud = true;
       }
     } catch (e) {
       debugPrint('Lỗi lưu bài làm lên Supabase, chuyển sang lưu trữ cục bộ: $e');
       // Lưu vào SharedPreferences để không mất dữ liệu của học sinh
       await _saveAttemptLocally(payload, finalScore, correctCount, wrongCount, skippedCount);
     }
     ```
   * Đánh dấu `_hasSubmitted = true;` và điều hướng sang `/result`.
   * Truyền thêm query parameter `offlineSaved=true` nếu `savedToCloud == false` để màn hình kết quả thông báo nhẹ cho người dùng.

### 2.3. Khởi tạo `AssessmentRepository` trong [exam_detail_screen.dart](file:///c:/Users/ADMINE/Desktop/CODE/thi_nhanh/lib/screens/exam/exam_detail_screen.dart)
   * Sử dụng `try { repo = context.read<AssessmentRepository>(); } catch (_) { repo = null; }` thay vì `context.read<AssessmentRepository?>()` để bắt đúng provider đã đăng ký trong `main.dart`.

---

## 3. Kế hoạch Kiểm thử (Test Suite)
- **Unit/Widget Test (`taking_exam_spam_submission_test.dart`):**
  - Viết test case giả lập `onSubmitAttempt` ném `PostgrestException(message: 'new row violates row-level security policy for table "attempts"', code: '42501')`.
  - Khẳng định màn hình nộp bài không bị kẹt, `_hasSubmitted` được thiết lập `true`, và điều hướng sang kết quả thành công.
- **Hệ thống Test Suite (`flutter test`):**
  - Đảm bảo toàn bộ 82+ bài kiểm thử hiện có vượt qua 100%.
