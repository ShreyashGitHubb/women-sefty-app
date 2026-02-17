import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:map_app/services/supabase_service.dart';

import '../child_login_screen.dart';
import 'profile_page.dart';
// import '../../login.dart'; 

class ProfileViewPage extends StatefulWidget {
  const ProfileViewPage({super.key});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  String? name = "Fetching...";
  String? email = "Fetching...";
  String? profilepic;

  // Fetch user data from Firestore
  Future<void> getUserData() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
          Fluttertoast.showToast(msg: "No user logged in");
          return;
      }

      final userData = await SupabaseService.getProfile(user.id);

      if (userData != null) {
        print("Fetched User Data: $userData"); 

        setState(() {
          name = userData['full_name'] ?? "No Name Available"; // 'full_name' matches Supabase table
          email = userData['email'] ?? "No Email Available";
          // profilepic = userData['profilepic']; // TODO: Add profile pic support
        });
      } else {
        Fluttertoast.showToast(msg: "No user data found");
        setState(() {
          name = "No Name Available";
          email = "No Email Available";
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching profile: $e");
      print("Error fetching profile: $e"); 
      setState(() {
        name = "Error Loading Name";
        email = "Error Loading Email";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text(
          "Profile",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
         IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    await SupabaseService.signOut();
    Fluttertoast.showToast(msg: 'Logged out successfully');
    
    // Redirect to login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), 
    );
  },
)

        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.pink[100],
                backgroundImage:
                    profilepic != null ? FileImage(File(profilepic!)) : null,
                child: profilepic == null
                    ? Icon(
                        Icons.account_circle,
                        size: 100,
                        color: Colors.pinkAccent,
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                name ?? "Fetching...",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                email ?? "Fetching...",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
