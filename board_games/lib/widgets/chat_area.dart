import 'package:flutter/material.dart';

class ChatArea extends StatelessWidget {
  final List<Map<String, String>> messages;

  const ChatArea({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isUser = message['sender'] == 'user';
          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7, // Maximum width
              ),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message['text'] ?? '',
                style: TextStyle(
                  fontSize: 15,
                ),
                textAlign: isUser ? TextAlign.right : TextAlign.left, // Align text
                softWrap: true, // Ensures text wraps to the next line
              ),
            ),
          );
        },
      ),
    );
  }
}
