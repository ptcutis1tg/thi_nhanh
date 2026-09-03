import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/repositories/room_repository.dart';
import '../../shared/widgets/top_nav_bar.dart';

class StudentWaitingRoomScreen extends StatefulWidget {
  const StudentWaitingRoomScreen({
    super.key,
    this.roomId,
    this.participantId,
    this.guestToken,
  });

  final String? roomId;
  final String? participantId;
  final String? guestToken;

  @override
  State<StudentWaitingRoomScreen> createState() => _StudentWaitingRoomScreenState();
}

class _StudentWaitingRoomScreenState extends State<StudentWaitingRoomScreen> {
  StudentRoomState? _roomState;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && widget.roomId != null && widget.participantId != null) {
        _pollState();
      }
    });
  }

  Future<void> _loadState() async {
    if (widget.roomId == null || widget.participantId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final repo = context.read<RoomRepository?>();
      if (repo == null) {
        setState(() => _isLoading = false);
        return;
      }
      final state = await repo.getStudentRoomState(
        roomId: widget.roomId!,
        participantId: widget.participantId!,
        guestToken: widget.guestToken,
      );
      if (mounted) {
        setState(() {
          _roomState = state;
          _isLoading = false;
        });
        _checkAndTransitionToExam(state);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pollState() async {
    try {
      final repo = context.read<RoomRepository?>();
      if (repo == null) return;
      final state = await repo.getStudentRoomState(
        roomId: widget.roomId!,
        participantId: widget.participantId!,
        guestToken: widget.guestToken,
      );
      if (mounted) {
        setState(() {
          _roomState = state;
        });
        _checkAndTransitionToExam(state);
      }
    } catch (_) {}
  }

  void _checkAndTransitionToExam(StudentRoomState state) {
    if (state.isLive && state.attemptId != null) {
      _pollingTimer?.cancel();
      context.go('/taking_exam?attemptId=${state.attemptId}&roomId=${widget.roomId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Hero Banner
                      _buildHeroBanner(),
                      const SizedBox(height: 32),

                      // Info Grid
                      _buildInfoGrid(),
                      const SizedBox(height: 32),

                      // Participants Section
                      _buildParticipantsSection(),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_roomState?.attemptId != null) {
            context.go('/taking_exam?attemptId=${_roomState!.attemptId}&roomId=${widget.roomId}');
          } else {
            context.go('/taking_exam');
          }
        },
        backgroundColor: AppTheme.success,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Mô phỏng: Bắt đầu thi'),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final title = _roomState?.examTitle ?? _roomState?.name ?? 'Phòng thi trực tuyến';
    final isLive = _roomState?.isLive ?? false;

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: isLive ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isLive ? Icons.check_circle_outline : Icons.hourglass_bottom,
            color: isLive ? AppTheme.success : AppTheme.primary,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isLive
              ? 'Phòng thi đã bắt đầu! Đang chuẩn bị bài làm...'
              : 'Đang chờ giáo viên mở phòng thi. Vui lòng giữ màn hình này và chuẩn bị sẵn sàng.',
          style: TextStyle(
            fontSize: 16,
            color: isLive ? AppTheme.success : AppTheme.textSecondary,
            fontWeight: isLive ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    final code = _roomState?.code ?? 'PT892341';
    final duration = _roomState != null ? '${_roomState!.durationMinutes} phút' : '45 phút';
    final teacher = _roomState?.teacherName ?? 'Giáo viên';
    final subject = _roomState?.subject ?? 'Toán học';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final codeCard = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'MÃ PHÒNG THI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  code,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã phòng vào clipboard')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Sao chép mã'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ],
          ),
        );

        final detailsCard = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin bài thi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(height: 32, color: AppTheme.border),
              Wrap(
                spacing: 20,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isCompact ? constraints.maxWidth : 180,
                    child: _buildInfoItem(Icons.schedule, 'Thời gian làm bài', duration),
                  ),
                  SizedBox(
                    width: isCompact ? constraints.maxWidth : 180,
                    child: _buildInfoItem(Icons.category_outlined, 'Môn học', subject),
                  ),
                  SizedBox(
                    width: isCompact ? constraints.maxWidth : 180,
                    child: _buildInfoItem(Icons.school_outlined, 'Giáo viên coi thi', teacher),
                  ),
                  SizedBox(
                    width: isCompact ? constraints.maxWidth : 180,
                    child: _buildInfoItem(Icons.rule, 'Quy chế', 'Không thoát màn hình', isError: true),
                  ),
                ],
              ),
            ],
          ),
        );

        if (isCompact) {
          return Column(
            children: [
              codeCard,
              const SizedBox(height: 24),
              detailsCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: codeCard),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: detailsCard),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              isError
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(value, style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  : Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    final participants = _roomState?.participants ?? const [];
    final count = _roomState?.participantCount ?? (participants.isNotEmpty ? participants.length : 1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Học sinh trong phòng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count học sinh đã sẵn sàng',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppTheme.border),
          participants.isEmpty
              ? Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _buildAvatarItem('Bạn', 'B', isSelf: true),
                    _buildAvatarItem('Minh Anh', 'MA'),
                    _buildAvatarItem('Hải Bình', 'HB'),
                    _buildAvatarItem('Tiến Cường', 'TC'),
                  ],
                )
              : Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: participants.map((p) {
                    final initials = p.name.trim().isNotEmpty
                        ? p.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                        : 'HS';
                    return _buildAvatarItem(p.name, initials, isSelf: p.isSelf);
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildAvatarItem(String name, String initials, {bool isSelf = false, bool isConnecting = false}) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConnecting
                    ? AppTheme.background
                    : (isSelf ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isConnecting ? AppTheme.border : (isSelf ? AppTheme.primary : AppTheme.border),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isConnecting
                  ? const Icon(Icons.person_outline, color: AppTheme.textSecondary)
                  : Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelf ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
            ),
            if (!isConnecting)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
            fontStyle: isConnecting ? FontStyle.italic : FontStyle.normal,
            color: isConnecting ? AppTheme.textSecondary : AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}
