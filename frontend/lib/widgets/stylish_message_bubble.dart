import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/widgets/glassmorphic_container.dart';

class StylishMessageBubble extends StatefulWidget {
  final dynamic message;
  final bool isMe;

  const StylishMessageBubble({super.key, required this.message, required this.isMe});

  @override
  State<StylishMessageBubble> createState() => _StylishMessageBubbleState();
}

class _StylishMessageBubbleState extends State<StylishMessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageText = widget.message['message'] ?? '';
    final username = widget.message['sender'] != null ? widget.message['sender']['username'] : widget.message['username'] ?? '';

    return ScaleTransition(
      scale: _animation,
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: GlassmorphicContainer(
            borderRadius: BorderRadius.circular(15),
            backgroundColor: widget.isMe
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).colorScheme.surface.withOpacity(0.3),
            border: Border.all(
              color: widget.isMe
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              width: 1.0,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isMe)
                  Text(
                    username,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                if (!widget.isMe) const SizedBox(height: 4),
                Text(
                  messageText,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}