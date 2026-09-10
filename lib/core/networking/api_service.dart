import 'package:dio/dio.dart';
import 'package:youmatter_mobile/core/networking/dio_client.dart';

class ApiService {
  final DioClient _dioClient = DioClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dioClient.dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dioClient.dio.post('/register', data: data);
    return response.data;
  }

  Future<void> logout() async {
    await _dioClient.dio.post('/logout');
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dioClient.dio.get('/me');
    return response.data;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dioClient.dio.put('/me/profile', data: data);
  }

  Future<void> updateIdentity(Map<String, dynamic> data) async {
    await _dioClient.dio.put('/me/identity', data: data);
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    await _dioClient.dio.put('/me/preferences', data: data);
  }

  Future<List<dynamic>> getOffers() async {
    final response = await _dioClient.dio.get('/listener/offers');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getConversations() async {
    final response = await _dioClient.dio.get('/conversations');
    return response.data as List<dynamic>;
  }

  Future<void> updateActivity(String activity) async {
    await _dioClient.dio.put('/me/activity', data: {'activity': activity});
  }

  Future<Map<String, dynamic>> createTalkRequest(
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.dio.post('/talk-requests', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>?> getCurrentTalkRequest() async {
    try {
      final response = await _dioClient.dio.get('/talk-requests/current');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getConversation(String id) async {
    final response = await _dioClient.dio.get('/conversations/$id');
    return response.data;
  }

  /// Lightweight status-only check used by the periodic conversation-expiry
  /// poll. Returns `status`, `ended_at`, `ended_by`, and `expires_at`.
  Future<Map<String, dynamic>> getConversationStatus(String id) async {
    final response = await _dioClient.dio.get('/conversations/$id/status');
    return response.data as Map<String, dynamic>;
  }

  Future<void> endConversation(String id) async {
    await _dioClient.dio.post('/conversations/$id/end');
  }

  /// Extend conversation by 15 minutes
  /// Returns the new expiry time
  Future<DateTime> extendConversation(String id) async {
    final response = await _dioClient.dio.post('/conversations/$id/extend');
    final expiresAt = response.data['expires_at'] as String;
    return DateTime.parse(expiresAt);
  }

  Future<List<dynamic>> getMessages(String conversationId) async {
    final response = await _dioClient.dio.get(
      '/conversations/$conversationId/messages',
    );
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String body,
  ) async {
    final response = await _dioClient.dio.post(
      '/conversations/$conversationId/messages',
      data: {'body': body},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> sendAudioMessage(
    String conversationId,
    String filePath, {
    int? duration,
    String body = 'Voice message',
  }) async {
    // Step 1: Create a placeholder message
    final message = await sendMessage(conversationId, body);
    final messageId = message['id'].toString();

    // Step 2: Upload the audio file to the message
    final formData = FormData.fromMap({
      if (duration != null) 'duration': duration,
      'audio': await MultipartFile.fromFile(
        filePath,
        filename: 'audio_message.m4a',
      ),
    });
    final response = await _dioClient.dio.post(
      '/conversations/$conversationId/messages/$messageId/audio',
      data: formData,
    );

    // Return the updated message with audio
    return response.data['message'] ?? message;
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await _dioClient.dio.get('/notifications');
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getUnreadNotifications() async {
    final response = await _dioClient.dio.get('/notifications/unread');
    return response.data['data'] ?? [];
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _dioClient.dio.post('/notifications/$notificationId/read');
  }

  Future<void> markAllNotificationsAsRead() async {
    await _dioClient.dio.post('/notifications/read-all');
  }

  Future<void> blockUser(String userId) async {
    await _dioClient.dio.post('/blocks/$userId');
  }

  Future<void> unblockUser(String userId) async {
    await _dioClient.dio.delete('/blocks/$userId');
  }

  Future<List<dynamic>> getBlockedUsers() async {
    final response = await _dioClient.dio.get('/blocks');
    return response.data['data'] ?? [];
  }

  Future<void> acceptOffer(String attemptId) async {
    await _dioClient.dio.post(
      '/listener/offers/$attemptId/accept',
      data: {'response': 'accepted'},
    );
  }

  Future<void> declineOffer(String attemptId) async {
    await _dioClient.dio.post(
      '/listener/offers/$attemptId/decline',
      data: {'response': 'declined'},
    );
  }

  Future<void> cancelTalkRequest(String talkRequestId) async {
    await _dioClient.dio.post('/talk-requests/$talkRequestId/cancel');
  }

  Future<int> getUnreadMessageCount(String conversationId) async {
    final response = await _dioClient.dio.get(
      '/conversations/$conversationId/messages/unread-count',
    );
    return response.data['unread_count'] ?? 0;
  }

  Future<void> redactMessage(
    String conversationId,
    String messageId,
    String reason,
  ) async {
    await _dioClient.dio.post(
      '/conversations/$conversationId/messages/$messageId/redact',
      data: {'reason': reason},
    );
  }

  Future<Map<String, dynamic>> getProfessionalInfo() async {
    final response = await _dioClient.dio.get('/me/professional');
    return response.data;
  }

  // ---- Voice Calling ----

  Future<Map<String, dynamic>> startCall(int conversationId) async {
    final response = await _dioClient.dio.post(
      '/conversations/$conversationId/calls',
    );
    return response.data;
  }

  Future<Map<String, dynamic>> acceptCall(int callId) async {
    final response = await _dioClient.dio.post('/calls/$callId/accept');
    return response.data;
  }

  Future<Map<String, dynamic>> declineCall(int callId) async {
    final response = await _dioClient.dio.post('/calls/$callId/decline');
    return response.data;
  }

  Future<Map<String, dynamic>> endCall(int callId) async {
    final response = await _dioClient.dio.post('/calls/$callId/end');
    return response.data;
  }

    Future<List<Map<String, dynamic>>> getIceServers() async {
    final response = await _dioClient.dio.get('/calls/ice-servers');
    final servers = response.data['ice_servers'] as List<dynamic>;
    return servers.cast<Map<String, dynamic>>();
  }

  // ---- Voice Calling (WebRTC signaling) ----

  /// Relay a WebRTC signaling payload (offer / answer / ICE candidate) for a
  /// call. The backend validates participation and broadcasts it to the
  /// private conversation channel.
  Future<void> sendSignal(int callId, Map<String, dynamic> body) async {
    await _dioClient.dio.post('/calls/$callId/signal', data: body);
  }

  /// Poll the current call state for a conversation (signaling fallback).
  /// Returns the active call (or `null` when none is in progress).
  Future<Map<String, dynamic>?> getCallState(String conversationId) async {
    final response = await _dioClient.dio.get(
      '/calls/$conversationId/state',
    );
    return response.data['call'] as Map<String, dynamic>?;
  }

  /// Drain pending signaling messages for a call (signaling fallback).
  /// Returns `(messages, lastId)`.
  Future<(List<dynamic>, int)> getCallSignals(
    int callId,
    int afterId,
  ) async {
    final response = await _dioClient.dio.get(
      '/calls/$callId/signals',
      queryParameters: {'after_id': afterId.toString()},
    );
    final messages = response.data['messages'] as List<dynamic>? ?? [];
    final lastId = response.data['last_id'] as int? ?? 0;
    return (messages, lastId);
  }

  /// Authorize a private broadcast channel for the current socket. Returns
  /// the signed auth string (`appKey:signature`) the Reverb client sends when
  /// subscribing to a private channel.
  Future<Map<String, dynamic>> authorizeChannel(
    String socketId,
    String channelName,
  ) async {
    final response = await _dioClient.dio.post(
      '/broadcasting/auth',
      data: {'socket_id': socketId, 'channel_name': channelName},
    );
    return response.data as Map<String, dynamic>;
  }
}
