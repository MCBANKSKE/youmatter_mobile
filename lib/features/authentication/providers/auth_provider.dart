import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youmatter_mobile/core/services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  const AuthState.initial()
      : isLoading = false,
        isAuthenticated = false,
        error = null;

  const AuthState.loading()
      : isLoading = true,
        isAuthenticated = false,
        error = null;

  const AuthState.authenticated()
      : isLoading = false,
        isAuthenticated = true,
        error = null;

  const AuthState.error([this.error])
      : isLoading = false,
        isAuthenticated = false;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState.initial();
  }

  Future<void> login(String email, String password) async {
    final authService = ref.read(authServiceProvider);
    state = const AuthState.loading();
    final success = await authService.login(email, password);
    state = success ? const AuthState.authenticated() : const AuthState.error();
  }

  Future<void> register(Map<String, dynamic> data) async {
    final authService = ref.read(authServiceProvider);
    state = const AuthState.loading();
    final success = await authService.register(data);
    state = success ? const AuthState.authenticated() : const AuthState.error();
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AuthState.initial();
  }

  Future<void> checkAuthStatus() async {
    final authService = ref.read(authServiceProvider);
    final isAuthenticated = await authService.isAuthenticated();
    state = isAuthenticated ? const AuthState.authenticated() : const AuthState.initial();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
