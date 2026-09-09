import 'package:flutter/material.dart';
import 'package:youmatter_mobile/core/theme/youmatter_design.dart';

/// Action card for "I'm available to listen" with blue/cyan gradient.
class ListenActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const ListenActionCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: YouMatterGradients.listenGradient,
        borderRadius: BorderRadius.circular(YouMatterRadius.lg),
        boxShadow: [
          BoxShadow(
                        color: YouMatterColors.blue.withValues(alpha: 0.3),
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
                    Icons.hearing_rounded,
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
                        "I'm available to listen",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be there for someone today',
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