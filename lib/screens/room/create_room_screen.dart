import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
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
  bool _isCreating = false;

  Map<String, dynamic>? _foundExam;

  Future<void> _onExamCodeChanged(String value) async {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.length >= 6) {
      setState(() {
        _isLoadingPreview = true;
        _hasPreview = false;
      });
      
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('exams')
            .select('id, code, title, subject, duration_minutes, teacher_id, teachers(display_name)')
            .ilike('code', trimmed)
            .maybeSingle();

        if (mounted) {
          if (res != null) {
            setState(() {
              _foundExam = res;
              _hasPreview = true;
              _isLoadingPreview = false;
            });
          } else {
            setState(() {
              _foundExam = null;
              _hasPreview = false;
              _isLoadingPreview = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _foundExam = null;
            _hasPreview = false;
            _isLoadingPreview = false;
          });
        }
      }
    } else {
      setState(() {
        _hasPreview = false;
        _foundExam = null;
      });
    }
  }

  Future<void> _createRoom() async {
    if (_foundExam == null) return;
    
    final roomName = _roomNameController.text.trim().isNotEmpty
        ? _roomNameController.text.trim()
        : 'Phòng thi ${_foundExam!['title']}';

    setState(() => _isCreating = true);

    try {
      final client = Supabase.instance.client;
      final randomCode = 'PT${(100000 + Random().nextInt(899999)).toString()}';
      
      // Get first teacher id
      String? teacherId = _foundExam!['teacher_id']?.toString();
      if (teacherId == null) {
        final teacherRes = await client.from('teachers').select('id').limit(1).maybeSingle();
        teacherId = teacherRes?['id']?.toString();
      }

      if (teacherId != null) {
        await client.from('rooms').insert({
          'code': randomCode,
          'exam_id': _foundExam!['id'],
          'teacher_id': teacherId,
          'name': roomName,
          'password_hash': _requirePassword && _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          'status': 'waiting',
          'max_participants': 50,
          'scheduled_start_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo phòng thi thành công với mã $randomCode!'), backgroundColor: AppTheme.success),
        );
        context.go('/teacher_waiting_room?code=$randomCode');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo phòng: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
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
    final teacherName = (_foundExam?['teachers'] as Map<String, dynamic>?)?['display_name'] ?? 'Giáo viên';

    return Scaffold(
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
                        decoration: const InputDecoration(
                          labelText: 'Tên Phòng Thi *',
                          hintText: 'Ví dụ: Kiểm tra 15p Lý lớp 12A1',
                          prefixIcon: Icon(Icons.meeting_room_outlined),
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
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu Phòng',
                            hintText: 'Nhập mật khẩu...',
                            prefixIcon: Icon(Icons.lock_outline),
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
                          hintText: 'DT100001 (hoặc DT100002)',
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
                      if (_hasPreview && _foundExam != null)
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
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đã tìm thấy đề thi trên Supabase!',
                                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ExamCard(
                                  title: _foundExam!['title'] ?? 'Đề thi',
                                  authorName: teacherName,
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
                          onPressed: (_hasPreview && !_isCreating) ? _createRoom : null,
                          icon: _isCreating
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            _isCreating ? 'Đang tạo phòng...' : 'Khởi tạo Phòng Thi (Tự động sinh mã PT)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
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

