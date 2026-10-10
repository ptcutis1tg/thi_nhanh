import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/teacher_exam_repository.dart';
import '../../core/repositories/saved_exam_repository.dart';
import '../../core/repositories/room_repository.dart';
import '../../core/theme/app_theme.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _roomNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();
  final _capacityController = TextEditingController(text: '40');

  List<TeacherExamSummary> _myExams = [];
  List<TeacherExamSummary> _savedExams = [];
  String _examSourceTab = 'all'; // 'all' | 'mine' | 'saved'
  TeacherExamSummary? _selectedExam;
  bool _requirePassword = false;
  bool _isLoadingExams = true;
  bool _isCreating = false;

  int _maxParticipants = 40;
  String _selectedSubject = 'Tất cả';
  bool _shuffleQuestions = true;
  bool _enableAntiCheat = true;
  bool _allowReview = true;

  final List<int> _quickCapacities = [30, 40, 50, 100];

  @override
  void initState() {
    super.initState();
    _loadCreatedExams();
  }

  Future<void> _loadCreatedExams() async {
    setState(() => _isLoadingExams = true);
    try {
      TeacherExamRepository? teacherRepo;
      try {
        teacherRepo = context.read<TeacherExamRepository>();
      } catch (_) {}

      SavedExamRepository? savedRepo;
      try {
        savedRepo = context.read<SavedExamRepository?>();
      } catch (_) {}

      final mySummaries = teacherRepo != null ? await teacherRepo.summaries() : <TeacherExamSummary>[];
      final savedSummaries = savedRepo != null ? await savedRepo.getSavedExams() : <TeacherExamSummary>[];

      if (mounted) {
        setState(() {
          _myExams = mySummaries.where((exam) => exam.status == 'published').toList();
          _savedExams = savedSummaries.where((exam) => exam.status == 'published').toList();
          _isLoadingExams = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingExams = false);
    }
  }

  bool _isSavedExam(String examId) => _savedExams.any((e) => e.id == examId);

  List<TeacherExamSummary> get _allAvailableExams {
    final seenIds = <String>{};
    final list = <TeacherExamSummary>[];
    for (final e in _myExams) {
      if (seenIds.add(e.id)) list.add(e);
    }
    for (final e in _savedExams) {
      if (seenIds.add(e.id)) list.add(e);
    }
    return list;
  }

  List<TeacherExamSummary> get _filteredExams {
    List<TeacherExamSummary> pool;
    if (_examSourceTab == 'mine') {
      pool = _myExams;
    } else if (_examSourceTab == 'saved') {
      pool = _savedExams;
    } else {
      pool = _allAvailableExams;
    }

    final query = _searchController.text.trim().toLowerCase();
    return pool.where((exam) {
      final matchesSearch = query.isEmpty ||
          exam.title.toLowerCase().contains(query) ||
          exam.subject.toLowerCase().contains(query);
      final matchesSubject = _selectedSubject == 'Tất cả' ||
          exam.subject.toLowerCase() == _selectedSubject.toLowerCase();
      return matchesSearch && matchesSubject;
    }).toList();
  }

  List<String> get _availableSubjects {
    final subjects = {'Tất cả'};
    for (final exam in _allAvailableExams) {
      if (exam.subject.trim().isNotEmpty) {
        subjects.add(exam.subject.trim());
      }
    }
    return subjects.toList();
  }

  Future<void> _createRoom() async {
    if (_roomNameController.text.trim().isEmpty || _selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy đặt tên phòng và chọn đề thi.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_maxParticipants < 5 || _maxParticipants > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sĩ số tối đa phải từ 5 đến 500 thí sinh.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final room = await context.read<RoomRepository>().create(
            examId: _selectedExam!.id,
            name: _roomNameController.text.trim(),
            password: _requirePassword ? _passwordController.text : null,
            maxParticipants: _maxParticipants,
          );
      if (mounted) context.go('/teacher_waiting_room?roomId=${room.id}');
    } catch (error) {
      if (mounted) {
        String msg = error.toString();
        if (msg.contains('Chỉ có thể tạo phòng từ đề đã xuất bản của bạn')) {
          msg = 'Đề này được lưu từ cộng đồng. Hãy chạy file migration SQL trên Supabase để cấp quyền mở phòng từ đề đã lưu!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tạo phòng: $msg'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
          ),
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
    _searchController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Widget _buildSourceTab(String key, String label, int count) {
    final isSelected = _examSourceTab == key;
    return InkWell(
      onTap: () => setState(() => _examSourceTab = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textMain,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tạo phòng thi',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Khởi tạo phòng thi trực tuyến, thiết lập sĩ số và mời học sinh vào phòng thi.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: AppTheme.luminescenceShadow,
                    ),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Thông tin cơ bản
                            const Row(
                              children: [
                                Icon(Icons.meeting_room_outlined, color: AppTheme.primary),
                                SizedBox(width: 8),
                              Text(
                                '1. Thông tin phòng thi',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _roomNameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên phòng thi *',
                              hintText: 'Ví dụ: Kiểm tra 15 phút - Lớp 12A1',
                              prefixIcon: Icon(Icons.edit_note_outlined),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sĩ số tối đa
                          const Text(
                            'Sĩ số tối đa',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Giới hạn số lượng thí sinh có thể kết nối vào phòng.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ..._quickCapacities.map((cap) {
                                final isSelected = _maxParticipants == cap;
                                return ChoiceChip(
                                  label: Text('$cap thí sinh'),
                                  selected: isSelected,
                                  selectedColor: AppTheme.primary,
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primary : AppTheme.border,
                                    ),
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        _maxParticipants = cap;
                                        _capacityController.text = cap.toString();
                                      });
                                    }
                                  },
                                );
                              }),
                              SizedBox(
                                width: 140,
                                height: 42,
                                child: TextField(
                                  controller: _capacityController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    suffixText: 'thí sinh',
                                    hintText: 'Tùy chỉnh',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (val) {
                                    final parsed = int.tryParse(val.trim());
                                    if (parsed != null && parsed >= 1) {
                                      setState(() => _maxParticipants = parsed);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Yêu cầu mật khẩu phòng thi'),
                            subtitle: const Text('Thí sinh cần nhập đúng mật khẩu để được vào phòng.'),
                            value: _requirePassword,
                            onChanged: (value) => setState(() => _requirePassword = value),
                          ),
                          if (_requirePassword) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Mật khẩu phòng',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                          ],

                          const Divider(height: 48),

                          // 2. Chọn đề thi
                          const Row(
                            children: [
                              Icon(Icons.menu_book_outlined, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text(
                                '2. Chọn đề thi mở phòng',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bạn có thể chọn đề thi do mình khởi tạo hoặc đề thi đã lưu từ cộng đồng.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 18),

                          if (_isLoadingExams)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_myExams.isEmpty && _savedExams.isEmpty)
                            _EmptyExamState(onCreateExam: () => context.go('/teacher_exams'))
                          else ...[
                            // Tabs nguồn đề: Tất cả, Đề của tôi, Đề đã lưu
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildSourceTab('all', 'Tất cả', _allAvailableExams.length),
                                  const SizedBox(width: 8),
                                  _buildSourceTab('mine', 'Đề của tôi', _myExams.length),
                                  const SizedBox(width: 8),
                                  _buildSourceTab('saved', 'Đề đã lưu', _savedExams.length),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Thanh tìm kiếm đề
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm đề thi...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),

                            // Bộ lọc môn
                            if (_availableSubjects.length > 2) ...[
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _availableSubjects.map((sub) {
                                    final isSelected = _selectedSubject == sub;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(sub),
                                        selected: isSelected,
                                        onSelected: (val) {
                                          if (val) setState(() => _selectedSubject = sub);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Danh sách đề thi dạng card
                            if (_filteredExams.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Không tìm thấy đề thi phù hợp với từ khóa.',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredExams.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final exam = _filteredExams[index];
                                  final isSelected = _selectedExam?.id == exam.id;
                                  final isSaved = _isSavedExam(exam.id);
                                  return InkWell(
                                    onTap: () => setState(() => _selectedExam = exam),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primary.withValues(alpha: 0.06)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.border,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_off,
                                            color: isSelected
                                                ? AppTheme.primary
                                                : AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (isSaved) ...[
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.bookmark_added_rounded, size: 12, color: AppTheme.primary),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Đề lưu từ cộng đồng',
                                                          style: TextStyle(
                                                            color: AppTheme.primary,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                Text(
                                                  exam.title,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${exam.subject} • ${exam.questionCount} câu • ${exam.durationMinutes} phút',
                                                  style: const TextStyle(
                                                    color: AppTheme.textSecondary,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary,
                                                borderRadius: BorderRadius.circular(100),
                                              ),
                                              child: const Text(
                                                'Đã chọn',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],

                          const Divider(height: 48),

                          // 3. Quy chế phòng thi
                          const Row(
                            children: [
                              Icon(Icons.security_rounded, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text(
                                '3. Quy chế & Bảo mật phòng thi',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.shuffle_rounded, color: AppTheme.primary),
                            title: const Text('Trộn ngẫu nhiên câu hỏi & đáp án'),
                            subtitle: const Text('Mỗi thí sinh nhận một thứ tự câu hỏi và phương án riêng biệt để chống nhìn bài.'),
                            value: _shuffleQuestions,
                            onChanged: (val) => setState(() => _shuffleQuestions = val),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.shield_outlined, color: AppTheme.primary),
                            title: const Text('Giám sát chống gian lận'),
                            subtitle: const Text('Cảnh báo khi rời tab/app tối đa 3 lần, tự động nộp bài ở lần thứ 4 và khóa sao chép đề thi.'),
                            value: _enableAntiCheat,
                            onChanged: (val) => setState(() => _enableAntiCheat = val),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.visibility_outlined, color: AppTheme.primary),
                            title: const Text('Cho phép xem đáp án sau khi nộp bài'),
                            subtitle: const Text('Học sinh xem lại bài thi và lời giải chi tiết ngay sau khi nộp.'),
                            value: _allowReview,
                            onChanged: (val) => setState(() => _allowReview = val),
                          ),

                          const SizedBox(height: 36),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: (_selectedExam == null || _isCreating) ? null : _createRoom,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                _isCreating ? 'Đang khởi tạo...' : 'Khởi tạo phòng thi',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _EmptyExamState extends StatelessWidget {
  const _EmptyExamState({required this.onCreateExam});
  final VoidCallback onCreateExam;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: .2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.note_add_outlined, size: 36, color: AppTheme.primary),
            const SizedBox(height: 10),
            const Text('Bạn chưa có đề nào để mở phòng.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'Hãy khởi tạo đề trước, rồi quay lại chọn đề cho phòng thi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onCreateExam,
              icon: const Icon(Icons.add),
              label: const Text('Tạo đề mới'),
            ),
          ],
        ),
      );
}
