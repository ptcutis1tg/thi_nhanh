import 'package:flutter/material.dart';
import '../shared/widgets/top_nav_bar.dart';

class MainLayoutScreen extends StatelessWidget {
  final Widget child;

  const MainLayoutScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      body: child,
    );
  }
}
