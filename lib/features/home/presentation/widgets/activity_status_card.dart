import 'package:flutter/material.dart';
import 'package:youmatter_mobile/features/home/models/home_data.dart';

// ================================================================
// ACTIVITY STATUS CARD
// ================================================================

/// State-aware card showing the user's current activity status.
class ActivityStatusCard extends StatelessWidget {
  final ActivityState state;
  final TalkRequestInfo? talkRequest;
  final ConversationPreview? activeConversation;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onStopListening;
  final VoidCallback? onContinueConversation;
  final VoidCallback? onTalkToMatch;

  const ActivityStatusCard({
    super.key,
    required this.state,
    this.talkRequest,
    this.activeConversation,
    this.onCancelRequest,
    this.onStopListening,
    this.onContinueConversation,
    this.onTalkToMatch,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ActivityState.idle:
        return const SizedBox.shrink();
      case ActivityState.seekingSupport:
        return _buildSeekingCard(context);
      case ActivityState.availableToListen:
        return _buildListeningCard(context);
      case ActivityState.inConversation:
        return _buildInConversationCard(context);
    }
  }

  Widget _buildSeekingCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const PulsingDot(color: Color(0xFF7120F4)),
            const SizedBox(height: 16),
            Text(
              'Looking for someone...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "We're finding someone who fits your request.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onCancelRequest,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel request'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const PulsingDot(color: Color(0xFF2ECC71)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "You're available to listen",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Someone may need someone to talk to.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onStopListening,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Stop listening'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInConversationCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Color(0xFF2ECC71),
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're connected",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Someone is here to talk with you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onContinueConversation,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue conversation →'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// PULSING DOT WIDGET
// ================================================================

/// A pulsing dot used to indicate active status.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 16,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// THEME CONSTANTS (If not already defined in youmatter_design.dart)
// ================================================================

/// Spacing constants for YouMatter app.
/// If these are already defined in youmatter_design.dart, 
/// you can remove this class.
class YouMatterSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Color constants for YouMatter app.
/// If these are already defined in youmatter_design.dart, 
/// you can remove this class.
class YouMatterColors {
  static const Color purple = Color(0xFF7120F4);
  static const Color green = Color(0xFF2ECC71);
  static const Color blue = Color(0xFF1489F5);
  static const Color orange = Color(0xFFF39C12);
  static const Color red = Color(0xFFE74C3C);
}