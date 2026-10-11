import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MilkyMintScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showAmbientGlow;
  final bool showCloudTexture;

  const MilkyMintScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showAmbientGlow = true,
    this.showCloudTexture = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Miku Dreamy Cloud Texture Layer
          if (showCloudTexture)
            Positioned.fill(
              child: RepaintBoundary(
                child: Opacity(
                  opacity: 0.25,
                  child: Image.asset(
                    'assets/images/miku_cloud_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // 2. Top-Right Cyber-Aqua Ambient Glow
          if (showAmbientGlow) ...[
            Positioned(
              top: -80,
              right: -80,
              child: RepaintBoundary(
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.22),
                        AppTheme.primaryLight.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // 3. Bottom-Left Soft Mint Ambient Glow
            Positioned(
              bottom: -100,
              left: -100,
              child: RepaintBoundary(
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentCyan.withValues(alpha: 0.15),
                        AppTheme.primaryContainer.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 4. Foreground Content
          SafeArea(child: body),
        ],
      ),
    );
  }
}
