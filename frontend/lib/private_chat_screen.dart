import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:frontend/auth_service.dart';
import 'dart:convert';

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
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentUsername();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.init(widget.friendUsername);

    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        chatProvider.sendTyping();
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          chatProvider.sendStopTyping();
        });
      } else {
        chatProvider.sendStopTyping();
      }
    });
  }

  void _getCurrentUsername() async {
    final token = await AuthService().getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Invalid token');
        }
        final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        if (mounted) {
          setState(() {
            _currentUsername = payload['username'];
          });
        }
      } catch (e) {
        log.severe('Error decoding token: $e');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // The ChatProvider's dispose is handled by the Provider package
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Scroll to bottom when new messages arrive
        if (chatProvider.messages.isNotEmpty) {
          _scrollToBottom();
        }
        chatProvider.markMessagesAsRead(); // Mark messages as read when the chat is visible
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friendUsername),
                if (chatProvider.onlineUsers.contains(widget.friendUsername))
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                  ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isMe = message['sender']['username'] == _currentUsername;
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                ),
              ),
              if (chatProvider.isTyping)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('typing...'),
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
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['message'],
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${DateTime.parse(message['timestamp']).hour}:${DateTime.parse(message['timestamp']).minute}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message['isRead'] ? Icons.done_all : Icons.done,
                    color: message['isRead'] ? Colors.blueAccent : Colors.white70,
                    size: 16,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}