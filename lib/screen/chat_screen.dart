import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ChatScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    listenToMessages();
  }

  void listenToMessages() {
    final url = Uri.parse(
      'https://sportface-f9594-default-rtdb.firebaseio.com/chats/${widget.groupId}.json',
    );
    http.get(url).then((res) {
      if (res.statusCode == 200 && mounted) {
        final Map<String, dynamic>? data = jsonDecode(res.body);
        final List<Map<String, dynamic>> tempMessages = [];

        data?.forEach((key, value) {
          tempMessages.add({
            'id': key,
            'text': value['text'],
            'senderId': value['senderId'],
            'timestamp': value['timestamp'],
          });
        });

        tempMessages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

        setState(() {
          messages = tempMessages;
        });

        // Scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    });
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final message = {
      "senderId": userId,
      "text": _controller.text.trim(),
      "timestamp": DateTime.now().millisecondsSinceEpoch
    };

    final url = Uri.parse(
      'https://sportface-f9594-default-rtdb.firebaseio.com/chats/${widget.groupId}.json',
    );

    await http.post(url, body: jsonEncode(message));
    _controller.clear();
    listenToMessages(); // reload to reflect new message
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['senderId'] == currentUserId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(maxWidth: 250),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
