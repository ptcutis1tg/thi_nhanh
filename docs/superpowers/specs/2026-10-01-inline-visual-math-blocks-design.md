# Thiết Kế Chi Tiết: Trình Soạn Thảo Công Thức Toán Trực Quan Dạng Block (Inline Visual Math Block Editor)

- **Ngày tạo**: 2026-10-01
- **Trạng thái**: Đã phê duyệt (Approved)
- **Tác giả**: Antigravity Pair Programming Agent

---

## 1. Mục tiêu & Bối cảnh

Khi giáo viên biên soạn câu hỏi chứa công thức toán/lý/hóa trong màn hình `CreateExamScreen`, việc phải gõ mã lệnh thô LaTeX (ví dụ: `\frac{\square}{\square}`, `\sqrt{\square}`, `\int_{a}^{b}`) gây khó khăn và tốn thời gian.

**Mục tiêu chính**:
- Khi giáo viên click vào các nút công thức toán trên thanh công cụ `ScientificBottomToolbar` (hoặc chèn trực tiếp), tại vùng nhập nội dung câu hỏi sẽ hiển thị ngay **khối toán học trực quan (Visual Math Block)** với hình dáng công thức thực tế (phân số có gạch ngang, căn thức có dấu căn, tích phân có dấu tích phân...).
- Mỗi phần tử biến đổi đều là một **ô trống tương tác `[ ]`** có viền nét đứt nhẹ, cho phép click trực tiếp vào ô để gõ nội dung hoặc dùng phím Tab chuyển ô.
- Hỗ trợ chế độ **2-trong-1**: Cho phép chuyển đổi mượt mà giữa chế độ **Khối trực quan (Visual Blocks)** và **Mã nguồn LaTeX (Raw Code)**.
- Tự động biên dịch hai chiều (bi-directional sync) ra chuẩn LaTeX để lưu trữ vào trường `question.body`, đảm bảo học sinh và giáo viên luôn xem đề thi hiển thị sắc nét bằng engine KaTeX / MathView sẵn có.

---

## 2. Kiến trúc dữ liệu & Mô hình khối toán (Data Architecture & Block Models)

### 2.1 Cấu trúc đoạn nội dung (`QuestionContentSegment`)

Nội dung câu hỏi được cấu tạo từ chuỗi các đoạn:
```dart
sealed class QuestionContentSegment {
  String toLatex();
}

class TextContentSegment extends QuestionContentSegment {
  String text;
  TextContentSegment(this.text);
  @override
  String toLatex() => text;
}

class MathBlockSegment extends QuestionContentSegment {
  final String id;
  final MathBlockType type;
  final Map<String, String> slots; // slotKey -> text value

  MathBlockSegment({
    required this.id,
    required this.type,
    Map<String, String>? slots,
  }) : slots = slots ?? {};

  @override
  String toLatex() => type.compileToLatex(slots);
}
```

### 2.2 Các loại khối toán học (`MathBlockType`)

| Loại khối (`MathBlockType`) | Nhãn UI | Các ô trống (`slots`) | Cú pháp LaTeX biên dịch |
|---|---|---|---|
| `fraction` | Phân số $\frac{\square}{\square}$ | `num` (tử số), `den` (mẫu số) | `\frac{${slots['num']}}{${slots['den']}}` |
| `sqrt` | Căn bậc hai $\sqrt{\square}$ | `radicand` (biểu thức dưới căn) | `\sqrt{${slots['radicand']}}` |
| `nroot` | Căn bậc n $\sqrt[n]{\square}$ | `index` (bậc n), `radicand` (biểu thức) | `\sqrt[${slots['index']}]{${slots['radicand']}}` |
| `power` | Số mũ / Lũy thừa $x^\square$ | `base` (cơ số), `exp` (số mũ) | `{${slots['base']}}^{${slots['exp']}}` |
| `subscript` | Chỉ số dưới $x_\square$ | `base` (biến), `sub` (chỉ số) | `{${slots['base']} \atop }_{${slots['sub']}}` hoặc `{${slots['base']}}_{${slots['sub']}}` |
| `integral` | Tích phân $\int_a^b$ | `lower` (cận dưới), `upper` (cận trên), `expr` (hàm số) | `\int_{${slots['lower']}}^{${slots['upper']}} {${slots['expr']}} \, dx` |
| `limit` | Giới hạn $\lim_{x \to a}$ | `to` (tiến tới), `expr` (hàm số) | `\lim_{x \to ${slots['to']}} {${slots['expr']}}` |
| `logarithm` | Logarit $\log_a(b)$ | `base` (cơ số), `arg` (biểu thức) | `\log_{${slots['base']}}({${slots['arg']}})` |
| `summation` | Tổng $\sum_{i=1}^n$ | `from` (cận dưới), `to` (cận trên), `expr` (biểu thức) | `\sum_{${slots['from']}}^{${slots['to']}} {${slots['expr']}}` |
| `vector` | Vectơ $\vec{v}$ | `name` (tên vectơ) | `\vec{${slots['name']}}` |
| `angle` | Góc $\widehat{ABC}$ | `name` (tên góc) | `\widehat{${slots['name']}}` |

---

## 3. Thiết kế Giao diện Khối trực quan & Trải nghiệm Ô trống (Visual Slots UI/UX)

### 3.1 Giao diện từng ô trống `VisualSlotInput`
- **Kích thước**: Tự động co giãn theo độ dài nội dung (tối thiểu 36px chiều rộng).
- **Trạng thái bình thường**:
  - Viền nét đứt (dashed border) 1.5px màu `AppTheme.primary.withOpacity(0.4)`.
  - Nền xám xanh nhạt `AppTheme.surface`.
  - Placeholder mờ nhạt (ví dụ: `tử`, `mẫu`, `x`, `n`, `a`, `b`).
- **Trạng thái Focus (khi click vào)**:
  - Viền nét liền đậm 2px `AppTheme.primary`, hiệu ứng phát sáng nhẹ.
  - Con trỏ gõ trực tiếp trong ô.
  - Hỗ trợ nhấn phím **Tab** hoặc phím **Mũi tên** để di chuyển tuần tự qua ô trống tiếp theo trong cùng khối hoặc sang khối kế tiếp.

### 3.2 Khối toán học 2D (`VisualMathBlockWidget`)
- **Phân số**:
  - Hiển thị theo phương dọc: Ô tử số ở trên $\to$ đường kẻ ngang 2px màu đen $\to$ ô mẫu số ở dưới.
- **Căn thức**:
  - Biểu tượng dấu căn $\sqrt{}$ bao phủ phía trên ô biểu thức, với ô bậc căn nhỏ ở góc trên bên trái (đối với căn bậc n).
- **Lũy thừa / Chỉ số**:
  - Ô cơ số ở dòng chính, ô số mũ thu nhỏ nằm lệch lên góc trên, hoặc ô chỉ số nằm lệch góc dưới.
- **Tích phân**:
  - Ký hiệu $\int$ lớn, hai ô cận nhỏ xếp lệch trên/dưới, theo sau là ô hàm số và nhãn `dx`.
- **Thao tác nhanh trên khối**:
  - Nút biểu tượng `✕` nhỏ mờ khi rê chuột vào khối để xóa nhanh khối nếu không cần nữa.

### 3.3 Tích hợp với `ScientificBottomToolbar`
- Khi người dùng click vào bất kỳ nút công thức toán học nào ở thanh công cụ dưới đáy màn hình:
  - Hệ thống chèn một `MathBlockSegment` tương ứng vào danh sách phân đoạn tại vị trí con trỏ hiện tại.
  - Tự động kích hoạt trạng thái focus vào ô trống đầu tiên của khối đó để giáo viên có thể gõ ngay tức thì mà không cần thêm thao tác nào.

---

## 4. Chế độ 2-trong-1 & Đồng bộ hóa Dữ liệu

### 4.1 Thanh chuyển đổi chế độ
Đặt ngay trên vùng nhập câu hỏi:
- **[🎨 Khối trực quan (Visual Blocks)]** *(Mặc định)*: Hiển thị văn bản xen kẽ các khối toán học 2D tương tác.
- **[📝 Mã nguồn LaTeX (Raw Code)]**: Hiển thị `TextFormField` chứa toàn bộ mã LaTeX hoàn chỉnh cho giáo viên thích gõ code trực tiếp hoặc paste đề thi từ nguồn khác.

### 4.2 Đồng bộ hai chiều (Bi-directional Sync)
- **Từ Khối trực quan $\to$ LaTeX**:
  - Mỗi khi một ô trống thay đổi giá trị hoặc một đoạn văn bản được gõ:
  - `question.body = segments.map((s) => s.toLatex()).join(' ')`.
  - Live Preview (`LatexMathView`) tự động cập nhật kết quả tức thì.
- **Từ LaTeX $\to$ Khối trực quan**:
  - Bộ phân tích `LatexBlockParser` quét các biểu thức LaTeX thông dụng (`\frac{...}{...}`, `\sqrt{...}`, `\sqrt[...]{...}`, `^{...}`, `_{...}`, `\int_{...}^{...}`, `\lim_{...}`, v.v.) và chuyển đổi ngược lại thành các `MathBlockSegment` có ô trống chứa sẵn giá trị tương ứng.
  - Những đoạn văn bản thường hoặc LaTeX không thuộc danh mục block được giữ nguyên dưới dạng `TextContentSegment`.

---

## 5. Chiến lược Kiểm thử & Đảm bảo Chất lượng

1. **Unit Test**:
   - `test/utils/visual_math_compiler_test.dart`:
     - Kiểm thử biên dịch phân số, căn thức, lũy thừa, tích phân, giới hạn ra đúng chuỗi LaTeX.
     - Kiểm thử phân tích ngược (parsing) chuỗi LaTeX thành danh sách các khối toán và ô trống.
     - Kiểm thử cập nhật giá trị slot mà không gây lỗi hoặc mất mát dữ liệu.
2. **Widget Test**:
   - `test/widgets/visual_math_editor_test.dart`:
     - Kiểm thử render đúng các ô trống `[ ]` của phân số, căn thức.
     - Kiểm thử người dùng gõ vào ô trống và kiểm tra `question.body` sinh ra mã LaTeX chính xác.
     - Kiểm thử chuyển đổi qua lại giữa chế độ Khối trực quan và Mã nguồn LaTeX.
     - Kiểm thử Live Preview phản hồi theo thời gian thực.
3. **End-to-End Test**:
   - Tạo một câu hỏi chứa cả văn bản và công thức phân số + căn thức, lưu bản nháp và kiểm tra dữ liệu lưu trên Supabase giữ nguyên định dạng LaTeX chuẩn.
