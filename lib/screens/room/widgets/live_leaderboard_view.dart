import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/room_repository.dart';

class LiveLeaderboardView extends StatefulWidget {
  const LiveLeaderboardView({
    super.key,
    required this.roomId,
    this.initialEntries,
    this.autoRefresh = true,
  });

  final String roomId;
  final List<RoomLeaderboardEntry>? initialEntries;
  final bool autoRefresh;

  @override
  State<LiveLeaderboardView> createState() => _LiveLeaderboardViewState();
}

class _LiveLeaderboardViewState extends State<LiveLeaderboardView> {
  static const double _leaderboardRowHeight = 54;
  static const Duration _reorderDuration = Duration(milliseconds: 650);

  List<RoomLeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEntries != null) {
      _entries = widget.initialEntries!;
      _isLoading = false;
    } else {
      _fetchLeaderboard();
    }

    if (widget.autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) _fetchLeaderboard(silent: true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiveLeaderboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEntries != null &&
        widget.initialEntries != oldWidget.initialEntries) {
      setState(() {
        _entries = widget.initialEntries!;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLeaderboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repo = context.read<RoomRepository?>();
      if (repo == null) {
        if (!silent) setState(() => _isLoading = false);
        return;
      }

      final list = await repo.getRoomLeaderboard(widget.roomId);
      if (mounted) {
        setState(() {
          _entries = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null && _entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 36),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _fetchLeaderboard(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu bảng xếp hạng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Thí sinh hoàn thành bài thi sẽ xuất hiện tại đây.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top 3 Podium Cards if at least 1 entry exists
        if (_entries.isNotEmpty) _buildPodium(),
        const SizedBox(height: 24),

        // Full Leaderboard Table / List
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 44,
                      child: Text(
                        'HẠNG',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'THÍ SINH',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'TRẠNG THÁI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'CÂU ĐÚNG',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'THỜI GIAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 60,
                      child: Text(
                        'ĐIỂM',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.border),
              SizedBox(
                height: _entries.length * _leaderboardRowHeight,
                child: Stack(
                  children: [
                    for (var index = 0; index < _entries.length; index++)
                      AnimatedPositioned(
                        key: ValueKey(
                          'leaderboard-position-${_entries[index].participantId}',
                        ),
                        duration: _reorderDuration,
                        curve: Curves.easeInOutCubic,
                        top: index * _leaderboardRowHeight,
                        left: 0,
                        right: 0,
                        height: _leaderboardRowHeight,
                        child: _AnimatedLeaderboardRow(entry: _entries[index]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodium() {
    final top1 = _entries.isNotEmpty ? _entries[0] : null;
    final top2 = _entries.length > 1 ? _entries[1] : null;
    final top3 = _entries.length > 2 ? _entries[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top2 != null)
          Expanded(
            child: _buildPodiumItem(top2, 2, const Color(0xFFC0C0C0), 140),
          ),
        if (top1 != null)
          Expanded(
            child: _buildPodiumItem(top1, 1, const Color(0xFFFFD700), 165),
          ),
        if (top3 != null)
          Expanded(
            child: _buildPodiumItem(top3, 3, const Color(0xFFCD7F32), 125),
          ),
      ],
    );
  }

  Widget _buildPodiumItem(
    RoomLeaderboardEntry entry,
    int rank,
    Color medalColor,
    double height,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: medalColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: medalColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events, color: medalColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.score.toStringAsFixed(1)} đ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: medalColor == const Color(0xFFFFD700)
                  ? AppTheme.primary
                  : AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.durationFormatted,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLeaderboardRow extends StatefulWidget {
  const _AnimatedLeaderboardRow({required this.entry});

  final RoomLeaderboardEntry entry;

  @override
  State<_AnimatedLeaderboardRow> createState() =>
      _AnimatedLeaderboardRowState();
}

class _AnimatedLeaderboardRowState extends State<_AnimatedLeaderboardRow> {
  Timer? _highlightTimer;
  bool _highlighted = false;

  @override
  void didUpdateWidget(covariant _AnimatedLeaderboardRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final improved =
        widget.entry.correctCount > oldWidget.entry.correctCount ||
        widget.entry.rank < oldWidget.entry.rank;
    if (improved) {
      _highlightTimer?.cancel();
      setState(() => _highlighted = true);
      _highlightTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _highlighted = false);
      });
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    Color? rankBadgeColor;
    if (entry.rank == 1) rankBadgeColor = const Color(0xFFFFD700);
    if (entry.rank == 2) rankBadgeColor = const Color(0xFFC0C0C0);
    if (entry.rank == 3) rankBadgeColor = const Color(0xFFCD7F32);

    return AnimatedContainer(
      key: ValueKey('leaderboard-row-${entry.participantId}'),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: _highlighted
            ? AppTheme.success.withValues(alpha: 0.12)
            : Colors.white,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: rankBadgeColor != null
                ? AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rankBadgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '${entry.rank}',
                        key: ValueKey(entry.rank),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '#${entry.rank}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: entry.isSubmitted
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.isSubmitted ? 'Đã nộp' : 'Đang làm',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: entry.isSubmitted
                        ? AppTheme.success
                        : AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: entry.correctCount.toDouble()),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => Text(
                '${value.round()}/${entry.totalQuestions}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.durationFormatted,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: entry.score),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => Text(
                value.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
