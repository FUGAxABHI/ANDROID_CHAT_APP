
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/call_service.dart';

enum CallStatus {
  none,
  ringing,
  connecting,
  connected,
  ended,
  error,
}

class CallProvider with ChangeNotifier {
  CallService? _callService;
  final AuthService _authService;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  CallStatus _callStatus = CallStatus.none;
  CallStatus get callStatus => _callStatus;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  RTCPeerConnection? get peerConnection => _callService?.peerConnection;
  MediaStream? get localStream => _callService?.localStream;

  CallProvider({required AuthService authService}) : _authService = authService {
    localRenderer.initialize();
    remoteRenderer.initialize();
    _callService = CallService(onAddRemoteStream: (stream) {
      remoteRenderer.srcObject = stream;
      notifyListeners();
    }, authService: _authService);
  }

  @override
  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await _callService?.init();
    localRenderer.srcObject = _callService?.localStream;
    notifyListeners();
  }

  Future<void> createOffer(String friendUsername) async {
    try {
      _setStatus(CallStatus.ringing);
      await _callService?.createOffer(friendUsername);
    } catch (e) {
      _setStatus(CallStatus.error);
    }
  }

  Future<void> createAnswer(String friendUsername, dynamic offer) async {
    try {
      _setStatus(CallStatus.connecting);
      await _callService?.createAnswer(friendUsername, offer);
      _setStatus(CallStatus.connected);
    } catch (e) {
      _setStatus(CallStatus.error);
    }
  }

  void endCall(String friendUsername) {
    _callService?.endCall(friendUsername);
    _setStatus(CallStatus.ended);
  }

  void rejectCall(String friendUsername) {
    _callService?.rejectCall(friendUsername);
    _setStatus(CallStatus.ended);
  }

  void toggleMute() {
    if (localStream != null) {
      final audioTrack = localStream!.getAudioTracks()[0];
      _isMuted = !_isMuted;
      audioTrack.enabled = !_isMuted;
      notifyListeners();
    }
  }

  void switchCamera() {
    if (localStream != null) {
      final videoTrack = localStream!.getVideoTracks()[0];
      videoTrack.switchCamera();
    }
  }

  void _setStatus(CallStatus status) {
    _callStatus = status;
    notifyListeners();
  }
}
