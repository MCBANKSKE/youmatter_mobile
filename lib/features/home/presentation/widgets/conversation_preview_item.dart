import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/theme/youmatter_design.dart';
import 'package:youmatter_mobile/features/home/models/home_data.dart';

class ConversationPreviewItem extends StatelessWidget {
  final ConversationPreview conversation;

  const ConversationPreviewItem({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: conversation.isActive 
              ? YouMatterColors.green.withValues(alpha: 0.2)
              : YouMatterColors.blue.withValues(alpha: 0.1),
          child: Icon(
            conversation.isActive 
                ? Icons.chat_bubble_rounded
                : Icons.chat_bubble_outline_rounded,
            color: conversation.isActive 
                ? YouMatterColors.green
                : YouMatterColors.blue,
          ),
        ),
        title: Text(
          conversation.participantName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          conversation.lastMessage ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: conversation.isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: YouMatterColors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: YouMatterColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
          context.push('/chat/${conversation.id}');
        },
      ),
    );
  }
}