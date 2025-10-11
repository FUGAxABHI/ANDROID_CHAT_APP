import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/stylish_message_bubble.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

final log = Logger('PrivateChatScreen');

class PrivateChatScreen extends StatefulWidget {
  final String friendUsername;

  const PrivateChatScreen({super.key, required this.friendUsername});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUsername;

  // Voice Recording State
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _currentUsername = Provider.of<AuthService>(context, listen: false).token; // Simplified

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.init(widget.friendUsername);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _sendMessage(ChatProvider chatProvider) {
    if (_messageController.text.isNotEmpty) {
      chatProvider.sendMessage(_messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/recording.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording(ChatProvider chatProvider) async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      chatProvider.sendVoiceMessage(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUsername == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Not authenticated.')),
      );
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.messages.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.friendUsername),
          ),
          body: Column(
            children: [
              Expanded(
                child: chatProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : chatProvider.error != null
                        ? Center(child: Text('Error: ${chatProvider.error}'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: chatProvider.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatProvider.messages[index];
                              final isMe = message['sender']?['username'] != widget.friendUsername;
                              return StylishMessageBubble(
                                message: message,
                                isMe: isMe,
                              );
                            },
                          ),
              ),
              _buildMessageInputField(chatProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInputField(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => chatProvider.sendFile(),
          ),
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
            onPressed: () => _sendMessage(chatProvider),
          ),
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(chatProvider),
            child: Icon(_isRecording ? Icons.mic_off : Icons.mic),
          ),
        ],
      ),
    );
  }
}
