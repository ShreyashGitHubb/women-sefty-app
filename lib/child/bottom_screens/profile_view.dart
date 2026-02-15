import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../child_login_screen.dart';
import 'profile_page.dart';

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
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data();
        print("Fetched User Data: $userData"); // Debugging: Log user data

        setState(() {
          name = userData['name'] ?? "No Name Available";
          email = userData['childEmail'] ?? "No Email Available";
          profilepic = userData['profilepic'];
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
      print("Error fetching profile: $e"); // Debugging: Log error
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
    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(msg: 'Logged out successfully');
    
    // Redirect to login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Replace with your LoginPage widget
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
