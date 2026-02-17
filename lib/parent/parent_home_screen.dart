import 'package:flutter/material.dart';
import 'package:map_app/services/supabase_service.dart';
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
          await SupabaseService.signOut();
          goTo(context, LoginScreen());
        } catch(e){
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getChildren(SupabaseService.currentUser?.email ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return showLoadingDialog(context);
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return Center(child: Text("No children found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (BuildContext context, int index) {
              final d = snapshot.data![index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  color: const Color.fromARGB(255, 250, 163, 192),
                  child: ListTile(
                    onTap: (){
                      goTo(context, ChatScreen(
                        currentUserId: SupabaseService.currentUser!.id, 
                        friendId: d['id'], 
                        friendName: d['full_name']
                      ));
                    },
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(d['full_name']),
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