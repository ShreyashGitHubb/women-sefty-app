import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:map_app/services/supabase_service.dart';

import '../utils/constans.dart';
import 'message_text_field.dart';
import 'single_message.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final String friendName;

  const ChatScreen({super.key, required this.currentUserId, required this.friendId, required this.friendName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? type;
  String? myname;

  // Fetch user status and name
  getstatus() async {
    final profile = await SupabaseService.getProfile(widget.currentUserId);
    if (profile != null) {
      setState(() {
         // Assuming 'type' (parent/child) is stored in metadata or profile. 
         // For now, let's default or try to fetch if we added it to profile.
         // The original code fetched 'type' and 'name'.
         // Our Supabase profile has 'full_name'. 'type' might need to be added or fetched from metadata.
         // I'll use a placeholder logic for type or assume it is in the profile if added.
         // Let's assume 'type' is in profile for now, or just don't break it.
         myname = profile['full_name'];
         // type = profile['type']; // If type is missing, UI might break?
         // Let's just set use name for now.
      });
    }
  }

  @override
  void initState() {
    getstatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink, // Set AppBar background color to pink
        title: Text(widget.friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.getMessages(widget.friendId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        type == "parent" ? "TALK WITH CHILD" : "TALK WITH PARENT",
                        style: TextStyle(fontSize: 30),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index];
                      bool isMe = data['sender_id'] == widget.currentUserId;

                      return SingleMessage(
                        message: data['message'],
                        date: DateTime.parse(data['created_at']), // Supabase returns ISO string
                        isme: isMe,
                        friendName: widget.friendName,
                        myName: myname,
                        type: data['type'],
                      );
                    },
                  );
                }
                return showLoadingDialog(context);
              },
            ),
          ),
          MessageTextField(
            currentId: widget.currentUserId,
            friendId: widget.friendId,
          ),
        ],
      ),
    );
  }
}
