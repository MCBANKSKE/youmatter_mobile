import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/features/authentication/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _random = Random();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  static const List<String> _adjectives = [
    'Quiet',
    'Gentle',
    'Kind',
    'Calm',
    'Bright',
    'Warm',
    'Sunny',
    'Soft',
    'Brave',
    'Happy',
  ];

  static const List<String> _nouns = [
    'Fox',
    'Owl',
    'Bear',
    'Deer',
    'Wren',
    'Lynx',
    'Tiger',
    'Dove',
    'Lark',
    'Panda',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController.text = _generateAnonymousUsername();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  /// A random, anonymous handle that is unrelated to the user's email so it
  /// doesn't reveal identity. It's pre-filled but editable.
  String _generateAnonymousUsername() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final noun = _nouns[_random.nextInt(_nouns.length)];
    final code = List.generate(3, (_) => _random.nextInt(10)).join();
    return '$adjective$noun$code';
  }

  String? _getIntent() {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    return uri.queryParameters['intent'];
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Privacy Policy'),
        ),
      );
      return;
    }
    final intent = _getIntent();
    final success = await ref.read(authStateProvider.notifier).register({
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'password_confirmation': _passwordController.text,
      'username': _usernameController.text.trim(),
      'display_name': _displayNameController.text.trim(),
      'intent': intent ?? 'talk',
    });

    if (!mounted) {
      return;
    }
    if (success) {
      // New users land on profile setup, carrying the chosen intent. Navigate
      // on the next frame so the router provider has rebuilt with the
      // authenticated state; navigating immediately uses the stale (signed-out)
      // router, which redirects this protected route back to /welcome.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.go('/profile-setup?intent=${intent ?? 'talk'}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final intent = _getIntent();
    final isListener = intent == 'listen';
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (isListener) ...[
                  const SizedBox(height: 8),
                  Text(
                    'You want to listen and support others.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Enter your email',
                    hintText: 'email@example.com',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Create a password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Your anonymous username',
                    helperText: 'Randomly generated, so it never reveals who you are. You can edit it.',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.casino_outlined),
                      tooltip: 'Generate another username',
                      onPressed: () {
                        setState(() {
                          _usernameController.text =
                              _generateAnonymousUsername();
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Please choose a username';
                    }
                    if (text.length < 2) {
                      return 'Username must be at least 2 characters';
                    }
                    if (text.length > 50) {
                      return 'Username must be 50 characters or fewer';
                    }
                    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(text)) {
                      return 'Use only letters, numbers, _ and -';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'This is how listeners and talkers see you. It is not your email or real name.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Choose your display name (optional)',
                    hintText: 'FriendlyListener',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _termsAccepted = !_termsAccepted;
                          });
                        },
                        child: Text(
                          'By creating an account, you agree to our Terms and Privacy Policy',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleCreateAccount,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
