import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontend/notification_service.dart';

import 'package:logging/logging.dart';

final log = Logger('SocketService');

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal() {
    _messageController = StreamController.broadcast();
  }

  IO.Socket? socket;
  String? activeChatUsername;
  final NotificationService _notificationService = NotificationService();

  late StreamController<Map<String, dynamic>> _messageController;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  void init(String? token) {
    if (token == null) {
      if (socket != null && socket!.connected) {
        socket!.disconnect();
      }
      socket = null;
      return;
    }

    // Only connect if not already connected or if the existing socket is disconnected
    if (socket == null || !socket!.connected) {
      socket = IO.io('http://localhost:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'extraHeaders': {'x-auth-token': token},
        'auth': {'token': token},
      });
      socket!.connect();

      // Add general socket event listeners here (e.g., onConnect, onError, onDisconnect)
      socket!.onConnect((_) => log.info('Socket connected'));
      socket!.onError((data) => log.severe('Socket Error: $data'));
      socket!.onDisconnect((_) => log.info('Socket disconnected'));

      socket!.on('private message', (data) {
        final message = data['message'];
        _messageController.add(message);

        if (activeChatUsername != message['sender']) {
          final id = message['sender'].hashCode;
          _notificationService.showNotification(
            id: id,
            title: 'New message from ${message['sender']}',
            body: message['message'] ?? 'Voice Message',
            payload: message['sender'],
          );
        }
      });
    }
  }

  void dispose() {
    socket?.disconnect();
    socket = null;
    if (!_messageController.isClosed) {
      _messageController.close();
    }
  }
}
