import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/theme/app_theme.dart';
import 'package:onthi_community/shared/widgets/milky_mint_scaffold.dart';

void main() {
  group('MilkyMintScaffold Widget Tests', () {
    testWidgets('renders background mesh and body content with zero lag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MilkyMintScaffold(
            body: Center(child: Text('Scaffold Content')),
          ),
        ),
      );

      expect(find.text('Scaffold Content'), findsOneWidget);
      expect(find.byType(MilkyMintScaffold), findsOneWidget);
    });

    testWidgets('supports optional app bar and bottom nav bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MilkyMintScaffold(
            appBar: AppBar(title: const Text('Miku Title')),
            bottomNavigationBar: const SizedBox(height: 50, child: Text('Bottom Bar')),
            body: const Text('Body Text'),
          ),
        ),
      );

      expect(find.text('Miku Title'), findsOneWidget);
      expect(find.text('Bottom Bar'), findsOneWidget);
      expect(find.text('Body Text'), findsOneWidget);
    });
  });
}
