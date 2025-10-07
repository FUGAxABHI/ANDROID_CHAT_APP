import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  final AuthService _authService = AuthService();
  List<dynamic> _recentChats = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentChats();
  }

  Future<void> _fetchRecentChats() async {
    final token = await _authService.getToken();
    if (token == null) return;

    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid token');
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final userId = payload['id'];

      final response = await http.get(Uri.parse('http://localhost:3000/api/users/recent-chats/$userId'));

      if (response.statusCode == 200) {
        setState(() {
          _recentChats = json.decode(response.body);
        });
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _markAsRead(String sender) async {
    final token = await _authService.getToken();
    if (token == null) return;

    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid token');
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final receiver = payload['username'];

      await http.post(
        Uri.parse('http://localhost:3000/api/chat/markAsRead'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sender': sender, 'receiver': receiver}),
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _recentChats.length,
      itemBuilder: (context, index) {
        final chat = _recentChats[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(chat['username'][0].toUpperCase()),
          ),
          title: Text(chat['username']),
          subtitle: Text(chat['lastMessage']['message'] ?? 'Voice Message'),
          trailing: chat['unreadCount'] > 0
              ? CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text(
                    chat['unreadCount'].toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              : null,
          onTap: () async {
            await _markAsRead(chat['username']);
            await Navigator.pushNamed(
              context,
              '/private_chat',
              arguments: {'friendUsername': chat['username']},
            );
            _fetchRecentChats();
          },
        );
      },
    );
  }
}