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
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await ref.read(authStateProvider.notifier).checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    // The welcome page uses a fixed light gradient background so that the
    // logo's dark-blue elements ("MATTER" text) remain visible regardless of
    // the device's theme setting (ThemeMode.system in main.dart).
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Decorative favicon accent
                Center(
                  child: Image.asset(
                    'youmatterfavicon.png',
                    height: 40,
                  ),
                ),
                const SizedBox(height: 24),
                // Logo on a white card so dark-blue logo elements are always
                // clearly visible against the light gradient background.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'youmatterlogo.png',
                    height: 140,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Talk. Listen. Connect.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const Spacer(),
                Text(
                  'A place to be heard.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'YouMatter connects people who want someone to talk to '
                  'with people willing to listen.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'YouMatter is not a crisis or emergency service.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.go('/register?intent=talk'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  ),
                  child: const Text('I want to listen'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
