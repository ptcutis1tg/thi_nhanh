import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/top_nav_bar.dart';
import '../shared/widgets/mobile_bottom_nav_bar.dart';
import '../shared/widgets/ai_navigation_button.dart';
import '../shared/widgets/milky_mint_scaffold.dart';

class MainLayoutScreen extends StatelessWidget {
  final Widget child;

  const MainLayoutScreen({super.key, required this.child});

  static const Set<String> _coreTabRoutes = {
    '/home',
    '/',
    '/search',
    '/teacher_exams',
    '/create_room',
    '/student/history',
  };

  @override
  Widget build(BuildContext context) {
    String currentLocation = '';
    try {
      currentLocation = GoRouterState.of(context).matchedLocation;
    } catch (_) {}

    final isCoreTab = _coreTabRoutes.contains(currentLocation) || currentLocation.isEmpty;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MilkyMintScaffold(
      appBar: const TopNavBar(),
      body: child,
      bottomNavigationBar: (isMobile && isCoreTab) ? const MobileBottomNavBar() : null,
      floatingActionButton: const AiNavigationButton(),
    );
  }
}
