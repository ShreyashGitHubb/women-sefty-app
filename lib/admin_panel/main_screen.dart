import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../child/child_login_screen.dart';
import 'admin_review.dart';
import 'user_activity.dart';
import 'view_user.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.pink,
      ),
      body: AdminOptions(),
    );
  }
}

class AdminOptions extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

void _logout(BuildContext context) async {
    try {
      await _auth.signOut(); // Sign out the user
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()), // Navigate to LoginScreen
      );
    } catch (e) {
      // Handle errors during logout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during logout: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text("View All Users"),
          trailing: const Icon(Icons.people),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewUsers()),
          ),
        ),
        ListTile(
          title: const Text("Received Reviews"),
          trailing: const Icon(Icons.report),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewReviews()),
          ),
        ),
        ListTile(
          title: const Text("User Activity"),
          trailing: const Icon(Icons.analytics),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserActivity()),
            );
          },
        ),
        ListTile(
          title: const Text("Logout"),
          trailing: const Icon(Icons.logout),
          onTap: () => _logout(context), // Call the logout function
        )
      ],
    );
  }
}
