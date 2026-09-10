import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/authentication/providers/auth_provider.dart';
import '../features/welcome/presentation/screens/welcome_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/register_screen.dart';
import '../features/profile/presentation/screens/profile_setup_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/talk_requests/presentation/screens/talk_requests_screen.dart';
import '../features/matching/presentation/screens/matching_screen.dart';
import '../features/conversations/presentation/screens/conversations_list_screen.dart';
import '../features/messages/presentation/screens/chat_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/safety/presentation/screens/safety_screen.dart';
import '../features/professional/presentation/screens/professional_screen.dart';
import '../features/calling/presentation/screens/active_call_screen.dart';
import '../features/calling/presentation/screens/outgoing_call_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.uri.path.isEmpty
          ? '/'
          : state.uri.path;

      if (location == '/') {
        return authState.isAuthenticated ? '/home' : '/welcome';
      }

      final bool isPublicRoute =
          location == '/welcome' ||
          location == '/login' ||
          location == '/register';

      if (authState.isAuthenticated && isPublicRoute) {
        return '/home';
      }
      if (!authState.isAuthenticated && !isPublicRoute) {
        return '/welcome';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/talk-requests',
        builder: (context, state) => const TalkRequestsScreen(),
      ),
      GoRoute(
        path: '/matching',
        builder: (context, state) => const MatchingScreen(),
      ),
      GoRoute(
        path: '/conversations',
        builder: (context, state) => const ConversationsListScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final conversationId =
              state.pathParameters['conversationId'] ?? '';
          return ChatScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/call/outgoing/:conversationId',
        builder: (context, state) {
          final conversationId =
              state.pathParameters['conversationId'] ?? '';
          return OutgoingCallScreen(
            conversationId: int.parse(conversationId),
            remoteUserName: 'Listener',
          );
        },
      ),
      GoRoute(
        path: '/call/active/:conversationId',
        builder: (context, state) {
          final conversationId =
              state.pathParameters['conversationId'] ?? '';
          return ActiveCallScreen(
            conversationId: int.parse(conversationId),
            remoteUserName: 'Listener',
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/professional',
        builder: (context, state) => const ProfessionalScreen(),
      ),
    ],
  );
});
