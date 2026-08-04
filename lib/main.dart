import 'package:flutter/material.dart';

const _violet = Color(0xff5b4cf0);
const _ink = Color(0xff202033);
const _muted = Color(0xff6f7287);
const _paper = Color(0xfffcfbff);

void main() => runApp(const OnThiApp());

class OnThiApp extends StatelessWidget {
  const OnThiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ÔnThi',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _paper,
      colorScheme: ColorScheme.fromSeed(seedColor: _violet),
      fontFamily: 'Arial',
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(),
                _Hero(),
                _SectionHeader('Đang được yêu thích', action: 'Xem tất cả →'),
                _ExamGrid(),
                SizedBox(height: 48),
                _WeeklyPanel(),
                _SectionHeader('Khám phá theo môn'),
                _SubjectList(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 55),
    child: Row(
      children: [
        const _Brand(),
        const Spacer(),
        if (MediaQuery.sizeOf(context).width > 650) ...[
          const _NavItem('Khám phá', selected: true),
          const _NavItem('Kho đề'),
          const _NavItem('Hướng dẫn'),
          const SizedBox(width: 22),
        ],
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xffffdaa6),
          child: Text(
            'NA',
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: _violet,
        child: Icon(Icons.check, color: Colors.white, size: 19),
      ),
      SizedBox(width: 9),
      Text(
        'ÔnThi',
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    ],
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.text, {this.selected = false});
  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(
      text,
      style: TextStyle(
        color: selected ? _ink : _muted,
        fontSize: 14,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'KHO ĐỀ CỘNG ĐỒNG',
        style: TextStyle(
          color: _violet,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          style: const TextStyle(
            color: _ink,
            fontSize: 58,
            height: 1.08,
            letterSpacing: -2.8,
            fontWeight: FontWeight.w800,
          ),
          children: const [
            TextSpan(text: 'Học thật sâu,\nlàm '),
            TextSpan(
              text: 'đề',
              style: TextStyle(
                color: _violet,
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(text: ' thật vui.'),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const SizedBox(
        width: 570,
        child: Text(
          'Tìm một đề thi phù hợp, tập trung làm bài và biết chính xác mình cần cải thiện ở đâu.',
          style: TextStyle(color: _muted, height: 1.7),
        ),
      ),
      const SizedBox(height: 27),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Nhập mã đề, ví dụ: TOAN12A',
            hintStyle: const TextStyle(fontSize: 13, color: _muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xffe8e6f1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xffe8e6f1)),
            ),
            suffixIcon: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: _violet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text('Vào làm bài →'),
            ),
          ),
        ),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.action});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 49, bottom: 16),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            letterSpacing: -.7,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: _violet,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
  );
}

class _ExamGrid extends StatelessWidget {
  const _ExamGrid();
  static const exams = [
    (
      'Toán 12',
      'Chinh phục hàm số mũ & logarit',
      '45 phút',
      '4.8 · 326 lượt làm',
    ),
    (
      'Tiếng Anh 11',
      'Ngữ pháp: Mệnh đề quan hệ',
      '30 phút',
      '4.9 · 184 lượt làm',
    ),
    (
      'Vật lý 12',
      'Dao động cơ — kiểm tra nhanh',
      '20 phút',
      '4.7 · 551 lượt làm',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 560
          ? 1
          : constraints.maxWidth < 840
          ? 2
          : 3;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: exams
            .map(
              (exam) => SizedBox(
                width: width,
                child: _ExamCard(exam.$1, exam.$2, exam.$3, exam.$4),
              ),
            )
            .toList(),
      );
    },
  );
}

class _ExamCard extends StatelessWidget {
  const _ExamCard(this.subject, this.title, this.time, this.rating);
  final String subject;
  final String title;
  final String time;
  final String rating;

  @override
  Widget build(BuildContext context) => Container(
    height: 160,
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffe8e6f1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Tag(subject),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '⏱ $time',
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
            const Spacer(),
            Text(
              '★ $rating',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xffe89b22),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xffeceaff),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _violet,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _WeeklyPanel extends StatelessWidget {
  const _WeeklyPanel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: const Color(0xff24213e),
      borderRadius: BorderRadius.circular(27),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GÓC ÔN TẬP TUẦN NÀY',
              style: TextStyle(
                color: Color(0xffb9f4d3),
                fontSize: 11,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Đừng để đề cương\nchỉ nằm trên bàn.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'Những bộ đề được cộng đồng hoàn thành nhiều nhất, chọn lọc theo từng môn.',
              style: TextStyle(
                color: Color(0xffc6c3dd),
                fontSize: 14,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffb9f4d3),
                foregroundColor: const Color(0xff193526),
              ),
              child: const Text('Khám phá bộ đề'),
            ),
          ],
        );
        const stats = _Stats();
        if (constraints.maxWidth > 650) {
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 28),
              const Expanded(child: stats),
            ],
          );
        }
        return Column(children: [copy, const SizedBox(height: 22), stats]);
      },
    ),
  );
}

class _Stats extends StatelessWidget {
  const _Stats();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        _Stat('Đề thi mới tuần này', '+142'),
        _Stat('Lượt làm bài', '12.480'),
        _Stat('Người học đang online', '1.256'),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: _violet,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _SubjectList extends StatelessWidget {
  const _SubjectList();
  static const subjects = [
    ('Toán học', '1.284 đề'),
    ('Ngữ văn', '948 đề'),
    ('Tiếng Anh', '1.130 đề'),
    ('Vật lý', '632 đề'),
    ('Hóa học', '597 đề'),
  ];
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: subjects
        .map(
          (item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffe8e6f1)),
            ),
            child: Text.rich(
              TextSpan(
                text: item.$1,
                style: const TextStyle(
                  fontSize: 13,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: '  ${item.$2}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );
}
