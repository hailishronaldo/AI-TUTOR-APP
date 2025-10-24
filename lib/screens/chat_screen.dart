import 'package:flutter/material.dart';
import 'dart:ui';
import '../main.dart';
import '../services/ai_service.dart';
import 'api_config_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
 // final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kDarkGradient,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildChatList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: kPrimaryColor, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Chat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              Text(
                aiService.isConfigured
                    ? 'Ask me anything'
                    : 'Configure API to start chatting',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                aiService.isConfigured
                    ? 'Start the conversation below'
                    : 'Configure API to start chatting',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      //itemCount: _messages.length,
      itemBuilder: (context, index) {
       // final message = _messages[_messages.length - 1 - index];
        //final isUser = message.role == 'user';
        return Align(
         // alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                   /* color: (isUser ? kAccentColor : Colors.white)
                        .withOpacity(0.12),*/
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),

                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: aiService.isConfigured
                          ? 'Type a message...'
                          : 'Set API to chat',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    enabled: !_isSending,
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(),
          const SizedBox(width: 8),
          _buildConfigButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      height: 44,
      width: 44,
      child: ElevatedButton(
        onPressed: _isSending ? null : _handleSend,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
        child: _isSending
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
      ),
    );
  }

  Widget _buildConfigButton() {
    return SizedBox(
      height: 44,
      width: 44,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApiConfigScreen()),
          );
          if (result == true) setState(() {});
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white.withOpacity(0.08),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
        child: const Icon(Icons.settings),
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (!aiService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure API first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {/*
      _messages.add(ChatMessage(role: 'user', content: text));
      _isSending = true;
      _messageController.clear();*/
    });
    try {/*
      final reply = await aiService.sendChatResponse(_messages);
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
      });*/
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}