import 'package:flutter/material.dart';
import '../../../../shared/placeholder_screen.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: 'Chat ($conversationId)');
  }
}