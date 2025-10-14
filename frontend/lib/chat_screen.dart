import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:frontend/auth_service.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontend/config.dart';
import 'package:provider/provider.dart';

final log = Logger('ChatScreen');

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  late IO.Socket socket;
  String? _username;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();

    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      _username = payload['username'];
    } catch (e) {
      log.severe('Error decoding token: $e');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    socket = IO.io(AppConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'x-auth-token': token},
    });

    socket.connect();

    socket.onConnect((_) {
      log.info('Connected to socket');
      if (_username != null) {
        socket.emit('set username', _username);
      }
    });

    socket.on('message history', (data) {
      setState(() {
        _messages.clear();
        for (var msg in data) {
          _messages.add('${msg['username']}: ${msg['message']}');
        }
      });
    });

    socket.on('chat message', (data) {
      setState(() {
        _messages.add('${data['username']}: ${data['message']}');
      });
    });

    socket.on('user joined', (username) {
      setState(() {
        _messages.add('$username joined the chat.');
      });
    });

    socket.on('user left', (username) {
      setState(() {
        _messages.add('$username left the chat.');
      });
    });

    socket.onDisconnect((_) => log.info('Disconnected from socket'));
    socket.onError((data) {
      log.severe('Socket Error: $data');
            if (data.toString().contains('Authentication error: Invalid token.')) {
              Provider.of<AuthService>(context, listen: false).logout(context);
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
      
        void _sendMessage() {
          if (_messageController.text.isNotEmpty) {
            socket.emit('chat message', _messageController.text);
            _messageController.clear();
          }
        }
      
        @override
        void dispose() {
          socket.disconnect();
          super.dispose();
        }
      
        @override
        Widget build(BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Chat as ${_username ?? 'Guest'}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile_settings');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
Provider.of<AuthService>(context, listen: false).logout(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
            body: Column(        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_messages[index]));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
