import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/room_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/top_nav_bar.dart';

class TeacherWaitingRoomScreen extends StatefulWidget {
  const TeacherWaitingRoomScreen({super.key, this.roomId});
  final String? roomId;

  @override
  State<TeacherWaitingRoomScreen> createState() => _TeacherWaitingRoomScreenState();
}

class _TeacherWaitingRoomScreenState extends State<TeacherWaitingRoomScreen> {
  TeacherRoomDashboard? _room;
  Object? _error;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.roomId == null) {
      setState(() {
        _error = 'Thiếu mã phòng. Hãy tạo phòng từ trang Tạo phòng thi.';
        _loading = false;
      });
      return;
    }
    try {
      final room = await context.read<RoomRepository>().dashboard(widget.roomId!);
      if (mounted) setState(() => _room = room);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startRoom() async {
    setState(() => _starting = true);
    try {
      final room = await context.read<RoomRepository>().start(_room!.id);
      if (mounted) {
        setState(() => _room = room);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phòng đã bắt đầu. Học sinh đã được tạo lượt làm bài.')),
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu phòng: $error'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
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
                : _RoomView(room: _room!, starting: _starting, onStart: _startRoom, onRefresh: _load),
      );
}

class _RoomView extends StatelessWidget {
  const _RoomView({required this.room, required this.starting, required this.onStart, required this.onRefresh});
  final TeacherRoomDashboard room;
  final bool starting;
  final VoidCallback onStart;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Chip(label: Text(room.isWaiting ? 'ĐANG CHỜ' : 'ĐANG DIỄN RA')),
                  const SizedBox(height: 8),
                  Text(room.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${room.examTitle} • ${room.subject} • ${room.durationMinutes} phút', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                ])),
                _RoomCodeCard(code: room.code),
              ]),
              const SizedBox(height: 28),
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
                const Icon(Icons.groups_outlined, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Học sinh đã tham gia (${room.participants.length}/${room.maxParticipants})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh), tooltip: 'Làm mới danh sách'),
              ]))),
              const SizedBox(height: 12),
              Card(child: room.participants.isEmpty
                  ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Chưa có học sinh nào vào phòng. Hãy gửi mã phòng ở trên.')))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: room.participants.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final participant = room.participants[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(participant.name.characters.first.toUpperCase())),
                          title: Text(participant.name),
                          trailing: Chip(label: Text(_participantStatus(participant.status))),
                        );
                      },
                    )),
              const SizedBox(height: 28),
              if (room.isWaiting)
                SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(onPressed: starting ? null : onStart, icon: starting ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow), label: Text(starting ? 'Đang bắt đầu...' : 'Bắt đầu làm bài')))
              else
                const Center(child: Text('Phòng đã bắt đầu. Thời gian làm bài được tính cho từng lượt đã tạo.', style: TextStyle(color: AppTheme.success))),
            ]),
          ),
        ),
      );

  String _participantStatus(String value) => switch (value) {
        'waiting' => 'Đang chờ',
        'approved' => 'Đã vào thi',
        'late_join_requested' => 'Yêu cầu vào muộn',
        _ => value,
      };
}

class _RoomCodeCard extends StatelessWidget {
  const _RoomCodeCard({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    const Text('MÃ PHÒNG THI', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text(code, style: const TextStyle(fontSize: 30, color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 2)),
  ])));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
    const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12),
    OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
  ])));
}
