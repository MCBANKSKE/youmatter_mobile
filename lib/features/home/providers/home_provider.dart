import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';
import 'package:youmatter_mobile/features/home/models/home_data.dart';

/// Provider for managing home screen state.
class HomeNotifier extends StateNotifier<AsyncValue<HomeData>> {
    HomeNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  final ApiService _api = ApiService();

  /// Load all home screen data from the backend.
  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      // Fetch user data
      final user = await _api.getMe();
      final userProfile = UserProfile.fromApi(user);

      // Fetch conversations
      final conversationsData = await _api.getConversations();
      final conversations = _parseConversations(conversationsData, user['id']);

      // Fetch unread notifications count
      final unreadNotifications = await _getUnreadCount();

      // Fetch current talk request
      final talkRequest = await _getCurrentTalkRequest();

      // Determine activity state
      final activityState = _determineActivityState(
        user['activity'],
        conversations,
        talkRequest,
      );

      state = AsyncValue.data(HomeData(
        user: userProfile,
        activityState: activityState,
        conversations: conversations,
        unreadNotifications: unreadNotifications,
        currentTalkRequest: talkRequest,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Set the user's activity state.
  Future<void> setActivity(String activity) async {
    final previousState = state;
    try {
      await _api.updateActivity(activity);
      await load();
    } catch (e) {
      // Restore previous state on error
      state = previousState;
      rethrow;
    }
  }

  /// Cancel the current talk request.
  Future<void> cancelTalkRequest(String requestId) async {
    try {
      await _api.cancelTalkRequest(requestId);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh home data.
  Future<void> refresh() => load();

  // ================================================================
  // PRIVATE METHODS
  // ================================================================

  Future<int> _getUnreadCount() async {
    try {
      final notifications = await _api.getUnreadNotifications();
      return notifications.length;
    } catch (_) {
      return 0;
    }
  }

  List<ConversationPreview> _parseConversations(
    List<dynamic> data,
    dynamic myUserId,
  ) {
    final myId = myUserId?.toString() ?? '';
    return data.map((item) {
      final map = item as Map<String, dynamic>;
            final isActive = map['status'] == 'active';
      final talkerId = map['talker_id']?.toString() ?? '';

      // Get the other participant's name
      String participantName = 'Someone you talked with';
      final key = talkerId == myId ? 'listener' : 'talker';
      final other = map[key] as Map<String, dynamic>?;
      if (other != null) {
        final identity = other['pseudonymous_identity'] as Map<String, dynamic>?;
        if (identity != null) {
          participantName = identity['display_name'] ??
              identity['username'] ??
              participantName;
        }
      }

      // Get last message
      final latestMessage = map['latest_message'] as Map<String, dynamic>?;
      final lastMessage = latestMessage?['body'] as String?;

      // Parse the ID properly
      final id = map['id'] is int 
          ? map['id'] 
          : int.tryParse(map['id'].toString()) ?? 0;

      return ConversationPreview(
        id: id,
        participantName: participantName,
        isActive: isActive,
        lastMessage: lastMessage,
        remoteUserId: _extractRemoteUserId(map, myId),
      );
    }).toList();
  }

  Future<TalkRequestInfo?> _getCurrentTalkRequest() async {
    try {
      final response = await _api.getCurrentTalkRequest();
      if (response == null) return null;

      // Check if this talk request has an active conversation
      bool hasActiveConversation = false;
      if (response['status'] == 'matched') {
        // Look for an active conversation from this request
        final conversations = await _api.getConversations();
        for (final conv in conversations) {
          final map = conv as Map<String, dynamic>;
          if (map['status'] == 'active') {
            hasActiveConversation = true;
            break;
          }
        }
      }

      // Parse the ID properly
      final id = response['id'] is int 
          ? response['id'] 
          : int.tryParse(response['id'].toString()) ?? 0;

      return TalkRequestInfo(
        id: id,
        status: response['status'] ?? '',
        topic: response['topic'] ?? '',
        hasActiveConversation: hasActiveConversation,
      );
    } catch (_) {
      return null;
    }
  }

  int? _extractRemoteUserId(Map<String, dynamic> map, String myId) {
    final talkerId = map['talker_id']?.toString() ?? '';
    final key = talkerId == myId ? 'listener' : 'talker';
    final other = map[key] as Map<String, dynamic>?;
    if (other == null) return null;
    final raw = other['id'];
    return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  }

  ActivityState _determineActivityState(
    dynamic activity,
    List<ConversationPreview> conversations,
    TalkRequestInfo? talkRequest,
  ) {
    // Check for active conversation first
    if (conversations.any((c) => c.isActive)) {
      return ActivityState.inConversation;
    }

    // Check activity field
    final activityStr = activity?.toString() ?? 'idle';
    switch (activityStr) {
      case 'seeking_support':
        return ActivityState.seekingSupport;
      case 'available_to_listen':
        return ActivityState.availableToListen;
      case 'in_conversation':
        return ActivityState.inConversation;
      default:
        return ActivityState.idle;
    }
  }
}

/// The main home state provider.
final homeProvider = StateNotifierProvider<HomeNotifier, AsyncValue<HomeData>>((_) {
  return HomeNotifier();
});