import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/providers/auth_provider.dart';
import 'features/calling/models/call_state.dart';
import 'features/calling/presentation/screens/active_call_screen.dart';
import 'features/calling/presentation/screens/incoming_call_screen.dart';
import 'features/calling/presentation/screens/outgoing_call_screen.dart';
import 'features/calling/providers/call_state_provider.dart';
import 'navigation/app_router.dart';

// NOTE: local notifications are temporarily disabled (build issues with
// flutter_local_notifications). Re-enable together with:
//  - pubspec: flutter_local_notifications + timezone
//  - android/app/build.gradle.kts: coreLibraryDesugaring (already configured)
//  - android manifest notification permissions (already configured)
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   LocalNotificationService.instance.initialize();
//   runApp(const ProviderScope(child: MyApp()));
// }
void main() {
  // Ensure Flutter bindings are initialized before running the app.
  // This is required for some plugins (like path_provider) to work properly.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wait until the persisted session has been loaded so already signed-in
    // users land directly on the home screen instead of flashing the welcome
    // page.
    final bootstrap = ref.watch(authBootstrapProvider);
        final router = ref.watch(routerProvider);
    final callState = ref.watch(callStateProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      restorationScopeId: 'app',
            builder: (context, child) {
        if (bootstrap.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // Active calls and incoming/outgoing ringing screens are
            // rendered here so they can surface from anywhere in the app.
            if (callState.status == CallStatus.ringing && callState.isIncoming)
              IncomingCallScreen(
                callId: callState.callId ?? 0,
                conversationId: callState.conversationId ?? 0,
                remoteUserName: callState.remoteUserName ?? 'Anonymous',
              ),
            if (callState.status == CallStatus.ringing && !callState.isIncoming)
              OutgoingCallScreen(
                conversationId: callState.conversationId ?? 0,
                remoteUserName: callState.remoteUserName ?? 'Anonymous',
              ),
            // Show connecting screen while waiting for call to connect
            if (callState.status == CallStatus.connecting)
              _ConnectingCallScreen(
                conversationId: callState.conversationId ?? 0,
                remoteUserName: callState.remoteUserName ?? 'Anonymous',
              ),
            if (callState.status == CallStatus.active)
              ActiveCallScreen(
                conversationId: callState.conversationId ?? 0,
                remoteUserName: callState.remoteUserName ?? 'Anonymous',
              ),
            // Show error message if call failed
            if (callState.status == CallStatus.ended && callState.errorMessage != null)
              _CallErrorScreen(
                errorMessage: callState.errorMessage!,
                onDismiss: () {
                  ref.read(callStateProvider.notifier).reset();
                },
              ),
          ],
        );
      },
    );
  }
}

/// Screen shown while connecting a call
class _ConnectingCallScreen extends StatelessWidget {
  final int conversationId;
  final String remoteUserName;

  const _ConnectingCallScreen({
    required this.conversationId,
    required this.remoteUserName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Connecting...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 60,
              child: Text(
                remoteUserName.characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              remoteUserName,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Listener',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Screen shown when a call fails
class _CallErrorScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onDismiss;

  const _CallErrorScreen({
    required this.errorMessage,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Call Failed',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onDismiss,
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
