import 'package:flutter/material.dart';
import 'package:frontend/login_screen.dart';
import 'package:frontend/registration_screen.dart';
import 'package:frontend/auth_service.dart';
import 'package:frontend/dashboard_screen.dart'; // Import DashboardScreen
import 'package:frontend/profile_settings_screen.dart'; // Import ProfileSettingsScreen
import 'package:frontend/friends_list_screen.dart'; // Import FriendsListScreen
import 'package:frontend/user_profile_screen.dart'; // Import UserProfileScreen
import 'package:frontend/search_users_screen.dart'; // Import SearchUsersScreen
import 'package:frontend/private_chat_screen.dart'; // Import PrivateChatScreen
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _authService.getToken();
    setState(() {
      _isLoggedIn = token != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const DashboardScreen(),
        '/chat': (context) => const ChatScreen(),
        '/profile_settings': (context) => const ProfileSettingsScreen(),
        '/friends_list': (context) => const FriendsListScreen(),
        '/search_users': (context) => const SearchUsersScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/user_profile') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) {
              return UserProfileScreen(username: args['username']!);
            },
          );
        } else if (settings.name == '/private_chat') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) {
              return PrivateChatScreen(friendUsername: args['friendUsername']!);
            },
          );
        }
        // Handle unknown routes
        return MaterialPageRoute(builder: (context) => const Text('Error: Unknown Route'));
      },
    );
  }
}

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
    final AuthService authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      // If no token, navigate to login
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Decode token to get username (for display purposes)
    // In a real app, you'd verify the token on the backend and get user info securely.
    // For simplicity, we'll just assume the token contains the username.
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      _username = payload['username'];
    } catch (e) {
      print('Error decoding token: $e');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'x-auth-token': token}, // Send token with connection
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket');
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

    socket.onDisconnect((_) => print('Disconnected from socket'));
    socket.onError((data) => print('Socket Error: $data'));
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
              await AuthService().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
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