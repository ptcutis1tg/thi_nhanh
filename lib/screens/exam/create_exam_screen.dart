import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final TextEditingController _examNameController = TextEditingController();
  String? _selectedSubject;
  
  int _activeQuestionIndex = 0;
  final List<String> _questions = ['Câu hỏi số 1', 'Câu hỏi số 2', 'Câu hỏi số 3'];

  @override
  void dispose() {
    _examNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainCanvas()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: const Row(
              children: [
                Text(
                  'DANH SÁCH CÂU HỎI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          // Question List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isActive = index == _activeQuestionIndex;
                return InkWell(
                  onTap: () => setState(() => _activeQuestionIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
                      border: Border.all(
                        color: isActive ? AppTheme.primaryLight : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.primary : AppTheme.border,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _questions[index],
                                style: TextStyle(
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  color: isActive ? AppTheme.primary : AppTheme.textMain,
                                ),
                              ),
                              const Text(
                                'Trắc nghiệm',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Add Question Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _questions.add('Câu hỏi số ${_questions.length + 1}');
                  _activeQuestionIndex = _questions.length - 1;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm câu hỏi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppTheme.border, style: BorderStyle.solid),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCanvas() {
    return Container(
      color: AppTheme.background,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32).copyWith(bottom: 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // General Settings (NEW)
                      const Text(
                        'Thông tin chung',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _examNameController,
                              decoration: InputDecoration(
                                hintText: 'Nhập tên đề thi (vd: Đề thi thử Toán 12...)',
                                labelText: 'Tên Đề Thi *',
                                fillColor: AppTheme.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.border),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Môn học',
                                fillColor: AppTheme.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.border),
                                ),
                              ),
                              hint: const Text('Chọn môn'),
                              value: _selectedSubject,
                              items: const [
                                DropdownMenuItem(value: 'Toán', child: Text('Toán')),
                                DropdownMenuItem(value: 'Vật lý', child: Text('Vật lý')),
                                DropdownMenuItem(value: 'Hóa học', child: Text('Hóa học')),
                                DropdownMenuItem(value: 'Tiếng Anh', child: Text('Tiếng Anh')),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedSubject = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 64, color: AppTheme.border, thickness: 2),

                      // Header for Question
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      'CÂU ${_activeQuestionIndex + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Chỉnh sửa nội dung',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const Divider(height: 48, color: AppTheme.border),
                      
                      // Question Input
                      const Text(
                        'Nội dung câu hỏi *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Nhập nội dung câu hỏi tại đây...',
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Answers
                      const Text(
                        'Các đáp án (Chọn 1 đáp án đúng)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildAnswerOption('A', true),
                      const SizedBox(height: 12),
                      _buildAnswerOption('B', false),
                      const SizedBox(height: 12),
                      _buildAnswerOption('C', false),
                      const SizedBox(height: 12),
                      _buildAnswerOption('D', false),
                      
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Thêm lựa chọn'),
                      ),
                      
                      const Divider(height: 64, color: AppTheme.border),
                      const Text(
                        'Cài đặt bổ sung (Tùy chọn)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                fillColor: AppTheme.background,
                              ),
                              hint: const Text('Mức độ khó...'),
                              items: const [
                                DropdownMenuItem(value: 'easy', child: Text('Dễ')),
                                DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                                DropdownMenuItem(value: 'hard', child: Text('Khó')),
                              ],
                              onChanged: (val) {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Điểm số (VD: 10)',
                                fillColor: AppTheme.background,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: const Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đã lưu tự động lúc 10:42 AM',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: const Text('Lưu nháp'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Text('Lưu & Khởi tạo Đề'),
                        label: const Icon(Icons.arrow_forward, size: 18),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(String label, bool isCorrect) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(color: isCorrect ? AppTheme.primary : AppTheme.border, width: isCorrect ? 2 : 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Radio<bool>(
            value: true,
            groupValue: isCorrect,
            onChanged: (val) {},
            activeColor: AppTheme.primary,
          ),
          Text(
            '$label.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Nhập đáp án...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
