import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  static const _items = [
    _SearchItem(title: 'Đề thi thử THPT Quốc Gia môn Toán 2024 - Trường Chuyên', teacher: 'Thầy Nguyễn Văn A', subject: 'Toán học', type: SearchItemType.exam, questions: 50, duration: 90, activity: '1.2k'),
    _SearchItem(title: 'Phòng thi đồng bộ IELTS Mock Test - Listening & Reading', teacher: 'Cô Trần Thị B', subject: 'Tiếng Anh', type: SearchItemType.room, questions: 40, duration: 60, activity: '45/100', isOpen: true),
    _SearchItem(title: 'Ôn tập Dao động cơ học - Vật lý 12 cơ bản và nâng cao', teacher: 'Thầy Lê Văn C', subject: 'Vật lý', type: SearchItemType.exam, questions: 40, duration: 50, activity: '850'),
    _SearchItem(title: 'Đề kiểm tra 1 tiết Hóa hữu cơ - Lớp 11', teacher: 'Cô Phạm Thị D', subject: 'Hóa học', type: SearchItemType.exam, questions: 30, duration: 45, activity: '320'),
  ];

  final _controller = TextEditingController();
  final Set<String> _subjects = {};
  SearchItemType? _type;
  String _sort = 'Mới nhất';
  bool _showTeachers = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SearchItem> get _filteredItems {
    final query = _controller.text.trim().toLowerCase();
    final results = _items.where((item) {
      final matchesQuery = query.isEmpty || '${item.title} ${item.teacher} ${item.subject}'.toLowerCase().contains(query);
      return matchesQuery && (_subjects.isEmpty || _subjects.contains(item.subject)) && (_type == null || _type == item.type);
    }).toList();
    if (_sort == 'Phổ biến nhất') results.sort((a, b) => b.activity.compareTo(a.activity));
    return results;
  }

  List<_Teacher> get _filteredTeachers {
    final query = _controller.text.trim().toLowerCase();
    return _teachers.where((teacher) {
      final matchesQuery = query.isEmpty || '${teacher.name} ${teacher.subject}'.toLowerCase().contains(query);
      return matchesQuery && (_subjects.isEmpty || _subjects.contains(teacher.subject));
    }).toList();
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
                        child: _showTeachers
                            ? _TeachersGrid(
                                teachers: _filteredTeachers,
                                onSelectTeacher: (teacher) {
                                  _controller.text = teacher.name;
                                  setState(() => _showTeachers = false);
                                },
                                onSelectTab: () => setState(() => _showTeachers = false),
                              )
                            : _ResultsGrid(
                                items: results,
                                onSelectTeachers: () => setState(() => _showTeachers = true),
                              ),
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
    Expanded(child: TextField(controller: controller, onChanged: (_) => onChanged(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm kiếm đề thi, phòng thi hoặc giáo viên...'))),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Bộ lọc', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      const Text('MÔN HỌC', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ...['Toán học', 'Vật lý', 'Hóa học', 'Tiếng Anh'].map((subject) => CheckboxListTile(
        value: subjects.contains(subject), contentPadding: EdgeInsets.zero, dense: true, title: Text(subject),
        onChanged: (value) => onSubjectChanged(subject, value ?? false),
      )),
      const SizedBox(height: 8),
      const Text('LOẠI', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      RadioListTile<SearchItemType?>(value: null, groupValue: type, contentPadding: EdgeInsets.zero, dense: true, title: const Text('Tất cả'), onChanged: onTypeChanged),
      RadioListTile<SearchItemType?>(value: SearchItemType.exam, groupValue: type, contentPadding: EdgeInsets.zero, dense: true, title: const Text('Đề thi (ĐT)'), onChanged: onTypeChanged),
      RadioListTile<SearchItemType?>(value: SearchItemType.room, groupValue: type, contentPadding: EdgeInsets.zero, dense: true, title: const Text('Phòng thi (PT)'), onChanged: onTypeChanged),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: sort, decoration: const InputDecoration(labelText: 'SẮP XẾP'), items: const [DropdownMenuItem(value: 'Mới nhất', child: Text('Mới nhất')), DropdownMenuItem(value: 'Phổ biến nhất', child: Text('Phổ biến nhất'))], onChanged: (value) => onSortChanged(value ?? sort)),
    ]),
  );
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.items, required this.onSelectTeachers});
  final List<_SearchItem> items;
  final VoidCallback onSelectTeachers;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 480 ? 2 : 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        TextButton(onPressed: () {}, child: Text('Đề thi & Phòng thi', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary))),
        TextButton(onPressed: onSelectTeachers, child: const Text('Giáo viên')),
        const Spacer(),
        Text('Tìm thấy ${items.length} kết quả', style: const TextStyle(color: AppTheme.textSecondary)),
      ]),
      const SizedBox(height: 20),
      if (items.isEmpty) const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('Không tìm thấy kết quả phù hợp.')))
      else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: 310, crossAxisSpacing: 18, mainAxisSpacing: 18), itemBuilder: (_, index) => _ResultCard(item: items[index])),
    ]);
  });
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});
  final _SearchItem item;

  @override
  Widget build(BuildContext context) {
    final isRoom = item.type == SearchItemType.room;
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Chip(label: Text(item.subject), visualDensity: VisualDensity.compact), const Spacer(), Chip(label: Text(isRoom ? 'PT' : 'ĐT'), visualDensity: VisualDensity.compact)]),
          const SizedBox(height: 8), Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12), Row(children: [const Icon(Icons.person_outline, size: 17, color: AppTheme.textSecondary), const SizedBox(width: 6), Expanded(child: Text(item.teacher, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary)))]),
          const Divider(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_Metric('CÂU HỎI', '${item.questions}'), _Metric('THỜI GIAN', '${item.duration}\''), _Metric(isRoom ? 'THAM GIA' : 'ĐÃ LÀM', item.activity)]),
        ])),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: isRoom
          ? ElevatedButton(onPressed: () => context.go('/room/password'), child: const Text('Vào phòng ngay'))
          : OutlinedButton(onPressed: () => context.go('/exam/physics-12'), child: const Text('Xem chi tiết')))),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
}

class _Teacher {
  const _Teacher({required this.name, required this.subject, required this.rating, required this.examCount, required this.color});
  final String name;
  final String subject;
  final String rating;
  final int examCount;
  final Color color;
}

const _teachers = [
  _Teacher(name: 'Thầy Nguyễn Văn A', subject: 'Toán học', rating: '4.9', examCount: 124, color: Color(0xFFE4DFFF)),
  _Teacher(name: 'Cô Lê Thị B', subject: 'Vật lý', rating: '4.8', examCount: 98, color: Color(0xFFDDF5FF)),
  _Teacher(name: 'Thầy Trần Văn C', subject: 'Tiếng Anh', rating: '5.0', examCount: 215, color: Color(0xFFFFE9DD)),
  _Teacher(name: 'Cô Phạm Thị D', subject: 'Hóa học', rating: '4.7', examCount: 76, color: Color(0xFFE3F8E8)),
];

class _TeachersGrid extends StatelessWidget {
  const _TeachersGrid({required this.teachers, required this.onSelectTeacher, required this.onSelectTab});
  final List<_Teacher> teachers;
  final ValueChanged<_Teacher> onSelectTeacher;
  final VoidCallback onSelectTab;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 480 ? 2 : 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        TextButton(onPressed: onSelectTab, child: const Text('Đề thi & Phòng thi')),
        TextButton(onPressed: () {}, child: Text('Giáo viên', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary))),
        const Spacer(),
        Text('Hiển thị ${teachers.length} giáo viên', style: const TextStyle(color: AppTheme.textSecondary)),
      ]),
      const SizedBox(height: 20),
      if (teachers.isEmpty) const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('Không tìm thấy giáo viên phù hợp.')))
      else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: teachers.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: 310, crossAxisSpacing: 18, mainAxisSpacing: 18), itemBuilder: (_, index) => _TeacherCard(teacher: teachers[index], onPressed: () => onSelectTeacher(teachers[index]))),
    ]);
  });
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({required this.teacher, required this.onPressed});
  final _Teacher teacher;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
    child: Column(children: [
      CircleAvatar(radius: 42, backgroundColor: teacher.color, child: Text(teacher.name.substring(teacher.name.indexOf(' ') + 1, teacher.name.indexOf(' ') + 2), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary))),
      const SizedBox(height: 12),
      Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_rounded, color: AppTheme.warning, size: 18), const SizedBox(width: 4), Text(teacher.rating)]),
      const SizedBox(height: 8),
      Text(teacher.name, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
      const SizedBox(height: 8), Chip(label: Text(teacher.subject), visualDensity: VisualDensity.compact),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.article_outlined, size: 18, color: AppTheme.textSecondary), const SizedBox(width: 6), Text('${teacher.examCount} đề thi', style: const TextStyle(color: AppTheme.textSecondary))]),
      const Spacer(),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onPressed, child: const Text('Xem bộ đề'))),
    ]),
  );
}
