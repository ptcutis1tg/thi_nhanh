import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/exam_card.dart';
import '../../shared/widgets/topic_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _joinRoomController = TextEditingController();

  @override
  void dispose() {
    _joinRoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
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
                        'Chào mừng quay lại, ${authProvider.userName}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hôm nay bạn muốn ôn tập chủ đề gì?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Primary, visible entry point for the connected practice flow.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: .25)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Làm đề tự luyện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            SizedBox(height: 3),
                            Text('Lưu đáp án tự động và tính giờ theo phiên làm bài.', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/exam/physics-12'),
                        child: const Text('Bắt đầu'),
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
                        onTap: () => context.go('/exam/physics-12'),
                      ),
                      const SizedBox(width: 24),
                      ExamCard(
                        title: 'Kiểm tra giữa kì I Vật lý 12 - Lớp 12A1',
                        authorName: 'Trần Thị B',
                        type: ExamCardType.room,
                        onTap: () => context.go('/room/password'),
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
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                            Expanded(
                              child: TextField(
                                controller: _joinRoomController,
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    context.go('/student_waiting_room');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã phòng')));
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Nhập mã phòng (PT...)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (_joinRoomController.text.isNotEmpty) {
                                  context.go('/student_waiting_room');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã phòng')));
                                }
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
                      onTap: () => context.go('/exam/physics-12'),
                    ),
                    ExamCard(
                      title: 'Từ vựng Tiếng Anh IELTS - Unit 4, 5',
                      authorName: 'Lê Văn C',
                      type: ExamCardType.exam,
                      onTap: () => context.go('/exam/physics-12'),
                    ),
                    ExamCard(
                      title: 'Trắc nghiệm cơ sở dữ liệu nâng cao',
                      authorName: 'Nguyễn Văn D',
                      type: ExamCardType.exam,
                      onTap: () => context.go('/exam/physics-12'),
                    ),
                    ExamCard(
                      title: 'Đề thi thử môn Hóa học 12 lần 1',
                      authorName: 'Phạm Thị E',
                      type: ExamCardType.exam,
                      onTap: () => context.go('/exam/physics-12'),
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
