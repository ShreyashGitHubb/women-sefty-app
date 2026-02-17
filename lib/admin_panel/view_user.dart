

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:map_app/services/supabase_service.dart';

class ViewUsers extends StatefulWidget {
  const ViewUsers({super.key});

  @override
  State<ViewUsers> createState() => _ViewUsersState();
}

class _ViewUsersState extends State<ViewUsers> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to remove user from Supabase
  Future<void> _removeUser(String userId) async {
    try {
      await SupabaseService.deleteProfile(userId);
      setState(() {}); // Trigger rebuild to refresh FutureBuilder
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getAllProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          final users = snapshot.data ?? [];

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
                      // ... (Pie chart code relies on counts, unmodified) ... 
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
                    final user = users[index];
                    final userId = user['id'];

                    // Determine which email to display based on the role
                    String emailField = "";
                    switch (user['type']) {
                      case "child":
                        emailField = user['child_email'] ?? "No Email"; // Note: snake_case from DB
                        break;
                      case "parent":
                        emailField = user['parent_email'] ?? "No Email";
                        break;
                      // Admin might store email in 'email' or parent_email depending on reg structure, 
                      // but let's assume 'email' from profile
                      case "admin":
                             emailField = user['email'] ?? "No Email";
                        break;
                      default:
                        emailField = user['email'] ?? "No Email";
                    }

                    return ListTile(
                      title: Text(user['full_name'] ?? "No Name"), // snake_case
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
