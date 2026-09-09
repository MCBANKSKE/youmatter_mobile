import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/theme/youmatter_design.dart';
import 'package:youmatter_mobile/features/home/models/home_data.dart';
import 'package:youmatter_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:youmatter_mobile/features/home/presentation/widgets/talk_action_card.dart';
import 'package:youmatter_mobile/features/home/presentation/widgets/listen_action_card.dart';
import 'package:youmatter_mobile/features/home/presentation/widgets/activity_status_card.dart' hide YouMatterColors, YouMatterSpacing;
import 'package:youmatter_mobile/features/home/presentation/widgets/conversation_preview_item.dart';
import 'package:youmatter_mobile/features/home/presentation/widgets/empty_conversations.dart';
import 'package:youmatter_mobile/features/home/providers/home_provider.dart';

// ================================================================
// HOME SCREEN
// ================================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? lastBackPressTime;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.push('/conversations');
        break;
      case 2:
        context.push('/notifications');
        break;
      case 3:
        context.push('/profile');
        break;
    }
  }

  Future<void> _startListening() async {
    try {
      await ref.read(homeProvider.notifier).setActivity('available_to_listen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You're now available to listen"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: YouMatterColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update activity. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: YouMatterColors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await ref.read(homeProvider.notifier).setActivity('idle');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You're no longer available to listen"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update activity. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: YouMatterColors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest() async {
    final homeData = ref.read(homeProvider).value;
    final talkRequest = homeData?.currentTalkRequest;
    if (talkRequest == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text(
          'Are you sure you want to cancel your talk request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep looking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(homeProvider.notifier)
            .cancelTalkRequest(talkRequest.id.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel request. Please try again.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: YouMatterColors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(homeProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Handle back press for exit confirmation
        if (lastBackPressTime == null ||
            DateTime.now().difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Exit the app
          // On Android, this will close the app
          // On iOS, this will go to the previous screen
          // Using go_router, we can handle this differently
        }
      },
      child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: homeAsync.when(
              loading: () => const HomeLoading(),
              error: (err, stack) => HomeError(
                onRetry: () => ref.read(homeProvider.notifier).load(),
              ),
              data: (homeData) {
                final isIdle = homeData.activityState == ActivityState.idle;
                final showActions = homeData.activityState == ActivityState.idle;
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(YouMatterSpacing.lg),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          HomeHeader(
                            displayName: homeData.user.displayName,
                            unreadCount: homeData.unreadNotifications,
                          ),
                          const SizedBox(height: YouMatterSpacing.lg),
                          Text(
                            '${_getGreeting()}, ${homeData.user.displayName}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: YouMatterSpacing.sm),
                          Text(
                            'What would you like to do today?',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: YouMatterSpacing.xl),
                          if (showActions) ...[
                            TalkActionCard(onTap: () => context.push('/talk-requests')),
                            const SizedBox(height: YouMatterSpacing.md),
                            ListenActionCard(onTap: _startListening),
                          ],
                          if (!isIdle)
                            ActivityStatusCard(
                              state: homeData.activityState,
                              talkRequest: homeData.currentTalkRequest,
                              activeConversation: homeData.activeConversation,
                              onCancelRequest: _cancelRequest,
                              onStopListening: _stopListening,
                              onContinueConversation: () {
                                final conv = homeData.activeConversation;
                                if (conv != null) {
                                  context.push('/chat/${conv.id}');
                                }
                              },
                            ),
                          const SizedBox(height: YouMatterSpacing.xl),
                          Text(
                            'Your conversations',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: YouMatterSpacing.md),
                          if (homeData.conversations.isEmpty)
                            const EmptyConversations()
                          else
                            ...homeData.conversations.map(
                              (c) => ConversationPreviewItem(conversation: c),
                            ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onNavItemTapped,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// HOME STATES WIDGETS
// ================================================================

/// Loading state for the home screen
class HomeLoading extends StatelessWidget {
  const HomeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your home...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Error state for the home screen
class HomeError extends StatelessWidget {
  final VoidCallback onRetry;

  const HomeError({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            "We couldn't load your home right now.",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// HOME CONTENT EXTENSION (if not already in home_content.dart)
// ================================================================

/// Extension to add computed properties to HomeData
extension HomeDataExtension on HomeData {
  /// Whether to show the primary action cards (Talk/Listen)
  bool get showPrimaryActions {
    return activityState == ActivityState.idle;
  }

  /// Get the active conversation if any
  ConversationPreview? get activeConversation {
    try {
      return conversations.firstWhere((c) => c.isActive);
    } catch (_) {
      return null;
    }
  }
}