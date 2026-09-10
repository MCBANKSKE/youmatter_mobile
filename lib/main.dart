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
            if (callState.status == CallStatus.connecting ||
                callState.status == CallStatus.active)
              ActiveCallScreen(
                conversationId: callState.conversationId ?? 0,
                remoteUserName: callState.remoteUserName ?? 'Anonymous',
              ),
          ],
        );
      },
    );
  }
}
