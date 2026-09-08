import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';

class TalkRequestsScreen extends StatefulWidget {
  const TalkRequestsScreen({super.key});

  @override
  State<TalkRequestsScreen> createState() => _TalkRequestsScreenState();
}

class _TalkRequestsScreenState extends State<TalkRequestsScreen> {
  final _api = ApiService();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _preference = 'anyone';
  Map<String, dynamic>? _current;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final current = await _api.getCurrentTalkRequest();
      if (!mounted) return;
      setState(() {
        _current = current;
        _loading = false;
        _error = null;
      });
      if (current != null && current['status'] == 'searching') {
        await Future.delayed(const Duration(seconds: 4));
        if (mounted) _load();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your talk request. Check your connection.';
      });
    }
  }

  Future<void> _create() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.createTalkRequest({
        'preference': _preference,
        'topic': _topicController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _loading = true;
      });
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create talk request')),
      );
    }
  }

  Future<void> _cancel() async {
    final id = _current?['id'];
    if (id == null) return;
    try {
      await _api.cancelTalkRequest(id.toString());
      if (!mounted) return;
      setState(() {
        _current = null;
        _loading = true;
      });
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel talk request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I want to talk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final current = _current;
    if (current != null) {
      final status = current['status'] as String?;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'matched'
                          ? 'You are matched! 🎉'
                          : 'Looking for a listener…',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Topic: ${current['topic'] ?? ''}'),
                    const SizedBox(height: 8),
                    if (status == 'searching')
                      const LinearProgressIndicator(),
                    if (status == 'matched') ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/conversations'),
                        child: const Text('Go to conversation'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (status == 'searching')
              OutlinedButton(
                onPressed: _cancel,
                child: const Text('Cancel request'),
              ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Who would you like to talk to?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          RadioListTile<String>(
            title: const Text('Anyone'),
            value: 'anyone',
            groupValue: _preference,
            onChanged: (v) => setState(() => _preference = v ?? 'anyone'),
          ),
          RadioListTile<String>(
            title: const Text('A professional'),
            value: 'professional',
            groupValue: _preference,
            onChanged: (v) =>
                setState(() => _preference = v ?? 'professional'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'What would you like to talk about?',
              hintText: 'e.g., stress, loneliness',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Anything else you want to share? (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _create,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Find someone to listen'),
          ),
        ],
      ),
    );
  }
}