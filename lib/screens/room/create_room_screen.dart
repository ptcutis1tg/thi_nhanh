import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';
import '../../shared/widgets/exam_card.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _examCodeController = TextEditingController();
  
  bool _requirePassword = false;
  bool _isLoadingPreview = false;
  bool _hasPreview = false;

  void _onExamCodeChanged(String value) {
    if (value.length >= 8 && value.startsWith('DT')) {
      setState(() {
        _isLoadingPreview = true;
        _hasPreview = false;
      });
      
      // Giả lập gọi API lấy thông tin đề thi
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _isLoadingPreview = false;
            _hasPreview = true; // Tìm thấy đề thi
          });
        }
      });
    } else {
      setState(() {
        _hasPreview = false;
      });
    }
  }

  void _createRoom() {
    // Điều hướng sang màn hình Waiting Room (Giáo viên)
    Navigator.pushReplacementNamed(context, '/teacher_waiting_room');
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    _examCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo Phòng Thi',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thiết lập phòng thi và gán đề thi để học sinh bắt đầu làm bài.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 32),

                // Card Cấu hình Phòng
                Container(
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
                      const Text(
                        '1. Thông tin Phòng thi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _roomNameController,
                        decoration: InputDecoration(
                          labelText: 'Tên Phòng Thi *',
                          hintText: 'Ví dụ: Kiểm tra 15p Lý lớp 12A1',
                          prefixIcon: const Icon(Icons.meeting_room_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Yêu cầu Mật khẩu (Bảo mật)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _requirePassword,
                            onChanged: (val) {
                              setState(() => _requirePassword = val);
                            },
                            activeColor: AppTheme.primary,
                          ),
                        ],
                      ),
                      if (_requirePassword) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu Phòng',
                            hintText: 'Nhập mật khẩu...',
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                      ],
                      
                      const Divider(height: 64, color: AppTheme.border, thickness: 1),
                      
                      const Text(
                        '2. Chọn Đề Thi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhập mã Đề thi (Bắt đầu bằng chữ DT) để hệ thống kiểm tra.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _examCodeController,
                        onChanged: _onExamCodeChanged,
                        decoration: InputDecoration(
                          labelText: 'Mã Đề Thi *',
                          hintText: 'DTxxxxxx',
                          prefixIcon: const Icon(Icons.qr_code_2),
                          suffixIcon: _isLoadingPreview 
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16, height: 16, 
                                    child: CircularProgressIndicator(strokeWidth: 2)
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Preview Box
                      if (_hasPreview)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Đã tìm thấy đề thi!',
                                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ExamCard(
                                  title: 'Đề thi thử THPT Quốc gia môn Toán 2024',
                                  authorName: 'Nguyễn Văn A',
                                  type: ExamCardType.exam,
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _hasPreview ? _createRoom : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Khởi tạo Phòng Thi (Tự động sinh mã PT)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
