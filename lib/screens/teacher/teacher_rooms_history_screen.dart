import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/google_pagination_bar.dart';

class TeacherRoomsHistoryScreen extends StatefulWidget {
  final List<TeacherRoomData>? testRooms;
  const TeacherRoomsHistoryScreen({super.key, this.testRooms});

  @override
  State<TeacherRoomsHistoryScreen> createState() => _TeacherRoomsHistoryScreenState();
}

class _TeacherRoomsHistoryScreenState extends State<TeacherRoomsHistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  List<TeacherRoomData> _allRooms = [];
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'live', 'waiting', 'closed'
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    if (widget.testRooms != null) {
      setState(() {
        _allRooms = widget.testRooms!;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final rooms = await ProfileService.fetchTeacherRoomsSecure(
      userId: auth.user?.id,
      userEmail: auth.userEmail,
      userName: auth.userName,
    );
    if (mounted) {
      setState(() {
        _allRooms = rooms;
        _isLoading = false;
      });
    }
  }

  List<TeacherRoomData> get _filteredRooms {
    return _allRooms.where((room) {
      // 1. Status Filter
      if (_statusFilter == 'live' && room.statusType != 'live') return false;
      if (_statusFilter == 'waiting' &&
          room.statusType != 'waiting' &&
          room.statusType != 'upcoming') {
        return false;
      }
      if (_statusFilter == 'closed' &&
          room.statusType != 'closed' &&
          room.statusType != 'ended') {
        return false;
      }

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = room.title.toLowerCase().contains(query);
        final matchesCode = room.roomCode.toLowerCase().contains(query);
        final matchesExam =
            room.examTitle != null && room.examTitle!.toLowerCase().contains(query);
        final matchesSubject =
            room.examSubject != null && room.examSubject!.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCode && !matchesExam && !matchesSubject) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final filtered = _filteredRooms;
          final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
          final pagedRooms =
              filtered.skip((_currentPage - 1) * _pageSize).take(_pageSize).toList();

          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 28,
              vertical: compact ? 16 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    _buildHeader(compact),
                    const SizedBox(height: 20),

                    // Search Box
                    _buildSearchBox(),
                    const SizedBox(height: 16),

                    // Status Tabs
                    _buildStatusTabs(compact),
                    const SizedBox(height: 20),

                    // Room Count Indicator
                    _buildCountIndicator(filtered.length),
                    const SizedBox(height: 16),

                    // Room List or Empty/Loading State
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      )
                    else if (filtered.isEmpty)
                      _buildEmptyState()
                    else ...[
                      for (final room in pagedRooms) ...[
                        _buildRoomCard(room, compact),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 16),
                      if (totalPages > 1)
                        GooglePaginationBar(
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          onPageChanged: (page) {
                            setState(() => _currentPage = page);
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
          tooltip: 'Quay lại',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '🏛️ Quản Lý Phòng Thi Đã Tạo',
            style: TextStyle(
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMain,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => context.go('/create_room'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 18,
              vertical: compact ? 10 : 12,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            compact ? 'Tạo phòng' : 'Tạo phòng mới',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6FC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const Key('teacher-rooms-search-field'),
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên phòng, mã code, đề thi...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                  _currentPage = 1;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
              tooltip: 'Xóa tìm kiếm',
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _currentPage = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(bool compact) {
    final tabs = [
      {'key': 'all', 'label': 'Tất cả', 'icon': Icons.all_inclusive_rounded},
      {'key': 'live', 'label': 'Đang diễn ra', 'icon': Icons.bolt_rounded},
      {'key': 'waiting', 'label': 'Đang chờ', 'icon': Icons.hourglass_top_rounded},
      {'key': 'closed', 'label': 'Đã kết thúc', 'icon': Icons.check_circle_outline_rounded},
    ];

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEBE6FC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: tabs.map((tab) {
              final key = tab['key'] as String;
              final label = tab['label'] as String;
              final icon = tab['icon'] as IconData;
              final isSelected = _statusFilter == key;
              return InkWell(
                onTap: () => setState(() {
                  _statusFilter = key;
                  _currentPage = 1;
                }),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE6FC)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final key = tab['key'] as String;
          final label = tab['label'] as String;
          final icon = tab['icon'] as IconData;
          final isSelected = _statusFilter == key;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _statusFilter = key;
                _currentPage = 1;
              }),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountIndicator(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hiển thị $count phòng thi',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        if (_searchQuery.isNotEmpty || _statusFilter != 'all')
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _statusFilter = 'all';
                _currentPage = 1;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.primary),
            label: const Text(
              'Đặt lại bộ lọc',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildRoomCard(TeacherRoomData room, bool compact) {
    final isLive = room.statusType == 'live';
    final isWaiting = room.statusType == 'waiting' || room.statusType == 'upcoming';
    final isClosed = room.statusType == 'closed' || room.statusType == 'ended';

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    if (isLive) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeBorder = const Color(0xFFBBF7D0);
      badgeText = const Color(0xFF166534);
      badgeIcon = Icons.fiber_manual_record_rounded;
      badgeLabel = 'Đang diễn ra';
    } else if (isWaiting) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeBorder = const Color(0xFFFDE68A);
      badgeText = const Color(0xFFB45309);
      badgeIcon = Icons.hourglass_top_rounded;
      badgeLabel = 'Đang chờ';
    } else {
      badgeBg = const Color(0xFFF3F4F6);
      badgeBorder = const Color(0xFFE5E7EB);
      badgeText = const Color(0xFF4B5563);
      badgeIcon = Icons.check_circle_outline_rounded;
      badgeLabel = 'Đã kết thúc';
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBE6FC)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToRoom(room),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Status Badge + Room Code (with 1-click copy)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: badgeText),
                        const SizedBox(width: 4),
                        Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: badgeText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: room.roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép mã phòng ${room.roomCode}'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EDFD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 13, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            room.roomCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                room.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 8),

              // Metadata Tags (Date, Students count, Exam Title, Duration)
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        room.date,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${room.studentsCount} thí sinh',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  if (room.examTitle != null && room.examTitle!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined, size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          room.examTitle!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  if (room.durationMinutes != null && room.durationMinutes! > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${room.durationMinutes} phút',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Contextual Action Button
              Align(
                alignment: Alignment.centerRight,
                child: _buildActionButton(room, isLive, isWaiting, isClosed, compact),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    TeacherRoomData room,
    bool isLive,
    bool isWaiting,
    bool isClosed,
    bool compact,
  ) {
    if (isLive) {
      return ElevatedButton.icon(
        onPressed: () => _navigateToRoom(room),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        icon: const Icon(Icons.dashboard_outlined, size: 16),
        label: const Text(
          'Bảng theo dõi trực tiếp',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    if (isWaiting) {
      return ElevatedButton.icon(
        onPressed: () => _navigateToRoom(room),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        icon: const Icon(Icons.meeting_room_outlined, size: 16),
        label: const Text(
          'Vào phòng chờ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    // isClosed
    return OutlinedButton.icon(
      onPressed: () => _navigateToRoom(room),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: Color(0xFFDDD6FE)),
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.leaderboard_outlined, size: 16),
      label: const Text(
        'Bảng xếp hạng & Kết quả',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  void _navigateToRoom(TeacherRoomData room) {
    final isWaiting = room.statusType == 'waiting' || room.statusType == 'upcoming';
    if (isWaiting) {
      context.go('/teacher_waiting_room?roomId=${Uri.encodeComponent(room.id)}');
    } else {
      context.go('/live_dashboard?code=${Uri.encodeComponent(room.roomCode)}');
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6FC)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1EDFD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy phòng thi nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thử thay đổi từ khóa tìm kiếm hoặc chọn bộ lọc trạng thái khác',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isNotEmpty || _statusFilter != 'all')
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _statusFilter = 'all';
                    _currentPage = 1;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Đặt lại bộ lọc'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => context.go('/create_room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tạo phòng ngay'),
              ),
          ],
        ),
      ),
    );
  }
}
