import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/theme/app_theme.dart';
import 'package:youmatter_mobile/features/authentication/providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// Drives the entrance cross-fade: starts showing the empty placeholder and,
  /// a moment after the first frame, switches to reveal the real content.
  CrossFadeState _fadeState = CrossFadeState.showFirst;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _playEntrance();
  }

  Future<void> _checkAuthStatus() async {
    await ref.read(authStateProvider.notifier).checkAuthStatus();
  }

  Future<void> _playEntrance() async {
    await Future.delayed(const Duration(milliseconds: 200), (() => 0));
    _fadeState = CrossFadeState.showSecond;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // The welcome page uses a fixed, warm "dark cream" gradient background so
    // that the logo's dark-blue ("MATTER") elements remain clearly visible and
    // flattering regardless of the device's theme setting (ThemeMode.system).
    final Widget content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Small favicon as a soft brand accent above the logo.
            Center(child: Image.asset('youmatterfavicon.png', height: 36)),
            const SizedBox(height: 28),
            // The logo rests on a warm ivory card with rounded corners so
            // the dark-blue logo elements always sit on a clean surface.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.welcomeCardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Image.asset('youmatterlogo.png', height: 132),
            ),
            const SizedBox(height: 32),
            // The logo image already carries the brand tagline
            // ("Talk. Be Heard. You Matter."), so the copy below is kept to
            // a gentle single welcome line rather than a repeat.
            Text(
              "We're glad you're here.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => context.go('/register?intent=talk'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('I want to talk'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/register?intent=listen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('I want to listen'),
            ),
            const SizedBox(height: 20),
            Text(
              'YouMatter is not a crisis or emergency service.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Layered warm "dark cream" gradient.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.welcomeBackgroundStart,
                    AppTheme.welcomeBackgroundEnd,
                  ],
                ),
              ),
            ),
          ),
          // Soft ambient brand color blobs for a calm, modern backdrop.
          Positioned(
            left: -48,
            top: -64,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
          Positioned(
            right: -48,
            bottom: -72,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(130),
              ),
            ),
          ),
          // The main content fades (and gently grows) in on load.
          AnimatedCrossFade(
            crossFadeState: _fadeState,
            duration: const Duration(milliseconds: 550),
            secondCurve: Curves.fastOutSlowIn,
            sizeCurve: Curves.fastOutSlowIn,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: content,
          ),
        ],
      ),
    );
  }
}
