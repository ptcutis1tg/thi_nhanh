import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isSavingInfo = false;
  bool _isSavingPassword = false;

  // Role toggle: true = Học sinh, false = Giáo viên
  bool _isStudentRole = true;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(text: authProvider.userName);
    _emailController = TextEditingController(text: authProvider.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar('Vui lòng nhập họ và tên', isError: true);
      return;
    }
    setState(() => _isSavingInfo = true);
    await context.read<AuthProvider>().updateProfile(newName);
    if (mounted) {
      setState(() => _isSavingInfo = false);
      _showSnackBar('Cập nhật thông tin cá nhân thành công!');
    }
  }

  Future<void> _handleChangePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ các trường mật khẩu', isError: true);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu mới và xác nhận không khớp', isError: true);
      return;
    }
    setState(() => _isSavingPassword = true);
    try {
      await context.read<AuthProvider>().changePassword(
            _currentPasswordController.text,
            _newPasswordController.text,
          );
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSnackBar('Đổi mật khẩu thành công!');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64String';
        if (mounted) {
          await context.read<AuthProvider>().updateAvatar(dataUrl);
          _showSnackBar('Cập nhật ảnh đại diện thành công!');
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi chọn ảnh: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAvatarWidget(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        final base64Str = avatarUrl.contains(',') ? avatarUrl.split(',').last : avatarUrl;
        final bytes = base64Decode(base64Str);
        return CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0xFFF0ECFF),
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        debugPrint('Lỗi giải mã avatar base64: $e');
      }
    }
    return const CircleAvatar(
      radius: 44,
      backgroundColor: Color(0xFFF0ECFF),
      child: Icon(
        Icons.person,
        size: 48,
        color: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (_nameController.text.isEmpty || !_isSavingInfo) {
      if (_nameController.text != authProvider.userName && !FocusScope.of(context).hasFocus) {
        _nameController.text = authProvider.userName;
      }
    }
    if (_emailController.text != authProvider.userEmail) {
      _emailController.text = authProvider.userEmail;
    }

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PROFILE HEADER CARD
                _buildProfileHeaderCard(authProvider, isMobile),

                const SizedBox(height: 28),

                // 2. DASHBOARD LAYOUT (2 COLUMNS) - Dynamic Student / Teacher Content
                if (isMobile)
                  Column(
                    children: [
                      _buildAnalyticsCard(),
                      const SizedBox(height: 24),
                      _buildOverviewOrAchievementsCard(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 65,
                        child: _buildAnalyticsCard(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 35,
                        child: _buildOverviewOrAchievementsCard(),
                      ),
                    ],
                  ),

                const SizedBox(height: 28),

                // 3. RECENT ACTIVITY CARD (Student Recent Tests vs Teacher Recent Rooms)
                if (_isStudentRole)
                  _buildStudentRecentTestCard()
                else
                  _buildTeacherRecentRoomsCard(),

                const SizedBox(height: 28),

                // 4. TEACHER EXAM SETS CARD (Teacher Only)
                if (!_isStudentRole) ...[
                  _buildTeacherExamSetsCard(),
                  const SizedBox(height: 28),
                ],

                // 5. TEACHING INSIGHTS CARD (Teacher Only)
                if (!_isStudentRole) ...[
                  _buildTeacherInsightsCard(),
                  const SizedBox(height: 28),
                ],

                // 6. PERSONAL INFORMATION CARD
                _buildPersonalInformationCard(),

                const SizedBox(height: 28),

                // 7. CHANGE PASSWORD CARD
                _buildChangePasswordCard(),

                const SizedBox(height: 28),

                // 8. ACCOUNT ACTIONS
                _buildAccountActionsCard(authProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. PROFILE HEADER CARD
  // ---------------------------------------------------------------------------
  Widget _buildProfileHeaderCard(AuthProvider authProvider, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _buildHeaderUserInfo(authProvider),
                const SizedBox(height: 24),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 16),
                _buildHeaderStats(),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildHeaderUserInfo(authProvider),
                ),
                Container(
                  height: 80,
                  width: 1,
                  color: AppTheme.border,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                ),
                Expanded(
                  flex: 5,
                  child: _buildHeaderStats(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderUserInfo(AuthProvider authProvider) {
    return Row(
      children: [
        InkWell(
          onTap: _pickAndUploadAvatar,
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              _buildAvatarWidget(authProvider.userAvatarUrl),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authProvider.userName.isNotEmpty ? authProvider.userName : 'Ly Khánh',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authProvider.userEmail,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              // Role badge with interactive toggle
              InkWell(
                onTap: () {
                  setState(() => _isStudentRole = !_isStudentRole);
                  _showSnackBar(
                      'Đã chuyển góc nhìn sang ${_isStudentRole ? 'Học sinh' : 'Giáo viên'}');
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0ECFF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFE4DFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isStudentRole ? '🎓 Học sinh' : '👨‍🏫 Giáo viên',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.sync_alt_rounded, size: 12, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStats() {
    if (_isStudentRole) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStatItem('24', 'Bài đã thi'),
          _buildVerticalSeparator(),
          _buildCompactStatItem('8.2', 'Điểm trung bình'),
          _buildVerticalSeparator(),
          _buildCompactStatItem('🔥 5', 'Chuỗi bài thi'),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStatItem('12', 'Bộ đề đã tạo'),
          _buildVerticalSeparator(),
          _buildCompactStatItem('35', 'Phòng thi'),
          _buildVerticalSeparator(),
          _buildCompactStatItem('450', 'Lượt tham gia'),
          _buildVerticalSeparator(),
          _buildCompactStatItem('8.1', 'Điểm TB học sinh'),
        ],
      );
    }
  }

  Widget _buildCompactStatItem(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalSeparator() {
    return Container(
      height: 36,
      width: 1,
      color: AppTheme.border,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ANALYTICS CARD (LEFT COLUMN ~65%)
  // ---------------------------------------------------------------------------
  Widget _buildAnalyticsCard() {
    final titleText = _isStudentRole ? '📊 Tổng quan học tập' : '📊 Thống kê giảng dạy';
    final subtitleText = _isStudentRole ? '6 bài gần nhất' : '6 phòng gần nhất';

    final List<double> chartValues =
        _isStudentRole ? const [7.0, 8.0, 7.5, 9.0, 8.5, 9.2] : const [32, 41, 28, 45, 38, 43];
    final List<String> chartLabels = _isStudentRole
        ? const ['Bài 1', 'Bài 2', 'Bài 3', 'Bài 4', 'Bài 5', 'Bài 6']
        : const ['Phòng 1', 'Phòng 2', 'Phòng 3', 'Phòng 4', 'Phòng 5', 'Phòng 6'];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  subtitleText,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Line Chart
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(
                values: chartValues,
                labels: chartLabels,
                isStudentScore: _isStudentRole,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // X-Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: chartLabels
                .map((lbl) =>
                    Text(lbl, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)))
                .toList(),
          ),

          const SizedBox(height: 24),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),

          // Secondary Metrics
          if (_isStudentRole)
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryMetricItem(
                    icon: Icons.star_rounded,
                    label: 'Điểm cao nhất',
                    value: '9.5',
                  ),
                ),
                Container(height: 36, width: 1, color: AppTheme.border),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSecondaryMetricItem(
                    icon: Icons.timer_outlined,
                    label: 'Tổng thời gian làm bài',
                    value: '6h 32m',
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryMetricItem(
                    icon: Icons.people_outline_rounded,
                    label: 'Phòng đông nhất',
                    value: '45 học sinh',
                  ),
                ),
                Container(height: 36, width: 1, color: AppTheme.border),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecondaryMetricItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Tỷ lệ hoàn thành',
                    value: '92%',
                  ),
                ),
                Container(height: 36, width: 1, color: AppTheme.border),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecondaryMetricItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Điểm TB học sinh',
                    value: '8.1',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFF0ECFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. OVERVIEW OR ACHIEVEMENTS CARD (RIGHT COLUMN ~35%)
  // ---------------------------------------------------------------------------
  Widget _buildOverviewOrAchievementsCard() {
    if (_isStudentRole) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Thành tích',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 20),
            _buildAchievementItem('🔥', 'Chuỗi 5 bài', 'Hoàn thành bài thi 5 lần liên tiếp', const Color(0xFFFFF7ED)),
            const SizedBox(height: 14),
            _buildAchievementItem('🎯', 'Điểm tuyệt đối', 'Đạt 10 điểm một bài thi', const Color(0xFFF0ECFF)),
            const SizedBox(height: 14),
            _buildAchievementItem('⚡', 'Phản xạ nhanh', 'Trả lời nhanh 10 câu', const Color(0xFFFEFCE8)),
            const SizedBox(height: 14),
            _buildAchievementItem('🥉', 'Top 3', 'Đạt Top 3 trong phòng thi', const Color(0xFFF3F4F6)),
          ],
        ),
      );
    } else {
      // Teacher Exam Overview Card ("📌 Tổng quan đề thi")
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📌 Tổng quan đề thi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 20),
            _buildTeacherOverviewItem('📝', 'Tổng số câu hỏi', '240 câu', const Color(0xFFF0ECFF)),
            const SizedBox(height: 14),
            _buildTeacherOverviewItem('🎯', 'Tỷ lệ trả lời đúng', '76%', const Color(0xFFDCFCE7)),
            const SizedBox(height: 14),
            _buildTeacherOverviewItem('⚠️', 'Câu khó nhất', 'Câu 8 – Toán 12 (42% đúng)', const Color(0xFFFFEDD5)),
            const SizedBox(height: 14),
            _buildTeacherOverviewItem('🔥', 'Đề tham gia nhiều nhất', 'Ôn tập Toán HK1 (86 lượt)', const Color(0xFFFEFCE8)),
          ],
        ),
      );
    }
  }

  Widget _buildAchievementItem(String icon, String title, String description, Color bgColor) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherOverviewItem(String icon, String title, String value, Color bgColor) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. STUDENT RECENT TEST CARD
  // ---------------------------------------------------------------------------
  Widget _buildStudentRecentTestCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🕘 Bài thi gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 20),
          _buildTestHistoryRow(
            subjectIcon: '📐',
            title: 'Toán 12 – Hàm số',
            date: '25/08/2026',
            score: '8.5 điểm',
            scoreStatus: _ScoreStatus.medium,
          ),
          const Divider(color: AppTheme.border, height: 24),
          _buildTestHistoryRow(
            subjectIcon: '🔤',
            title: 'Tiếng Anh – Unit 4',
            date: '22/08/2026',
            score: '9.0 điểm',
            scoreStatus: _ScoreStatus.high,
          ),
          const Divider(color: AppTheme.border, height: 24),
          _buildTestHistoryRow(
            subjectIcon: '⚡',
            title: 'Vật lý – Dao động điều hòa',
            date: '18/08/2026',
            score: '7.5 điểm',
            scoreStatus: _ScoreStatus.low,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showSnackBar('Xem lịch sử bài thi'),
              icon: const Text(
                'Xem tất cả lịch sử',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
              label: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestHistoryRow({
    required String subjectIcon,
    required String title,
    required String date,
    required String score,
    required _ScoreStatus scoreStatus,
  }) {
    Color pillBg;
    Color pillText;
    switch (scoreStatus) {
      case _ScoreStatus.high:
        pillBg = const Color(0xFFDCFCE7);
        pillText = const Color(0xFF166534);
        break;
      case _ScoreStatus.medium:
        pillBg = const Color(0xFFF0ECFF);
        pillText = AppTheme.primary;
        break;
      case _ScoreStatus.low:
        pillBg = const Color(0xFFFFEDD5);
        pillText = const Color(0xFFC2410C);
        break;
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(subjectIcon, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            score,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pillText,
            ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => _showSnackBar('Xem chi tiết bài thi: $title'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: const [
                Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TEACHER RECENT ROOMS CARD ("🕘 Phòng thi gần đây")
  // ---------------------------------------------------------------------------
  Widget _buildTeacherRecentRoomsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🕘 Phòng thi gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/create_room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Tạo phòng thi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTeacherRoomRow(
            title: 'Ôn tập Toán 12 – Hàm số',
            roomCode: 'A8K21',
            date: '25/08/2026',
            studentsCount: 42,
            statusLabel: 'Đã kết thúc',
            statusType: _RoomStatusType.ended,
          ),
          const Divider(color: AppTheme.border, height: 24),
          _buildTeacherRoomRow(
            title: 'Tiếng Anh – Unit 4',
            roomCode: 'ENG24',
            date: '22/08/2026',
            studentsCount: 35,
            statusLabel: 'Đã kết thúc',
            statusType: _RoomStatusType.ended,
          ),
          const Divider(color: AppTheme.border, height: 24),
          _buildTeacherRoomRow(
            title: 'Vật lý – Dao động điều hòa',
            roomCode: 'PHY18',
            date: '18/08/2026',
            studentsCount: 38,
            statusLabel: 'Đã kết thúc',
            statusType: _RoomStatusType.ended,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showSnackBar('Xem tất cả phòng thi đã tạo'),
              icon: const Text(
                'Xem tất cả phòng thi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
              label: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherRoomRow({
    required String title,
    required String roomCode,
    required String date,
    required int studentsCount,
    required String statusLabel,
    required _RoomStatusType statusType,
  }) {
    Color badgeBg;
    Color badgeText;
    switch (statusType) {
      case _RoomStatusType.live:
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF166534);
        break;
      case _RoomStatusType.ended:
        badgeBg = const Color(0xFFF3F4F6);
        badgeText = const Color(0xFF6B7280);
        break;
      case _RoomStatusType.upcoming:
        badgeBg = const Color(0xFFF0ECFF);
        badgeText = AppTheme.primary;
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0ECFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.meeting_room_outlined, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mã phòng: $roomCode • $date',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          '$studentsCount học sinh',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badgeText),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => _showSnackBar('Xem kết quả phòng thi: $roomCode'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: const [
                Text(
                  'Xem kết quả',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. TEACHER EXAM SETS CARD ("📝 Bộ đề của tôi")
  // ---------------------------------------------------------------------------
  Widget _buildTeacherExamSetsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📝 Bộ đề của tôi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/create_exam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Tạo đề thi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildExamSetRow(
            title: 'Toán 12 – Hàm số',
            details: '20 câu • 30 phút • 86 lượt thi • Cập nhật 25/08/2026',
          ),
          const Divider(color: AppTheme.border, height: 24),
          _buildExamSetRow(
            title: 'Tiếng Anh – Unit 4',
            details: '30 câu • 25 phút • 54 lượt thi • Cập nhật 22/08/2026',
          ),
          const Divider(color: AppTheme.border, height: 24),
          _buildExamSetRow(
            title: 'Vật lý – Dao động điều hòa',
            details: '25 câu • 40 phút • 48 lượt thi • Cập nhật 18/08/2026',
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showSnackBar('Xem tất cả bộ đề đã tạo'),
              icon: const Text(
                'Xem tất cả bộ đề',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
              label: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamSetRow({required String title, required String details}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCE8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment_outlined, color: Color(0xFFC2410C), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                details,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () => _showSnackBar('Chỉnh sửa bộ đề: $title'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textMain,
            side: const BorderSide(color: AppTheme.border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => context.go('/create_room'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Tạo phòng →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 7. TEACHING INSIGHTS CARD ("💡 Cần chú ý")
  // ---------------------------------------------------------------------------
  Widget _buildTeacherInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Cần chú ý',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightRow('⚠️ 42% học sinh trả lời sai câu 8 trong đề Toán 12 – Hàm số.'),
          const SizedBox(height: 10),
          _buildInsightRow('🎯 Câu hỏi về đạo hàm có tỷ lệ đúng thấp nhất: 58%.'),
          const SizedBox(height: 10),
          _buildInsightRow('📈 Điểm trung bình của phòng Toán 12 gần nhất tăng 0.6 điểm.'),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textMain),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. PERSONAL INFORMATION CARD
  // ---------------------------------------------------------------------------
  Widget _buildPersonalInformationCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline_rounded, color: AppTheme.primary, size: 22),
              SizedBox(width: 10),
              Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name Field
          const Text(
            'Họ và tên',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 14),
            decoration: _buildInputDecoration(
              hintText: 'Nhập họ và tên...',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            ),
          ),

          const SizedBox(height: 18),

          // Registered Email Field
          const Text(
            'Gmail đăng ký',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            enabled: false,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            decoration: _buildInputDecoration(
              hintText: 'Gmail đăng ký',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              suffixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save Profile Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSavingInfo ? null : _handleSaveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSavingInfo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text(
                'Lưu thay đổi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. CHANGE PASSWORD CARD
  // ---------------------------------------------------------------------------
  Widget _buildChangePasswordCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 22),
              SizedBox(width: 10),
              Text(
                'Thay đổi mật khẩu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Current Password
          const Text(
            'Mật khẩu hiện tại',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _currentPasswordController,
            obscureText: _isOldPasswordObscured,
            style: const TextStyle(fontSize: 14),
            decoration: _buildInputDecoration(
              hintText: 'Nhập mật khẩu hiện tại...',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isOldPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _isOldPasswordObscured = !_isOldPasswordObscured),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // New Password
          const Text(
            'Mật khẩu mới',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPasswordController,
            obscureText: _isNewPasswordObscured,
            style: const TextStyle(fontSize: 14),
            decoration: _buildInputDecoration(
              hintText: 'Nhập mật khẩu mới...',
              prefixIcon: const Icon(Icons.key_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isNewPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _isNewPasswordObscured = !_isNewPasswordObscured),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Confirm New Password
          const Text(
            'Xác nhận mật khẩu mới',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _isConfirmPasswordObscured,
            style: const TextStyle(fontSize: 14),
            decoration: _buildInputDecoration(
              hintText: 'Nhập lại mật khẩu mới...',
              prefixIcon: const Icon(Icons.key_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Change Password Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSavingPassword ? null : _handleChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSavingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.published_with_changes_rounded, size: 18),
              label: const Text(
                'Cập nhật mật khẩu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 10. ACCOUNT ACTIONS CARD
  // ---------------------------------------------------------------------------
  Widget _buildAccountActionsCard(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                context.go('/greeting');
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'Đăng xuất',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              _showSnackBar('Vui lòng liên hệ quản trị viên để hỗ trợ xóa tài khoản',
                  isError: true);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text(
              'Xóa tài khoản',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }
}

enum _ScoreStatus { high, medium, low }
enum _RoomStatusType { live, ended, upcoming }

// Custom Painter for clean minimal chart
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final bool isStudentScore;

  _LineChartPainter({
    required this.values,
    required this.labels,
    required this.isStudentScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const lineColor = AppTheme.primary;
    const fillColor = Color(0x206557E8);

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintDot = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final paintDotInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final double stepX = size.width / (values.length - 1);
    final double minVal = isStudentScore ? 5.0 : 20.0;
    final double maxVal = isStudentScore ? 10.0 : 50.0;

    final Path path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < values.length; i++) {
      final val = values[i].clamp(minVal, maxVal);
      final normalized = (val - minVal) / (maxVal - minVal);
      final x = i * stepX;
      final y = size.height - (normalized * (size.height - 30)) - 15;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Path fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fillColor, fillColor.withValues(alpha: 0.0)],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 5, paintDot);
      canvas.drawCircle(pt, 2.5, paintDotInner);

      final textVal = isStudentScore ? values[i].toStringAsFixed(1) : '${values[i].toInt()} hs';
      textPainter.text = TextSpan(
        text: textVal,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pt.dx - textPainter.width / 2, pt.dy - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}
