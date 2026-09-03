import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/room/widgets/live_leaderboard_view.dart';

void main() {
  testWidgets('renders LiveLeaderboardView with podium and entries', (tester) async {
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
}
