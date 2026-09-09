import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';
import 'package:youmatter_mobile/features/authentication/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _me;
  bool _loading = true;
  bool _saving = false;
  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _ageController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final me = await _api.getMe();
      if (!mounted) return;
      final identity = me['pseudonymous_identity'] as Map<String, dynamic>?;
      final profile = me['profile'] as Map<String, dynamic>?;
      setState(() {
        _me = me;
        _usernameController.text = identity?['username']?.toString() ?? '';
        _displayNameController.text =
            identity?['display_name']?.toString() ?? '';
        _bioController.text = profile?['bio']?.toString() ?? '';
        _ageController.text = profile?['age']?.toString() ?? '';
        _gender = profile?['gender']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateIdentity({
        'username': _usernameController.text.trim(),
        if (_displayNameController.text.trim().isNotEmpty)
          'display_name': _displayNameController.text.trim(),
      });
      await _api.updateProfile({
        if (_bioController.text.trim().isNotEmpty)
          'bio': _bioController.text.trim(),
        if (_ageController.text.trim().isNotEmpty)
          'age': int.tryParse(_ageController.text.trim()),
        if (_gender != null && _gender!.isNotEmpty) 'gender': _gender,
      });
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save. Username may already be taken.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    if (!mounted) return;
    ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _me?['email']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Anonymous username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: (_gender == null || _gender!.isEmpty)
                        ? null
                        : _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(
                        value: 'non-binary',
                        child: Text('Non-binary'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
    );
  }
}
