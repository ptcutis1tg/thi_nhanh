import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/repositories/room_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/room_url_helper.dart';
import '../../shared/widgets/top_nav_bar.dart';
import 'widgets/live_leaderboard_view.dart';
import 'widgets/room_qr_dialog.dart';

class TeacherWaitingRoomScreen extends StatefulWidget {
  const TeacherWaitingRoomScreen({super.key, this.roomId});
  final String? roomId;

  @override
  State<TeacherWaitingRoomScreen> createState() =>
      _TeacherWaitingRoomScreenState();
}

class _TeacherWaitingRoomScreenState extends State<TeacherWaitingRoomScreen> {
  TeacherRoomDashboard? _room;
  Object? _error;
  bool _loading = true;
  bool _starting = false;
  bool _ending = false;
  int _selectedTab = 0; // 0: Danh sách thí sinh, 1: Bảng xếp hạng trực tiếp
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && widget.roomId != null && _selectedTab == 0 && (_room == null || _room!.isWaiting)) {
        _load(silent: true);
      }
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (widget.roomId == null) {
      if (!silent) {
        setState(() {
          _error = 'Thiếu mã phòng. Hãy tạo phòng từ trang Tạo phòng thi.';
          _loading = false;
        });
      }
      return;
    }
    if (!silent && _room == null) {
      setState(() => _loading = true);
    }
    try {
      final room = await context.read<RoomRepository>().dashboard(
        widget.roomId!,
      );
      if (mounted) {
        setState(() {
          _room = room;
          if (room.isLive && _selectedTab == 0) _selectedTab = 1;
        });
      }
    } catch (error) {
      if (mounted && !silent) setState(() => _error = error);
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _startRoom() async {
    setState(() => _starting = true);
    try {
      final room = await context.read<RoomRepository>().start(_room!.id);
      if (mounted) {
        setState(() {
          _room = room;
          _selectedTab = 1; // Switch to Live Leaderboard automatically
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Phòng đã bắt đầu! Đang theo dõi tiến độ nộp bài trực tiếp.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể bắt đầu phòng: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _closeRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc phòng thi?'),
        content: const Text(
          'Các bài đang làm sẽ được tự động nộp và kết quả sẽ được công bố cho học sinh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kết thúc và công bố'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _ending = true);
    try {
      final room = await context.read<RoomRepository>().close(_room!.id);
      if (!mounted) return;
      setState(() => _room = room);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã kết thúc phòng và công bố kết quả.')),
      );
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết thúc phòng: $message'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const TopNavBar(),
    backgroundColor: AppTheme.background,
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _ErrorState(message: _error.toString(), onRetry: _load)
        : _RoomView(
            room: _room!,
            starting: _starting,
            ending: _ending,
            selectedTab: _selectedTab,
            onTabChanged: (tab) => setState(() => _selectedTab = tab),
            onStart: _startRoom,
            onClose: _closeRoom,
            onRefresh: _load,
          ),
  );
}

class _RoomView extends StatelessWidget {
  const _RoomView({
    required this.room,
    required this.starting,
    required this.ending,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onStart,
    required this.onClose,
    required this.onRefresh,
  });

  final TeacherRoomDashboard room;
  final bool starting;
  final bool ending;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onStart;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: room.isWaiting
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          room.isWaiting
                              ? 'ĐANG CHỜ BẮT ĐẦU'
                              : (room.isLive
                                    ? 'PHÒNG THI ĐANG DIỄN RA'
                                    : 'ĐÃ KẾT THÚC'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: room.isWaiting
                                ? AppTheme.primary
                                : AppTheme.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${room.examTitle} • ${room.subject} • ${room.durationMinutes} phút',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _RoomCodeCard(code: room.code, roomName: room.name),
              ],
            ),
            const SizedBox(height: 24),

            // Mode Tabs
            Row(
              children: [
                ChoiceChip(
                  label: Text(
                    'Thí sinh (${room.participants.length}/${room.maxParticipants})',
                  ),
                  selected: selectedTab == 0,
                  onSelected: (_) => onTabChanged(0),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.leaderboard_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Bảng xếp hạng trực tiếp'),
                    ],
                  ),
                  selected: selectedTab == 1,
                  onSelected: (_) => onTabChanged(1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (selectedTab == 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.groups_outlined,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Danh sách thí sinh (${room.participants.length}/${room.maxParticipants})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Làm mới danh sách',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: room.participants.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Chưa có học sinh nào vào phòng. Hãy gửi mã phòng ở trên.',
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: room.participants.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final participant = room.participants[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                participant.name.characters.first.toUpperCase(),
                              ),
                            ),
                            title: Text(participant.name),
                            trailing: Chip(
                              label: Text(
                                _participantStatus(participant.status),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ] else ...[
              LiveLeaderboardView(roomId: room.id),
            ],

            const SizedBox(height: 28),
            if (room.isWaiting)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: starting ? null : onStart,
                  icon: starting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    starting ? 'Đang bắt đầu...' : 'Bắt đầu thi ngay',
                  ),
                ),
              ),
            if (room.isLive)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: ending ? null : onClose,
                  icon: ending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.stop_circle_outlined),
                  label: Text(
                    ending ? 'Đang kết thúc...' : 'Kết thúc và công bố kết quả',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  String _participantStatus(String value) => switch (value) {
    'waiting' => 'Đang chờ',
    'approved' => 'Đang làm bài',
    'late_join_requested' => 'Yêu cầu vào muộn',
    'submitted' => 'Đã nộp bài',
    _ => value,
  };
}

class _RoomCodeCard extends StatelessWidget {
  const _RoomCodeCard({required this.code, required this.roomName});
  final String code;
  final String roomName;

  String get _joinUrl => RoomUrlHelper.buildJoinUrl(code);

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _joinUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép liên kết vào phòng thi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPresentation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => RoomQrDialog(roomCode: code, roomName: roomName),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppTheme.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MÃ PHÒNG THI',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              InkWell(
                onTap: () => _openPresentation(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: QrImageView(
                    data: _joinUrl,
                    version: QrVersions.auto,
                    size: 52,
                    gapless: false,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openPresentation(context),
                icon: const Icon(Icons.fullscreen, size: 16),
                label: const Text('Chiếu QR', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: () => _copyLink(context),
                icon: const Icon(Icons.link, size: 16),
                tooltip: 'Sao chép liên kết vào phòng',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
