import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get().then((value) {
      setState(() {
        type = value.data()!['type'];
        myname = value.data()!['name'];
      });
    });
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
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUserId)
                  .collection('messages')
                  .doc(widget.friendId)
                  .collection('chats')
                  .orderBy('date', descending: false)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        type == "parent" ? "TALK WITH CHILD" : "TALK WITH PARENT",
                        style: TextStyle(fontSize: 30),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      bool isMe = snapshot.data!.docs[index]['senderId'] == widget.currentUserId;
                      final data = snapshot.data!.docs[index];

                      return Dismissible(
                        key: UniqueKey(),
                        onDismissed: (direction) async {
                          // Correct collection path for deletion
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.currentUserId)
                              .collection('messages') // Correct path
                              .doc(widget.friendId)
                              .collection('chats')
                              .doc(data.id)
                              .delete();

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.friendId)
                              .collection('messages') // Correct path
                              .doc(widget.currentUserId)
                              .collection('chats')
                              .doc(data.id)
                              .delete()
                              .then((value) => Fluttertoast.showToast(msg: 'Message deleted successfully'))
                              .catchError((e) {
                            Fluttertoast.showToast(msg: 'Failed to delete message: $e');
                          });
                        },
                        child: SingleMessage(
                          message: data['message'],
                          date: data['date'],
                          isme: isMe,
                          friendName: widget.friendName,
                          myName: myname,
                          type: data['type'],
                        ),
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
