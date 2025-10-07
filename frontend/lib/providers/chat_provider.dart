import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logging/logging.dart';
import 'package:frontend/socket_service.dart';

// Assuming Message and User models are defined somewhere, for now using Map<String, dynamic>
// import 'package:frontend/models/message.dart';
// import 'package:frontend/models/user.dart';

class ChatProvider with ChangeNotifier {
  final log = Logger('ChatProvider');
  final AuthService _authService = AuthService();

  List<dynamic> _messages = [];
  bool _isTyping = false;
  Set<String> _onlineUsers = {};
  String? _currentChatPartner;

  List<dynamic> get messages => _messages;
  bool get isTyping => _isTyping;
  Set<String> get onlineUsers => _onlineUsers;

  void init(String chatPartner) {
    _messages = [];
    _currentChatPartner = chatPartner;
    _connectSocket();
  }

  void _connectSocket() {
    final IO.Socket? socket = SocketService().socket;
    if (socket == null || !socket.connected) {
      log.warning('ChatProvider: SocketService socket not connected, cannot set up listeners.');
      return;
    }
    log.info('ChatProvider: Setting up listeners for chat partner: $_currentChatPartner');

    // Clear previous listeners to prevent duplicates
    socket.off('private messages');
    socket.off('private message');
    socket.off('typing');
    socket.off('stop typing');
    socket.off('messages marked as read');
    socket.off('user online');
    socket.off('user offline');

    socket.on('private messages', (data) {
      log.info('ChatProvider: Received private messages history: $data');
      _messages = List<dynamic>.from(data); // Assign a new list instance
      notifyListeners();
    });

    socket.on('private message', (data) {
      log.info('ChatProvider: Received real-time private message: $data');
      _messages.add(data['message']);
      notifyListeners();
    });

    socket.on('typing', (data) {
      if (data['from'] == _currentChatPartner) {
        _isTyping = true;
        notifyListeners();
      }
    });

    socket.on('stop typing', (data) {
      if (data['from'] == _currentChatPartner) {
        _isTyping = false;
        notifyListeners();
      }
    });

    socket.on('messages marked as read', (data) {
      if (data['byUser'] == _currentChatPartner) {
        for (var msg in _messages) {
          msg['isRead'] = true;
        }
        notifyListeners();
      }
    });

    socket.on('user online', (userId) {
      _onlineUsers.add(userId);
      notifyListeners();
    });

    socket.on('user offline', (userId) {
      _onlineUsers.remove(userId);
      notifyListeners();
    });

    // Request private messages after listeners are set up
    socket.emit('get private messages', {'withUser': _currentChatPartner});
  }

  void sendMessage(String message, {bool isVoice = false, String? voiceData}) {
    final IO.Socket? socket = SocketService().socket;
    if (socket == null || !socket.connected) {
      log.warning('SocketService socket not connected, cannot send message.');
      return;
    }
    final messageData = {
      'to': _currentChatPartner,
      'message': message,
      'isVoice': isVoice,
      'voiceData': voiceData,
    };
    // Optimistically add the message to the sender's chat for immediate display
    _messages.add({
      'sender': {'username': 'You'}, // Placeholder for sender's username
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    });
    notifyListeners();

    socket.emit('private message', messageData);
  }

  void sendTyping() {
    final IO.Socket? socket = SocketService().socket;
    if (socket == null || !socket.connected) return;
    socket.emit('typing', {'to': _currentChatPartner});
  }

  void sendStopTyping() {
    final IO.Socket? socket = SocketService().socket;
    if (socket == null || !socket.connected) return;
    socket.emit('stop typing', {'to': _currentChatPartner});
  }

  void markMessagesAsRead() {
    final IO.Socket? socket = SocketService().socket;
    if (socket == null || !socket.connected) return;
    socket.emit('mark messages as read', {'withUser': _currentChatPartner});
  }


}
