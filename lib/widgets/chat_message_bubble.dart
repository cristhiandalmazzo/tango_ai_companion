import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isTyping;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isUser 
              ? Theme.of(context).primaryColor.withOpacity(0.9)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isTyping
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Typing',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    height: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        3,
                        (index) => _buildDot(context, index),
                      ),
                    ),
                  ),
                ],
              )
            : MarkdownBody(
                data: message,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  h1: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  a: TextStyle(
                    color: isUser ? Colors.white.withOpacity(0.9) : Theme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                  em: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                  strong: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  code: TextStyle(
                    color: isUser ? Colors.white.withOpacity(0.9) : Colors.black54,
                    fontFamily: 'monospace',
                    fontSize: 15,
                  ),
                  codeblockPadding: const EdgeInsets.all(8),
                  blockquote: TextStyle(
                    color: isUser ? Colors.white.withOpacity(0.9) : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                  blockquotePadding: const EdgeInsets.only(left: 8),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isUser ? Colors.white.withOpacity(0.5) : Colors.grey.shade400,
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDot(BuildContext context, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 * (index + 1)),
      height: 4,
      width: 4,
      decoration: BoxDecoration(
        color: isUser ? Colors.white70 : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
} 