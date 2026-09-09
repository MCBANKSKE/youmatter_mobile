import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/theme/youmatter_design.dart';

/// Header widget for the home screen with brand mark and notifications.
class HomeHeader extends StatelessWidget {
  final String displayName;
  final int unreadCount;

  const HomeHeader({
    super.key,
    required this.displayName,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // YouMatter brand mark
        Flexible(
          child: Image.asset(
            'assets/images/youmatterheaderlogo.png',
            width: 150,
            height: 116,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.favorite, size: 112),
          ),
        ),
        // Notification icon with badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
              onPressed: () => context.push('/notifications'),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: YouMatterColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}