import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/widgets/stylish_message_bubble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import 'package:frontend/widgets/glassmorphic_container.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<dynamic> _messages = [];
  String? _username;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isLoadingHistory = true;
  late AnimationController _bgAnimationController;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _messageController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _handleVoiceRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (path != null) {
        _sendVoiceMessage(path);
      }
      setState(() => _isRecording = false);
    } else {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        await _audioRecorder.start(const RecordConfig(), path: p.join(tempDir.path, 'audio.m4a'));
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _sendVoiceMessage(String path) async {
    final token = await Provider.of<AuthService>(context, listen: false).getToken();
    var request = http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}/uploads'));
    request.headers['x-auth-token'] = token!;
    request.files.add(await http.MultipartFile.fromPath('file', path));
    var response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final fileUrl = json.decode(responseData)['url'];
      SocketService().emit('chat message', {
        'message': '',
        'mediaUrl': fileUrl,
        'mediaType': 'audio',
        'isVoice': true,
      });
    }
  }

  Future<void> _sendFileMessage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String path = result.files.single.path!;
      final token = await Provider.of<AuthService>(context, listen: false).getToken();
      var request = http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}/uploads'));
      request.headers['x-auth-token'] = token!;
      request.files.add(await http.MultipartFile.fromPath('file', path));
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final fileUrl = json.decode(responseData)['url'];
        SocketService().emit('chat message', {
          'message': '',
          'mediaUrl': fileUrl,
          'mediaType': result.files.single.extension == 'jpg' || result.files.single.extension == 'png' ? 'image' : 'video',
        });
      }
    }
  }

  void _connectSocket() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _username = authService.currentUser?.username;

    if (_username == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    SocketService().messageStream.listen((data) {
      setState(() => _messages.add(data));
    });

    SocketService().historyStream.listen((data) {
      setState(() {
        _messages.clear();
        _messages.addAll(data);
        _isLoadingHistory = false;
      });
    });

    SocketService().on('user joined', (username) {
      setState(() => _messages.add({'username': username, 'message': 'joined the chat.'}));
    });

    SocketService().on('user left', (username) {
      setState(() => _messages.add({'username': username, 'message': 'left the chat.'}));
    });

    SocketService().getMessageHistory('dummy');
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      SocketService().emit('chat message', {'message': _messageController.text});
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text('CYBER CHAT', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/profile_settings'),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () {
            Provider.of<AuthService>(context, listen: false).logout(context);
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF0a0f21), const Color(0xFF10002b), _bgAnimation.value)!,
                Color.lerp(const Color(0xFF10002b), const Color(0xFF0a0f21), _bgAnimation.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      child: Column(
        children: <Widget>[
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['username'] == _username;
                      return StylishMessageBubble(message: message, isMe: isMe);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(0), // No border radius for full width
      blurStrength: 10,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
      border: Border.all(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        width: 0.0, // No visible border for the input area itself
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white70),
            onPressed: _sendFileMessage,
          ),
          IconButton(
            icon: Icon(Icons.mic, color: _isRecording ? Colors.cyan : Colors.white70),
            onPressed: _handleVoiceRecording,
          ),
          Expanded(
            child: GlassmorphicContainer(
              borderRadius: BorderRadius.circular(25),
              blurStrength: 5,
              backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.4),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                width: 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.cyan),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
