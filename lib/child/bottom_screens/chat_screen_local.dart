import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreenLocal extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final String friendName;

  const ChatScreenLocal({
    Key? key,
    required this.currentUserId,
    required this.friendId,
    required this.friendName,
  }) : super(key: key);

  @override
  State<ChatScreenLocal> createState() => _ChatScreenLocalState();
}

class _ChatScreenLocalState extends State<ChatScreenLocal> {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessageLocal> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<String> _getMessageKey() async {
    return 'chat_${widget.currentUserId}_${widget.friendId}';
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messageKey = await _getMessageKey();
    final messagesData = prefs.getStringList(messageKey) ?? [];
    setState(() {
      _messages =
          messagesData.map((messageString) {
            final parts = messageString.split('||');
            return ChatMessageLocal(
              senderId: parts[0],
              text: parts[1],
              timestamp: DateTime.parse(parts[2]),
            );
          }).toList();
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  Future<void> _saveMessage(ChatMessageLocal message) async {
    final prefs = await SharedPreferences.getInstance();
    final messageKey = await _getMessageKey();
    final messageString =
        '${message.senderId}||${message.text}||${message.timestamp.toIso8601String()}';
    final currentMessages = prefs.getStringList(messageKey) ?? [];
    currentMessages.add(messageString);
    await prefs.setStringList(messageKey, currentMessages);
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final message = ChatMessageLocal(
        senderId: widget.currentUserId,
        text: text,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(message);
      });
      await _saveMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.friendName}"),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == widget.currentUserId;
                return Align(
                  alignment: isMe ? Alignment.topRight : Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.pink.shade200 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          "${message.timestamp.hour}:${message.timestamp.minute}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Send a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                  child: const Text(
                    'Send',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessageLocal {
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessageLocal({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });
}
