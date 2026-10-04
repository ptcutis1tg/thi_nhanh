import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 28,
              vertical: 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
