
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:map_app/services/supabase_service.dart';

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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getSOSAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          final alerts = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Pie Chart to display alert types
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: _buildAlertPieChart(alerts),
                ),
                // ListView of users and their alerts
                Expanded(
                  child: ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      // Assuming joined profile data
                      final profile = alert['profiles'];
                      final userName = profile != null ? profile['full_name'] : "Unknown User";
                      final alertName = alert['alert_name'];
                      final time = alert['created_at'];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4.0,
                        child: ListTile(
                          title: Text(userName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Alert Type: $alertName"),
                              Text("Time: $time"),
                            ],
                          ),
                        ),
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

  Widget _buildAlertPieChart(List<Map<String, dynamic>> alerts) {
    // Reset the counts each time the chart is built
    lowBatteryAlerts = 0;
    shakePhoneAlerts = 0;

    // Count alerts for each type
    for (var alert in alerts) {
          final alertName = alert['alert_name'];

          if (alertName == 'Low_Battery_Alert') {
            lowBatteryAlerts++;
          } else if (alertName == 'shake_phone_Alert') {
            shakePhoneAlerts++;
          }
    }


    // Pie Chart Data
    return lowBatteryAlerts == 0 && shakePhoneAlerts == 0
        ? const Text('No SOS Alerts recorded')
        : PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: lowBatteryAlerts.toDouble(),
                  title: 'Low Battery',
                  color: Colors.red,
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: shakePhoneAlerts.toDouble(),
                  title: 'Shake Phone',
                  color: Colors.green,
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          );
  }
}
