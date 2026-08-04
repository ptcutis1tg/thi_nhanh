import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';
import '../../shared/widgets/exam_card.dart';
import '../../shared/widgets/topic_chip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  width: double.infinity,
                  height: 200,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chào mừng quay lại, Minh Anh',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hôm nay bạn muốn ôn tập chủ đề gì?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Topic Chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    TopicChip(label: 'Toán 12', onTap: () {}),
                    TopicChip(label: 'Vật lý', onTap: () {}),
                    TopicChip(label: 'Tiếng Anh IELTS', onTap: () {}),
                    TopicChip(label: 'Sinh học', onTap: () {}),
                    TopicChip(label: 'Lịch sử', onTap: () {}),
                  ],
                ),
                const SizedBox(height: 48),

                // Recent Section
                Text(
                  'Đề vừa làm',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ExamCard(
                        title: 'Đề thi thử THPT Quốc gia môn Toán 2024',
                        authorName: 'Nguyễn Văn A',
                        type: ExamCardType.exam,
                        onTap: () {},
                      ),
                      const SizedBox(width: 24),
                      ExamCard(
                        title: 'Kiểm tra giữa kì I Vật lý 12 - Lớp 12A1',
                        authorName: 'Trần Thị B',
                        type: ExamCardType.room,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Join Room Section
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vào phòng thi ngay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Giáo viên của bạn vừa chia sẻ mã phòng? Nhập ngay để làm bài.', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Row(
                          children: [
                            const Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Nhập mã phòng (PT...)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/student_waiting_room');
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              child: const Text('Tham gia'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Hot Exams Section
                Text(
                  'Đề Hot',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 280 / 160,
                  children: [
                    ExamCard(
                      title: 'Đề thi thử THPT Quốc gia môn Toán 2024',
                      authorName: 'Nguyễn Văn A',
                      type: ExamCardType.exam,
                      onTap: () {},
                    ),
                    ExamCard(
                      title: 'Từ vựng Tiếng Anh IELTS - Unit 4, 5',
                      authorName: 'Lê Văn C',
                      type: ExamCardType.exam,
                      onTap: () {},
                    ),
                    ExamCard(
                      title: 'Trắc nghiệm cơ sở dữ liệu nâng cao',
                      authorName: 'Nguyễn Văn D',
                      type: ExamCardType.exam,
                      onTap: () {},
                    ),
                    ExamCard(
                      title: 'Đề thi thử môn Hóa học 12 lần 1',
                      authorName: 'Phạm Thị E',
                      type: ExamCardType.exam,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
