
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class UserActivity extends StatefulWidget {
  const UserActivity({super.key});

  @override
  _UserActivityState createState() => _UserActivityState();
}

class _UserActivityState extends State<UserActivity> {
  int lowBatteryAlerts = 0;
  int shakePhoneAlerts = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS Activity"),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('type', isEqualTo: 'child') // Filter for children only
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Pie Chart to display alert types
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: _buildAlertPieChart(users),
                ),
                // ListView of users and their alerts
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user.id; // User ID from Firestore
                      final userName = user['name'] ?? "Unknown User";

                      // Fetch SOS alerts for this user
                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('sos_alert')
                            .get(), // Get SOS alerts from the sub-collection
                        builder: (context, sosSnapshot) {
                          if (!sosSnapshot.hasData) {
                            return const ListTile(title: Text("Loading SOS alerts..."));
                          }

                          final sosAlerts = sosSnapshot.data!.docs;
                          final sosAlertsCount = sosAlerts.length;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 4.0,
                            child: ListTile(
                              title: Text(userName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("SOS Alerts: $sosAlertsCount"),
                                  for (var alert in sosAlerts)
                                    Text("Alert Type: ${alert['alert_name'] ?? 'Unknown'}"), // Display alert type
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Function to build the Pie Chart for SOS alert types
  Widget _buildAlertPieChart(List<QueryDocumentSnapshot> users) {
    // Reset the counts each time the chart is built
    lowBatteryAlerts = 0;
    shakePhoneAlerts = 0;

    // List to hold Futures for each user’s SOS alerts
    List<Future<void>> sosAlertFutures = [];

    // Count alerts for each type
    for (var user in users) {
      final userId = user.id;

      // Add the future of each SOS alerts query to the list
      sosAlertFutures.add(FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sos_alert')
          .get()
          .then((sosSnapshot) {
        final sosAlerts = sosSnapshot.docs;

        for (var alert in sosAlerts) {
          final alertName = alert['alert_name'];

          if (alertName == 'Low_Battery_Alert') {
            lowBatteryAlerts++;
          } else if (alertName == 'shake_phone_Alert') {
            shakePhoneAlerts++;
          }
        }
      }));
    }

    // Wait for all futures to complete and update the state
    Future.wait(sosAlertFutures).then((_) {
      setState(() {
        // Ensure the state is updated after all alerts are counted
      });
    });

    // Pie Chart Data
    return lowBatteryAlerts == 0 && shakePhoneAlerts == 0
        ? const Text('No SOS Alerts recorded')
        : PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: lowBatteryAlerts.toDouble(),
                  title: 'Low Battery Alerts',
                  color: Colors.red,
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: shakePhoneAlerts.toDouble(),
                  title: 'Shake Phone Alerts',
                  color: Colors.green,
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          );
  }
}
