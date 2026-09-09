import 'package:flutter/material.dart';
import 'package:youmatter_mobile/core/theme/youmatter_design.dart';

/// Action card for "I want to talk" with purple/violet gradient.
class TalkActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const TalkActionCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: YouMatterGradients.talkGradient,
        borderRadius: BorderRadius.circular(YouMatterRadius.lg),
        boxShadow: [
          BoxShadow(
                        color: YouMatterColors.purple.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(YouMatterRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(YouMatterSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(YouMatterRadius.md),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: YouMatterSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I want to talk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find someone who will listen',
                        style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}