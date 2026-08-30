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
                // =============================================================
                // 1. PROFILE HEADER CARD
                // =============================================================
                _buildProfileHeaderCard(authProvider, isMobile),

                const SizedBox(height: 28),

                // =============================================================
                // 2. LEARNING OVERVIEW & ACHIEVEMENTS DASHBOARD
                // =============================================================
                if (isMobile)
                  Column(
                    children: [
                      _buildLearningOverviewCard(),
                      const SizedBox(height: 24),
                      _buildAchievementsCard(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 65,
                        child: _buildLearningOverviewCard(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 35,
                        child: _buildAchievementsCard(),
                      ),
                    ],
                  ),

                const SizedBox(height: 28),

                // =============================================================
                // 3. RECENT TEST HISTORY CARD
                // =============================================================
                _buildRecentTestHistoryCard(),

                const SizedBox(height: 28),

                // =============================================================
                // 4. ACCOUNT SETTINGS CARD
                // =============================================================
                _buildPersonalInformationCard(),

                const SizedBox(height: 28),

                // =============================================================
                // 5. CHANGE PASSWORD CARD
                // =============================================================
                _buildChangePasswordCard(),

                const SizedBox(height: 28),

                // =============================================================
                // 6. ACCOUNT ACTIONS
                // =============================================================
                _buildAccountActionsCard(authProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. PROFILE HEADER CARD WIDGET
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
                _buildHeaderStats(isMobile: true),
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
                  child: _buildHeaderStats(isMobile: false),
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
              // Role badge with interactive toggle support
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

  Widget _buildHeaderStats({required bool isMobile}) {
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
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
  // 2. LEARNING OVERVIEW CARD (LEFT COLUMN)
  // ---------------------------------------------------------------------------
  Widget _buildLearningOverviewCard() {
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
                _isStudentRole ? '📊 Tổng quan học tập' : '📊 Thống kê giảng dạy',
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
                child: const Text(
                  '6 bài gần nhất',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
              painter: _ScoreChartPainter(
                scores: const [7.0, 8.0, 7.5, 9.0, 8.5, 9.2],
                labels: const ['Bài 1', 'Bài 2', 'Bài 3', 'Bài 4', 'Bài 5', 'Bài 6'],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // X-Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Bài 1', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('Bài 2', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('Bài 3', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('Bài 4', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('Bài 5', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('Bài 6', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),

          // Secondary Metrics
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0ECFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.star_rounded, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Điểm cao nhất',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '9.5',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 36, width: 1, color: AppTheme.border),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0ECFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.timer_outlined, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Tổng thời gian làm bài',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '6h 32m',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ACHIEVEMENTS CARD (RIGHT COLUMN)
  // ---------------------------------------------------------------------------
  Widget _buildAchievementsCard() {
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
          _buildAchievementItem(
            icon: '🔥',
            title: 'Chuỗi 5 bài',
            description: 'Hoàn thành bài thi 5 lần liên tiếp',
            bgColor: const Color(0xFFFFF7ED),
          ),
          const SizedBox(height: 14),
          _buildAchievementItem(
            icon: '🎯',
            title: 'Điểm tuyệt đối',
            description: 'Đạt 10 điểm một bài thi',
            bgColor: const Color(0xFFF0ECFF),
          ),
          const SizedBox(height: 14),
          _buildAchievementItem(
            icon: '⚡',
            title: 'Phản xạ nhanh',
            description: 'Trả lời nhanh 10 câu',
            bgColor: const Color(0xFFFEFCE8),
          ),
          const SizedBox(height: 14),
          _buildAchievementItem(
            icon: '🥉',
            title: 'Top 3',
            description: 'Đạt Top 3 trong phòng thi',
            bgColor: const Color(0xFFF3F4F6),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem({
    required String icon,
    required String title,
    required String description,
    required Color bgColor,
  }) {
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
          child: Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. RECENT TEST HISTORY CARD
  // ---------------------------------------------------------------------------
  Widget _buildRecentTestHistoryCard() {
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
            children: const [
              Text(
                '🕘 Bài thi gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
            ],
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
              onPressed: () {
                _showSnackBar('Tính năng xem toàn bộ lịch sử đang được phát triển');
              },
              icon: const Text(
                'Xem tất cả lịch sử',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
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
          onTap: () {
            _showSnackBar('Xem chi tiết bài thi: $title');
          },
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
  // 5. PERSONAL INFORMATION CARD
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
  // 6. CHANGE PASSWORD CARD
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
  // 7. ACCOUNT ACTIONS CARD
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
              if (context.mounted) {
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

// Custom Painter for clean minimal score chart
class _ScoreChartPainter extends CustomPainter {
  final List<double> scores;
  final List<String> labels;

  _ScoreChartPainter({required this.scores, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

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

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final double stepX = size.width / (scores.length - 1);
    const minScore = 5.0;
    const maxScore = 10.0;

    final Path path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < scores.length; i++) {
      final score = scores[i].clamp(minScore, maxScore);
      final normalized = (score - minScore) / (maxScore - minScore);
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
      colors: [fillColor, fillColor.withOpacity(0.0)],
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

      textPainter.text = TextSpan(
        text: scores[i].toStringAsFixed(1),
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
  bool shouldRepaint(covariant _ScoreChartPainter oldDelegate) => true;
}
