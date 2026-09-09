import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

enum SearchItemType { exam, room }

class _SearchItem {
  const _SearchItem({
    required this.title,
    required this.teacher,
    required this.subject,
    required this.type,
    required this.questions,
    required this.duration,
    required this.activity,
    this.isOpen = false,
  });

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
      final res = await client.from('exams').select('title, subject, total_questions, created_at');
      final list = res as List<dynamic>;
      final List<_SearchItem> items = [];
      for (var item in list) {
        items.add(_SearchItem(
          title: (item['title'] as String?) ?? 'Đề thi trắc nghiệm',
          teacher: 'Giáo viên',
          subject: (item['subject'] as String?) ?? 'Chung',
          type: SearchItemType.exam,
          questions: (item['total_questions'] as num?)?.toInt() ?? 40,
          duration: 60,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SearchItem> get _filteredItems {
    final query = _controller.text.trim().toLowerCase();
    final results = _realItems.where((item) {
      final matchesQuery = query.isEmpty || '${item.title} ${item.teacher} ${item.subject}'.toLowerCase().contains(query);
      return matchesQuery && (_subjects.isEmpty || _subjects.contains(item.subject)) && (_type == null || _type == item.type);
    }).toList();
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
                      SizedBox(width: compact ? double.infinity : 230, child: _FilterPanel(
                        subjects: _subjects,
                        type: _type,
                        sort: _sort,
                        onSubjectChanged: (subject, selected) => setState(() => selected ? _subjects.add(subject) : _subjects.remove(subject)),
                        onTypeChanged: (type) => setState(() => _type = type),
                        onSortChanged: (sort) => setState(() => _sort = sort),
                      )),
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
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: TextField(controller: controller, onChanged: (_) => onChanged(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm kiếm đề thi, phòng thi...'))),
    const SizedBox(width: 12),
    ElevatedButton(onPressed: onChanged, child: const Text('Tìm kiếm')),
  ]);
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.subjects, required this.type, required this.sort, required this.onSubjectChanged, required this.onTypeChanged, required this.onSortChanged});
  final Set<String> subjects;
  final SearchItemType? type;
  final String sort;
  final void Function(String, bool) onSubjectChanged;
  final ValueChanged<SearchItemType?> onTypeChanged;
  final ValueChanged<String> onSortChanged;

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
          const Text('Môn học', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ...['Toán', 'Vật lý', 'Hóa học', 'Tiếng Anh'].map((sub) => CheckboxListTile(
            title: Text(sub, style: const TextStyle(fontSize: 13)),
            value: subjects.contains(sub),
            onChanged: (val) => onSubjectChanged(sub, val ?? false),
            contentPadding: EdgeInsets.zero,
            dense: true,
          )),
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
            Text('Không tìm thấy đề thi phù hợp trong CSDL Supabase.', style: TextStyle(color: AppTheme.textSecondary)),
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
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFF0ECFF), child: Icon(Icons.assignment_outlined, color: AppTheme.primary)),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Môn: ${item.subject} • ${item.questions} câu'),
            trailing: ElevatedButton(
              onPressed: () => context.go('/exam/physics-12'),
              child: const Text('Xem Đề'),
            ),
          ),
        );
      },
    );
  }
}
