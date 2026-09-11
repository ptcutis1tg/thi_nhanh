# Design: Hybrid Exam Storage (CQRS) & 8 Subjects Exam Seed

## 1. Context & Objectives
The Thi Nhanh platform currently relies on a traditional 3NF relational model (`exams` -> `questions` -> `question_options`). While suitable for authoring, this requires complex multi-table `JOIN` queries during high-concurrency exam participation sessions. Furthermore, the database currently only has a few sample exams.

### Key Objectives:
1. **Optimal Storage Architecture**: Implement a high-performance **Hybrid CQRS (Command Query Responsibility Segregation)** pattern in PostgreSQL / Supabase, combining 3NF authoring with automated JSONB snapshots for instant (<5ms) sub-second exam retrieval.
2. **Anti-Cheat & Security**: Ensure the public exam snapshot delivered to students during active test taking omits `is_correct` answers and explanations, protecting integrity against browser DevTools inspection.
3. **Comprehensive Subject Catalog**: Generate 3 high-quality exams for each of the 8 core subjects (Toán học, Vật lý, Hóa học, Sinh học, Tiếng Anh, Lịch sử, Địa lý, Tin học), totaling 24 exams, 240 questions, and 960 options with accurate subject knowledge.

---

## 2. Storage Strategy Evaluation & Architecture

### Comparative Analysis:
- **Normalized 3NF (Current)**:
  - *Pros*: Granular updates, foreign key constraints, easy question bank search.
  - *Cons*: High database load and latency under peak concurrency (e.g. 50+ students opening an exam room at the exact same second).
- **Pure Document (JSONB only)**:
  - *Pros*: Single row fetch, no joins.
  - *Cons*: Destroys relational integrity; making edits to a single question requires updating large JSON blobs; hampers question-level analytics.
- **Hybrid CQRS Snapshot (Chosen)**:
  - *Authoring (Write path)*: Teachers manage individual questions and options in normalized tables (`questions`, `question_options`).
  - *Materialization (Event trigger)*: A PostgreSQL trigger automatically synchronizes a clean `snapshot_payload jsonb` on `public.exams` whenever questions or options are inserted, updated, or deleted.
  - *Delivery (Read path)*: When a participant joins or loads the exam, the client can fetch `snapshot_payload` in a single indexed query.

### Schema Changes:
1. **Column Addition**:
   ```sql
   alter table public.exams add column if not exists snapshot_payload jsonb;
   create index if not exists idx_exams_snapshot on public.exams using gin (snapshot_payload);
   ```
2. **Snapshot Builder Function**:
   `public.fn_rebuild_exam_snapshot(p_exam_id uuid)` builds:
   ```json
   {
     "id": "uuid",
     "code": "DT100001",
     "title": "Đề thi...",
     "subject": "Toán học",
     "duration_minutes": 45,
     "total_questions": 10,
     "questions": [
       {
         "id": "uuid",
         "position": 1,
         "body": "Đạo hàm của...",
         "points": 1.0,
         "options": [
           {"id": "uuid", "position": 1, "body": "x^2"},
           {"id": "uuid", "position": 2, "body": "3x^2"}
         ]
       }
     ]
   }
   ```
   *(Notice: `is_correct` is excluded from the student-facing snapshot).*

3. **Auto-sync Trigger**:
   Triggers on `public.questions` and `public.question_options` on `AFTER INSERT OR UPDATE OR DELETE` execute `fn_trigger_sync_exam_snapshot()` to update `exams.snapshot_payload` automatically.

---

## 3. Catalog of 24 Exams (8 Subjects x 3 Exams)

Each exam consists of 10 multiple-choice questions with 4 options (A, B, C, D) and exactly 1 correct answer verified for academic accuracy.

### 1. Toán học
- **Đề 1 (DT010101)**: Khảo sát hàm số & Ứng dụng đạo hàm (Cực trị, tiệm cận, tính đơn điệu, GTLN-GTNN).
- **Đề 2 (DT010102)**: Nguyên hàm, Tích phân & Hình học không gian Oxyz (Tọa độ điểm, mặt phẳng, mặt cầu).
- **Đề 3 (DT010103)**: Mũ - Logarit, Số phức & Xác suất tổ hợp (Phương trình logarit, môđun số phức, hoán vị).

### 2. Vật lý
- **Đề 1 (DT010201)**: Dao động cơ học & Sóng cơ (Con lắc lò xo, con lắc đơn, giao thoa sóng, sóng dừng).
- **Đề 2 (DT010202)**: Dòng điện xoay chiều & Mạch RLC (Hệ số công suất, cộng hưởng điện, máy biến áp).
- **Đề 3 (DT010203)**: Sóng ánh sáng, Lượng tử ánh sáng & Hạt nhân (Giao thoa Young, quang điện, phóng xạ).

### 3. Hóa học
- **Đề 1 (DT010301)**: Hóa học hữu cơ - Este, Lipit & Cacbohiđrat (Phản ứng xà phòng hóa, glucozơ, saccarozơ).
- **Đề 2 (DT010302)**: Kim loại kiềm, kiềm thổ, Nhôm & Hợp chất (Nước cứng, phản ứng nhiệt nhôm, ăn mòn).
- **Đề 3 (DT010303)**: Tổng hợp Hóa học vô cơ & hữu cơ (Polime, peptit, sắt, crom, nhận biết hóa chất).

### 4. Sinh học
- **Đề 1 (DT010401)**: Cơ chế di truyền & Biến dị cấp phân tử (Nhân đôi ADN, phiên mã, dịch mã, đột biến gen).
- **Đề 2 (DT010402)**: Quy luật di truyền & Di truyền học người (Mendel, liên kết gen, hoán vị gen, phả hệ).
- **Đề 3 (DT010403)**: Di truyền quần thể, Tiến hóa & Sinh thái học (Định luật Hardy-Weinberg, chuỗi thức ăn).

### 5. Tiếng Anh
- **Đề 1 (DT010501)**: English Grammar Mastery (Tenses, Conditionals, Reported Speech, Relative Clauses).
- **Đề 2 (DT010502)**: Vocabulary & Collocations (Idioms, phrasal verbs, word formations).
- **Đề 3 (DT010503)**: Error Identification & Sentence Transformations (Cấu trúc đồng nghĩa, sửa lỗi sai).

### 6. Lịch sử
- **Đề 1 (DT010601)**: Lịch sử Việt Nam (1930 - 1954) (Phong trào Xô Viết Nghệ Tĩnh, CMT8 1945, Điện Biên Phủ).
- **Đề 2 (DT010602)**: Lịch sử Việt Nam (1954 - 1975) (Đường lối kháng chiến, Tết Mậu Thân 1968, Chiến dịch HCM 1975).
- **Đề 3 (DT010603)**: Lịch sử thế giới hiện đại (1945 - nay) (Liên Hợp Quốc, Chiến tranh Lạnh, ASEAN, Xu thế toàn cầu hóa).

### 7. Địa lý
- **Đề 1 (DT010701)**: Địa lý tự nhiên Việt Nam (Vị trí địa lý, địa hình nhiệt đới ẩm gió mùa, sông ngòi).
- **Đề 2 (DT010702)**: Địa lý dân cư & Các ngành kinh tế (Chuyển dịch cơ cấu kinh tế, nông nghiệp, công nghiệp, du lịch).
- **Đề 3 (DT010703)**: Địa lý các vùng kinh tế trọng điểm (Đồng bằng sông Hồng, Tây Nguyên, Đồng bằng sông Cửu Long).

### 8. Tin học
- **Đề 1 (DT010801)**: Cơ sở lập trình & Thuật toán cơ bản (Biến, kiểu dữ liệu, vòng lặp, đệ quy, tìm kiếm nhị phân).
- **Đề 2 (DT010802)**: Cơ sở dữ liệu quan hệ & Ngôn ngữ SQL (Khóa chính, khóa ngoại, SELECT, JOIN, GROUP BY).
- **Đề 3 (DT010803)**: Mạng máy tính & An toàn bảo mật thông tin (Địa chỉ IP, mô hình OSI/TCP-IP, mã hóa, tường lửa).

---

## 4. Implementation Deliverables
1. **Migration Script**: `supabase/migrations/202609110001_hybrid_storage_and_8_subjects_seed.sql`
   - DDL for `snapshot_payload jsonb` column and triggers.
   - DML inserts for all 24 exams, 240 questions, and 960 question options with standard unique UUIDs and codes.
   - Immediate execution of `fn_rebuild_exam_snapshot` to hydrate snapshots for all 24 exams.
2. **Seed Synchronization**: Update `supabase/seed.sql` so newly provisioned environments or local test databases instantly possess the 24 exams.

---

## 5. Verification Plan
1. **SQL Integrity Check**: Validate that all 24 exams have valid codes (`DT010101`..`DT010803`), valid teacher foreign keys, exactly 10 questions per exam, and exactly 4 options per question with 1 correct option.
2. **Trigger Verification**: Verify that adding/updating a question immediately triggers an update to `exams.snapshot_payload`.
3. **Application Regression**: Run `flutter test` to ensure existing repository parsers and screens function seamlessly.
