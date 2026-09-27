import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/room/widgets/live_leaderboard_view.dart';

void main() {
  testWidgets('renders LiveLeaderboardView with podium and entries', (
    tester,
  ) async {
    final entries = [
      const RoomLeaderboardEntry(
        rank: 1,
        participantId: 'p-1',
        name: 'Trần Văn Hoàng',
        status: 'submitted',
        score: 10.0,
        correctCount: 40,
        totalQuestions: 40,
        durationSeconds: 1200,
        submittedAt: '2026-09-03T20:00:00Z',
      ),
      const RoomLeaderboardEntry(
        rank: 2,
        participantId: 'p-2',
        name: 'Lê Thùy Dung',
        status: 'submitted',
        score: 9.0,
        correctCount: 36,
        totalQuestions: 40,
        durationSeconds: 1400,
        submittedAt: '2026-09-03T20:05:00Z',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveLeaderboardView(
            roomId: 'room-1',
            initialEntries: entries,
            autoRefresh: false,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Trần Văn Hoàng'), findsWidgets);
    expect(find.text('Lê Thùy Dung'), findsWidgets);
    expect(find.text('10.0 đ'), findsOneWidget);
    expect(find.text('9.0 đ'), findsOneWidget);
    expect(find.text('Đã nộp'), findsWidgets);
  });

  testWidgets('animates rows when live ranks change', (tester) async {
    final key = GlobalKey<_LeaderboardHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _LeaderboardHarness(key: key)));
    await tester.pumpAndSettle();

    final firstRow = find.byKey(const ValueKey('leaderboard-row-p-1'));
    final initialY = tester.getTopLeft(firstRow).dy;

    key.currentState!.swapRanks();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));
    final movingY = tester.getTopLeft(firstRow).dy;
    await tester.pumpAndSettle();
    final finalY = tester.getTopLeft(firstRow).dy;

    expect(movingY, greaterThan(initialY));
    expect(movingY, lessThan(finalY));
  });
}

class _LeaderboardHarness extends StatefulWidget {
  const _LeaderboardHarness({super.key});

  @override
  State<_LeaderboardHarness> createState() => _LeaderboardHarnessState();
}

class _LeaderboardHarnessState extends State<_LeaderboardHarness> {
  var entries = _entries(swapped: false);

  void swapRanks() => setState(() => entries = _entries(swapped: true));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LiveLeaderboardView(
      roomId: 'room-1',
      initialEntries: entries,
      autoRefresh: false,
    ),
  );
}

List<RoomLeaderboardEntry> _entries({required bool swapped}) {
  final first = RoomLeaderboardEntry(
    rank: swapped ? 2 : 1,
    participantId: 'p-1',
    name: 'Học sinh 1',
    status: 'in_progress',
    score: swapped ? 1 : 0,
    correctCount: swapped ? 1 : 0,
    totalQuestions: 10,
  );
  final second = RoomLeaderboardEntry(
    rank: swapped ? 1 : 2,
    participantId: 'p-2',
    name: 'Học sinh 2',
    status: 'in_progress',
    score: swapped ? 2 : 0,
    correctCount: swapped ? 2 : 0,
    totalQuestions: 10,
  );
  return swapped ? [second, first] : [first, second];
}
