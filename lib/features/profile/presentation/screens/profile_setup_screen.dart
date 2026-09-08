import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicsController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _topicsController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String? _getIntent() {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    return uri.queryParameters['intent'];
  }

  bool get _isTalker => _getIntent() == 'talk';

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    final api = ApiService();
    try {
      final data = <String, dynamic>{
        'age': int.tryParse(_ageController.text.trim()),
      };
      if (_selectedGender != null) {
        data['gender'] = _selectedGender!.toLowerCase();
      }
      if (_topicsController.text.trim().isNotEmpty) {
        data['bio'] =
            'Topics: ${_topicsController.text.trim()}';
      }
      await api.updateProfile(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not save profile, continuing anyway')),
      );
      context.go('/home');
    }
  }

  void _handleSkip() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isTalker = _isTalker;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/register'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'Tell us a bit about yourself',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                if (isTalker) ...[
                  TextFormField(
                    controller: _topicsController,
                    decoration: const InputDecoration(
                      labelText: 'What would you like to talk about?',
                      hintText: 'e.g., stress, loneliness',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preferred listener gender?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  ...['Any', 'Female', 'Male', 'Non-binary'].map((gender) {
                    return RadioListTile<String>(
                      title: Text(gender),
                      value: gender,
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (for matching)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 13 || age > 120) {
                        return 'Please enter a valid age';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _topicsController,
                    decoration: const InputDecoration(
                      labelText: 'What topics are you comfortable with?',
                      hintText: 'e.g., anxiety, relationships',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Your age (for matching)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 13 || age > 120) {
                        return 'Please enter a valid age';
                      }
                      return null;
                    },
                  ),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _handleSkip,
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
