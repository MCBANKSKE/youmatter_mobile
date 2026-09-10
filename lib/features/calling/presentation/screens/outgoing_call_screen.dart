import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youmatter_mobile/features/calling/providers/call_state_provider.dart';

/// Screen shown when making an outgoing call.
class OutgoingCallScreen extends ConsumerWidget {
  final int conversationId;
  final String remoteUserName;

  const OutgoingCallScreen({
    super.key,
    required this.conversationId,
    required this.remoteUserName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(
              'Calling...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Listener',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            // Cancel button
            Column(
              children: [
                FloatingActionButton(
                  heroTag: 'cancel',
                  onPressed: () async {
                    await ref.read(callStateProvider.notifier).endCall();
                  },
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}