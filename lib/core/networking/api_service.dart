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

  Future<void> endConversation(String id) async {
    await _dioClient.dio.post('/conversations/$id/end');
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
}
