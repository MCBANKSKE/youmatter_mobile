import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/theme/youmatter_design.dart';
import 'package:youmatter_mobile/features/home/models/home_data.dart';

/// A single conversation preview item for the home screen.
class ConversationPreviewItem extends StatelessWidget {
  final ConversationPreview conversation;

  const ConversationPreviewItem({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: YouMatterSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: YouMatterSpacing.md,
          vertical: YouMatterSpacing.sm,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: conversation.isActive
                             ? YouMatterColors.green.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: conversation.isActive
                ? YouMatterColors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          conversation.participantName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Text(
          conversation.isActive
              ? (conversation.lastMessage ?? 'Continue conversation')
              : 'Conversation ended',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: conversation.isActive
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: conversation.isActive ? null : FontStyle.italic,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => context.push('/chat/${conversation.id}'),
      ),
    );
  }
}