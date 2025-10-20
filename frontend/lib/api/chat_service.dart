import 'package:flutter/material.dart';
import 'package:frontend/api/api_service.dart';

class ChatService with ChangeNotifier {
  final ApiService _apiService;

  ChatService(this._apiService);

  Future<List<dynamic>> getAllConversations(String userId) async {
    try {
      // The endpoint is /api/users/all-conversations/:userId
      final response = await _apiService.get('/api/users/all-conversations/$userId');
      return response as List<dynamic>;
    } catch (e) {
      // Handle or re-throw the error as appropriate
      print('Error fetching all conversations: $e');
      return [];
    }
  }
}
