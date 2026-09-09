import 'package:flutter/material.dart';
import 'package:youmatter_mobile/core/theme/youmatter_design.dart';

/// Warm empty state for when there are no conversations.
class EmptyConversations extends StatelessWidget {
  const EmptyConversations({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YouMatterSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
                         color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: YouMatterSpacing.md),
          Text(
            "Whenever you're ready,",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: YouMatterSpacing.xs),
          Text(
            "there's someone here to listen.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}