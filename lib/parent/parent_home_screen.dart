import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../chat_module/chat_screen.dart';
import '../child/child_login_screen.dart';
import '../utils/constans.dart';

class ParentHomeScreen extends StatelessWidget{
  const ParentHomeScreen({Key?key}):super(key:key);
@override
  Widget build(BuildContext context) {
    return Scaffold(
         drawer: Drawer(
        child: Column(
          children: [DrawerHeader(child: Container(),
          ),

          ListTile(
           title:  TextButton(onPressed: ()async{
        try{
          FirebaseAuth.instance.signOut();
          goTo(context, LoginScreen());
        }on FirebaseAuthException catch(e){
          dialog(context, e.toString());
        }

      }, child: Text("SIGN OUT"))

          ),
        
          ],
        ),
      ),
      
      appBar: AppBar(
        title: const Text("SELECT CHILD"),
        backgroundColor: Colors.pink, // Set AppBar background color to pink
      ),
       body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('type', isEqualTo: 'child')
            .where('parentEmail', isEqualTo: FirebaseAuth.instance.currentUser!.email)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return showLoadingDialog((context));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              final d = snapshot.data!.docs[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  color: const Color.fromARGB(255, 250, 163, 192),
                  child: ListTile(
                    onTap: (){
                      goTo(context, ChatScreen(currentUserId: FirebaseAuth.instance.currentUser!.uid, friendId: d.id, friendName: d['name']));
                     // Navigator.push(context, MaterialPageRoute(builder: builder))
                    },
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(d['name']),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  
  }

}