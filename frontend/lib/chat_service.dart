import 'package:frontend/api_service.dart';

class ChatService {
  final ApiService _apiService;

  ChatService(this._apiService);

  Future<List<dynamic>> getRecentChats(String userId) async {
    try {
      // The endpoint is /api/users/recent-chats/:userId
      final response = await _apiService.get('/api/users/recent-chats/$userId');
      return response as List<dynamic>;
    } catch (e) {
      // Handle or re-throw the error as appropriate
      print('Error fetching recent chats: $e');
      return [];
    }
  }
}
