import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontend/auth_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart'; // Import for audio recording
import 'package:just_audio/just_audio.dart'; // Import for audio playback
import 'package:path_provider/path_provider.dart'; // For temporary directory
import 'package:path/path.dart' as p; // For path manipulation

class PrivateChatScreen extends StatefulWidget {
  final String friendUsername;

  const PrivateChatScreen({super.key, required this.friendUsername});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket socket;
  String? _currentUsername;
  final AuthService _authService = AuthService();

  bool _isRecording = false;
  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioPath; // Path to the recorded audio file

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    final token = await _authService.getToken();

    if (token == null) {
      // Handle not logged in
      return;
    }

    // Decode token to get current username
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      setState(() {
        _currentUsername = payload['username'];
      });
    } catch (e) {
      print('Error decoding token: $e');
      // Handle invalid token
      return;
    }

    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'x-auth-token': token}, // Send token with connection
      'auth': {'token': token}, // Send token for Socket.IO middleware
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to private chat socket');
      // Request message history
      socket.emit('get private messages', {'withUser': widget.friendUsername}, (data) {
        setState(() {
          _messages.clear();
          _messages.addAll(data.cast<Map<String, dynamic>>());
        });
      });
    });

    socket.on('private message', (data) {
      setState(() {
        _messages.add(data['message']);
      });
    });

    socket.onDisconnect((_) => print('Disconnected from private chat socket'));
    socket.onError((data) => print('Private Chat Socket Error: $data'));
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _audioPath = p.join(directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
        await _audioRecorder.start(path: _audioPath);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path; // Update _audioPath with the final recorded file path
      });
      if (_audioPath != null) {
        final audioFile = await _audioRecorder.getWavFile(); // Get the recorded file
        final bytes = await audioFile.readAsBytes();
        final base64Audio = base64Encode(bytes);
        _sendMessage(isVoice: true, voiceData: base64Audio);
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playAudio(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.dataFromBytes(bytes)));
      _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void _sendMessage({bool isVoice = false, String? voiceData}) {
    if (isVoice && voiceData != null && _currentUsername != null) {
      socket.emit('private message', {
        'to': widget.friendUsername,
        'message': '',
        'isVoice': true,
        'voiceData': voiceData,
      });
    } else if (_messageController.text.isNotEmpty && _currentUsername != null) {
      socket.emit('private message', {
        'to': widget.friendUsername,
        'message': _messageController.text,
        'isVoice': false,
      });
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.friendUsername}'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['sender'] == _currentUsername;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['sender'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(message['message']),
                        Text(
                          DateTime.parse(message['timestamp']).toLocal().toString().substring(11, 16),
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
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
                      hintText: 'Enter message...',
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
