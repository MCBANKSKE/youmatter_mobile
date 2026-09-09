/// Represents the current activity state of the user.
enum ActivityState {
  idle,
  seekingSupport,
  availableToListen,
  inConversation,
}

/// User profile information for the home screen.
class UserProfile {
  final String displayName;
  final String? username;

  const UserProfile({
    required this.displayName,
    this.username,
  });

  factory UserProfile.fromApi(Map<String, dynamic> user) {
    final identity = user['pseudonymous_identity'] as Map<String, dynamic>?;
    if (identity != null) {
      final displayName = identity['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        return UserProfile(
          displayName: displayName,
          username: identity['username'] as String?,
        );
      }
      final username = identity['username'] as String?;
      if (username != null && username.isNotEmpty) {
        return UserProfile(displayName: username);
      }
    }
    final email = user['email'] as String?;
    if (email != null && email.contains('@')) {
      return UserProfile(displayName: email.split('@').first);
    }
    return const UserProfile(displayName: 'Friend');
  }
}

/// Preview of a conversation for the home screen.
class ConversationPreview {
  final int id;
  final String participantName;
  final bool isActive;
  final String? lastMessage;
  final int? remoteUserId;

  const ConversationPreview({
    required this.id,
    required this.participantName,
    required this.isActive,
    this.lastMessage,
    this.remoteUserId,
  });
}

/// Information about the current talk request.
class TalkRequestInfo {
  final int id;
  final String status;
  final String topic;
  final bool hasActiveConversation;

  const TalkRequestInfo({
    required this.id,
    required this.status,
    required this.topic,
    required this.hasActiveConversation,
  });

  /// Whether the user can create a new talk request.
  bool get canCreateNewRequest {
    return status == 'cancelled' ||
        status == 'expired' ||
        (status == 'matched' && !hasActiveConversation);
  }
}

/// Aggregated data for the home screen.
class HomeData {
  final UserProfile user;
  final ActivityState activityState;
  final List<ConversationPreview> conversations;
  final int unreadNotifications;
  final TalkRequestInfo? currentTalkRequest;

  const HomeData({
    required this.user,
    required this.activityState,
    required this.conversations,
    required this.unreadNotifications,
    this.currentTalkRequest,
  });

  /// Whether to show the primary action cards (talk/listen).
  bool get showPrimaryActions {
    if (activityState == ActivityState.idle) return true;
    if (currentTalkRequest != null) {
      return currentTalkRequest!.canCreateNewRequest;
    }
    return false;
  }

  /// Whether the user has an active conversation.
  bool get hasActiveConversation {
    return conversations.any((c) => c.isActive);
  }

  /// The active conversation, if any.
  ConversationPreview? get activeConversation {
    try {
      return conversations.firstWhere((c) => c.isActive);
    } catch (_) {
      return null;
    }
  }
}