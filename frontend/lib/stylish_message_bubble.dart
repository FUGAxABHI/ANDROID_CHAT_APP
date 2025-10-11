import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class StylishMessageBubble extends StatefulWidget {
  final dynamic message;
  final bool isMe;

  const StylishMessageBubble({super.key, required this.message, required this.isMe});

  @override
  _StylishMessageBubbleState createState() => _StylishMessageBubbleState();
}

class _StylishMessageBubbleState extends State<StylishMessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: widget.isMe
                  ? const LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isMe ? null : Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: widget.isMe ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight: widget.isMe ? const Radius.circular(0) : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${DateTime.parse(widget.message['timestamp']).hour}:${DateTime.parse(widget.message['timestamp']).minute}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    if (widget.isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.message['isRead'] ? Icons.done_all : Icons.done,
                        color: widget.message['isRead'] ? Colors.blueAccent : Colors.white70,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    final message = widget.message;
    final isVoice = message['isVoice'] ?? false;
    final mediaUrl = message['mediaUrl'];
    final mediaType = message['mediaType'];

    if (isVoice) {
      return VoiceMessagePlayer(voiceData: message['voiceData']);
    } else if (mediaUrl != null) {
      if (mediaType == 'image') {
        return Image.network(AppConfig.baseUrl + mediaUrl);
      } else {
        return ElevatedButton(
          onPressed: () => launch(AppConfig.baseUrl + mediaUrl),
          child: const Text('Download File'),
        );
      }
    } else {
      return Text(
        message['message'],
        style: const TextStyle(color: Colors.white),
      );
    }
  }
}

class VoiceMessagePlayer extends StatefulWidget {
  final List<int> voiceData;

  const VoiceMessagePlayer({super.key, required this.voiceData});

  @override
  _VoiceMessagePlayerState createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setAudioSource(BytesAudioSource(Uint8List.fromList(widget.voiceData)));
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: _togglePlay,
    );
  }
}

class BytesAudioSource extends StreamAudioSource {
  final Uint8List _buffer;

  BytesAudioSource(this._buffer) : super(tag: 'BytesAudioSource');

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final size = _buffer.length;
    start ??= 0;
    end ??= size;
    return StreamAudioResponse(
      sourceLength: size,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/m4a',
    );
  }
}