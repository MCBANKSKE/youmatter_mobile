import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youmatter_mobile/features/calling/providers/call_state_provider.dart';

/// Screen shown when receiving an incoming call.
class IncomingCallScreen extends ConsumerWidget {
  final int callId;
  final int conversationId;
  final String remoteUserName;

  const IncomingCallScreen({
    super.key,
    required this.callId,
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
              'Incoming call',
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
              'wants to talk',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline button
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'decline',
                        onPressed: () async {
                          await ref.read(callStateProvider.notifier).declineCall();
                        },
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Decline',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  // Answer button
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'answer',
                        onPressed: () async {
                          await ref.read(callStateProvider.notifier).acceptCall();
                        },
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.call, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Answer',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}