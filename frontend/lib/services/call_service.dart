
import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/auth_service.dart';

class CallService {
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  final Function(MediaStream stream) onAddRemoteStream;
  final AuthService _authService;
  Timer? _callTimeout;

  CallService({required this.onAddRemoteStream, required AuthService authService}) : _authService = authService;

  Future<void> init() async {
    peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    }, {});

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // This will be handled in the provider
    };

    peerConnection!.onTrack = (RTCTrackEvent event) {
      onAddRemoteStream(event.streams[0]);
    };

    try {
      localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
    } catch (e) {
      // Handle error in the provider
      rethrow;
    }
  }

  Future<void> createOffer(String friendUsername) async {
    RTCSessionDescription description = await peerConnection!.createOffer({'offerToReceiveVideo': 1});
    await peerConnection!.setLocalDescription(description);
    SocketService().emit('call-user', {
      'to': friendUsername,
      'from': _authService.currentUser?.username,
      'signal': description.toMap(),
    });

    _callTimeout = Timer(const Duration(seconds: 30), () {
      // Handle timeout in the provider
    });
  }

  Future<void> createAnswer(String friendUsername, dynamic offer) async {
    await peerConnection!.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
    RTCSessionDescription description = await peerConnection!.createAnswer({'offerToReceiveVideo': 1});
    await peerConnection!.setLocalDescription(description);
    SocketService().emit('make-answer', {
      'to': friendUsername,
      'signal': description.toMap(),
    });
  }

  void endCall(String friendUsername) {
    SocketService().emit('call-ended', {'to': friendUsername});
    dispose();
  }

  void rejectCall(String friendUsername) {
    SocketService().emit('call-rejected', {'to': friendUsername});
  }

  void dispose() {
    _callTimeout?.cancel();
    localStream?.getTracks().forEach((track) {
      track.stop();
    });
    localStream?.dispose();
    peerConnection?.dispose();
  }
}
