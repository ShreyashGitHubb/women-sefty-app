

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ViewUsers extends StatefulWidget {
  const ViewUsers({super.key});

  @override
  State<ViewUsers> createState() => _ViewUsersState();
}

class _ViewUsersState extends State<ViewUsers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to remove user from Firestore
  Future<void> _removeUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User removed successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove user: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Users"),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          // Calculate counts
          int totalUsers = users.length;
          int adminUsers = users.where((user) => user['type'] == 'admin').length;
          int childUsers = users.where((user) => user['type'] == 'child').length;
          int parentUsers = users.where((user) => user['type'] == 'parent').length;

          return Column(
            children: [
              // Display user statistics with a pie chart
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "User Statistics",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: adminUsers.toDouble(),
                                color: Colors.blue,
                                title: "Admins",
                                titleStyle: const TextStyle(fontSize: 14, color: Colors.white),
                              ),
                              PieChartSectionData(
                                value: childUsers.toDouble(),
                                color: Colors.orange,
                                title: "Children",
                                titleStyle: const TextStyle(fontSize: 14, color: Colors.white),
                              ),
                              PieChartSectionData(
                                value: parentUsers.toDouble(),
                                color: Colors.green,
                                title: "Parents",
                                titleStyle: const TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Total Users: $totalUsers\nAdmins: $adminUsers\nChildren: $childUsers\nParents: $parentUsers",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              // Display user list
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;

                    // Determine which email to display based on the role
                    String emailField = "";
                    switch (user['type']) {
                      case "child":
                        emailField = user['childEmail'] ?? "No Email";
                        break;
                      case "parent":
                        emailField = user['parentEmail'] ?? "No Email";
                        break;
                      case "admin":
                        emailField = user['adminEmail'] ?? "No Email";
                        break;
                      default:
                        emailField = "No Email";
                    }

                    return ListTile(
                      title: Text(user['name'] ?? "No Name"),
                      subtitle: Text(emailField),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(user['type'] ?? "No Role"),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Show a confirmation dialog before deleting
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Remove User"),
                                  content: const Text(
                                      "Are you sure you want to remove this user?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _removeUser(userId); // Call the delete function
                                        Navigator.pop(context); // Close the dialog
                                      },
                                      child: const Text("Remove"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
