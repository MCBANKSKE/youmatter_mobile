import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youmatter_mobile/core/networking/dio_client.dart';
import 'package:youmatter_mobile/core/services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final Map<String, dynamic>? user;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.user,
  });

  const AuthState.initial()
    : isLoading = false,
      isAuthenticated = false,
      error = null,
      user = null;

  const AuthState.loading()
    : isLoading = true,
      isAuthenticated = false,
      error = null,
      user = null;

  const AuthState.authenticated([this.user])
    : isLoading = false,
      isAuthenticated = true,
      error = null;

  const AuthState.error([this.error])
    : isLoading = false,
      isAuthenticated = false,
      user = null;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // When any API call returns 401 (expired/invalid token), clear the local
    // session and flip back to a signed-out state so the router redirects the
    // user to the welcome screen.
    ErrorInterceptor.onUnauthorized ??= () async {
      final authService = ref.read(authServiceProvider);
      await authService.clearLocalSession();
      state = const AuthState.initial();
    };
    return const AuthState.initial();
  }

  /// Signs in and returns `true` on success / `false` on failure.
  Future<bool> login(String email, String password) async {
    final authService = ref.read(authServiceProvider);
    state = const AuthState.loading();
    final error = await authService.login(email, password);
    if (error != null) {
      state = AuthState.error(error);
      return false;
    }
    state = AuthState.authenticated(await authService.getUserData());
    return true;
  }

  /// Creates an account and returns `true` on success / `false` on failure.
  Future<bool> register(Map<String, dynamic> data) async {
    final authService = ref.read(authServiceProvider);
    state = const AuthState.loading();
    final error = await authService.register(data);
    if (error != null) {
      state = AuthState.error(error);
      return false;
    }
    state = AuthState.authenticated(await authService.getUserData());
    return true;
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AuthState.initial();
  }

  /// Loads the persisted session (if any) at app start.
  Future<void> checkAuthStatus() async {
    final authService = ref.read(authServiceProvider);
    if (state.isLoading) {
      return;
    }
    final isAuthenticated = await authService.isAuthenticated();
    state = isAuthenticated
        ? AuthState.authenticated(await authService.getUserData())
        : const AuthState.initial();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Resolves once the persisted session (if any) has been loaded so the app can
/// present the correct first screen without flashing the welcome page to
/// users who are already signed in.
final authBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(authStateProvider.notifier).checkAuthStatus();
});
