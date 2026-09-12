import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

enum SearchItemType { exam, room }

class _SearchItem {
  const _SearchItem({
    required this.id,
    required this.code,
    required this.title,
    required this.teacher,
    required this.subject,
    required this.type,
    required this.questions,
    required this.duration,
    required this.activity,
    this.isOpen = false,
  });

  final String id;
  final String code;
  final String title;
  final String teacher;
  final String subject;
  final SearchItemType type;
  final int questions;
  final int duration;
  final String activity;
  final bool isOpen;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final Set<String> _subjects = {};
  SearchItemType? _type;
  String _sort = 'Mới nhất';

  List<_SearchItem> _realItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealSearchData();
  }

  Future<void> _fetchRealSearchData() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('exams')
          .select('id, code, title, subject, duration_minutes, created_at, teachers(display_name), questions(count)')
          .eq('status', 'published')
          .order('created_at', ascending: false);

      final list = res as List<dynamic>;
      final List<_SearchItem> items = [];

      for (var item in list) {
        final teacherMap = item['teachers'] as Map<String, dynamic>?;
        final teacherName = teacherMap?['display_name'] as String? ?? 'Giáo viên bộ môn';
        final questionsData = item['questions'] as List<dynamic>?;
        final countFromDb = (questionsData != null && questionsData.isNotEmpty)
            ? ((questionsData.first as Map<String, dynamic>?)?['count'] as num?)?.toInt()
            : null;
        final qCount = (countFromDb != null && countFromDb > 0) ? countFromDb : 10;
        final duration = (item['duration_minutes'] as num?)?.toInt() ?? 45;

        items.add(_SearchItem(
          id: item['id']?.toString() ?? '',
          code: item['code']?.toString() ?? '',
          title: (item['title'] as String?) ?? 'Đề thi trắc nghiệm',
          teacher: teacherName,
          subject: (item['subject'] as String?) ?? 'Chung',
          type: SearchItemType.exam,
          questions: qCount,
          duration: duration,
          activity: 'Mới tạo',
        ));
      }

      if (mounted) {
        setState(() {
          _realItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu tìm kiếm từ Supabase: $e');
      if (mounted) {
        setState(() {
          // Provide standard initial subjects items for offline/testing compatibility
          if (_realItems.isEmpty) {
            _realItems = [
              const _SearchItem(
                id: '10000000-0000-4000-8000-000000000001',
                code: 'DT100001',
                title: 'Đề thi thử THPT Quốc gia môn Toán 2024',
                teacher: 'Thầy Nguyễn Văn A',
                subject: 'Toán học',
                type: SearchItemType.exam,
                questions: 10,
                duration: 90,
                activity: 'Mới tạo',
              ),
              const _SearchItem(
                id: '10000000-0000-4000-8000-000000000002',
                code: 'DT100002',
                title: 'Ôn tập Dao động cơ học - Vật lý 12',
                teacher: 'Cô Lê Thị B',
                subject: 'Vật lý',
                type: SearchItemType.exam,
                questions: 10,
                duration: 50,
                activity: 'Mới tạo',
              ),
            ];
          }
          _isLoading = false;
        });

        // Show network popup if mounted
        _showNetworkErrorDialog();
      }
    }
  }

  void _showNetworkErrorDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Lỗi kết nối mạng: Không thể đồng bộ đề thi mới từ máy chủ.'),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _fetchRealSearchData,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SearchItem> get _filteredItems {
    final query = _controller.text.trim().toLowerCase();
    final results = _realItems.where((item) {
      final matchesQuery = query.isEmpty ||
          '${item.title} ${item.teacher} ${item.subject} ${item.code}'.toLowerCase().contains(query);
      final matchesSubject = _subjects.isEmpty || _subjects.contains(item.subject);
      final matchesType = _type == null || _type == item.type;
      return matchesQuery && matchesSubject && matchesType;
    }).toList();

    if (_sort == 'Mới nhất') {
      // Retain natural database newest-first order
    } else if (_sort == 'Thời gian tăng dần') {
      results.sort((a, b) => a.duration.compareTo(b.duration));
    } else if (_sort == 'Thời gian giảm dần') {
      results.sort((a, b) => b.duration.compareTo(a.duration));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredItems;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  _SearchBox(controller: _controller, onChanged: () => setState(() {})),
                  const SizedBox(height: 32),
                  Flex(
                    direction: compact ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: compact ? double.infinity : 230,
                        child: _FilterPanel(
                          subjects: _subjects,
                          type: _type,
                          sort: _sort,
                          onSubjectChanged: (subject, selected) => setState(
                            () => selected ? _subjects.add(subject) : _subjects.remove(subject),
                          ),
                          onTypeChanged: (type) => setState(() => _type = type),
                          onSortChanged: (sort) => setState(() => _sort = sort),
                        ),
                      ),
                      SizedBox(width: compact ? 0 : 32, height: compact ? 24 : 0),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                            : _ResultsGrid(items: results),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm kiếm đề thi theo tên, môn học, giáo viên, mã đề...',
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onChanged,
            icon: const Icon(Icons.search),
            label: const Text('Tìm kiếm'),
          ),
        ],
      );
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.subjects,
    required this.type,
    required this.sort,
    required this.onSubjectChanged,
    required this.onTypeChanged,
    required this.onSortChanged,
  });

  final Set<String> subjects;
  final SearchItemType? type;
  final String sort;
  final void Function(String, bool) onSubjectChanged;
  final ValueChanged<SearchItemType?> onTypeChanged;
  final ValueChanged<String> onSortChanged;

  static const List<String> availableSubjects = [
    'Toán học',
    'Vật lý',
    'Hóa học',
    'Sinh học',
    'Tiếng Anh',
    'Lịch sử',
    'Địa lý',
    'Tin học',
  ];

  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bộ Lọc Tìm Kiếm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              const Text('Môn học (8 môn)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ...availableSubjects.map(
                (sub) => CheckboxListTile(
                  title: Text(sub, style: const TextStyle(fontSize: 13)),
                  value: subjects.contains(sub),
                  onChanged: (val) => onSubjectChanged(sub, val ?? false),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    for (final s in availableSubjects) {
                      onSubjectChanged(s, false);
                    }
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Bỏ chọn tất cả', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      );
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.items});
  final List<_SearchItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Không tìm thấy đề thi phù hợp với bộ lọc.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF0ECFF),
                  child: const Icon(Icons.assignment_outlined, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.subject,
                              style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (item.code.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '#${item.code}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.questions} câu hỏi • Thời gian: ${item.duration} phút • GV: ${item.teacher}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (item.id.isNotEmpty) {
                      context.go('/exam_detail?examId=${item.id}');
                    } else {
                      context.go('/exam_detail');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Xem Đề'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
