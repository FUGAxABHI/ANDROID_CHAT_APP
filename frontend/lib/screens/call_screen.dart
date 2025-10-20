import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  final String friendUsername;
  final Map<String, dynamic>? offer;

  const CallScreen({super.key, required this.friendUsername, this.offer});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.init(widget.friendUsername).then((_) {
      if (widget.offer == null) {
        callProvider.createOffer(widget.friendUsername);
      } else {
        callProvider.createAnswer(widget.friendUsername, widget.offer);
      }
    }).catchError((e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Could not access camera and microphone. Please make sure they are not in use by another application or browser tab.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calling ${widget.friendUsername}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () => callProvider.switchCamera(),
          ),
        ],
      ),
      body: _buildBody(context, callProvider),
      floatingActionButton: _buildFloatingActionButton(context, callProvider),
    );
  }

  Widget _buildBody(BuildContext context, CallProvider callProvider) {
    switch (callProvider.callStatus) {
      case CallStatus.ringing:
        return const Center(child: Text('Ringing...'));
      case CallStatus.connecting:
        return const Center(child: CircularProgressIndicator());
      case CallStatus.connected:
        return Stack(
          children: [
            Positioned.fill(
              child: RTCVideoView(callProvider.remoteRenderer, mirror: true),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: SizedBox(
                width: 100,
                height: 150,
                child: RTCVideoView(callProvider.localRenderer, mirror: true),
              ),
            ),
          ],
        );
      case CallStatus.ended:
        return const Center(child: Text('Call Ended'));
      case CallStatus.error:
        return const Center(child: Text('Call Error'));
      default:
        return const Center(child: Text('Initializing...'));
    }
  }

  Widget _buildFloatingActionButton(BuildContext context, CallProvider callProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          onPressed: () => callProvider.toggleMute(),
          child: Icon(callProvider.isMuted ? Icons.mic_off : Icons.mic),
          heroTag: "mic",
        ),
        const SizedBox(width: 10),
        FloatingActionButton(
          onPressed: () {
            callProvider.endCall(widget.friendUsername);
            Navigator.pop(context);
          },
          backgroundColor: Colors.red,
          child: const Icon(Icons.call_end),
          heroTag: "end_call",
        ),
      ],
    );
  }
}