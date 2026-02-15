import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickHelpActions extends StatelessWidget {
  const QuickHelpActions({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _callEmergencyContact(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    await _launchUrl(callUri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Help'),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Replace with your actual emergency contact number retrieval logic
                _callEmergencyContact('112'); // Example: Pan-India emergency number
              },
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text('Call Emergency', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                // Replace with your app's SOS sharing functionality
                // This might involve getting current location and sharing via SMS/other means
                _launchUrl('sms:?body=I need help! My location is...');
              },
              icon: const Icon(Icons.message, color: Colors.white),
              label: const Text('Send SOS Message', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                // Replace with functionality to trigger an alarm sound
                // You might need a package for playing sounds
                debugPrint('Alarm triggered');
              },
              icon: const Icon(Icons.alarm, color: Colors.white),
              label: const Text('Trigger Alarm', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                // Replace with functionality to open a nearby safe places map
                // This might involve integrating with a maps service and showing relevant POIs
                _launchUrl('https://www.google.com/maps/search/safe+places+near+me');
              },
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text('Find Safe Places', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Important Note:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'This is a simplified UI for quick help actions. Actual women safety apps require robust background services, accurate location tracking, reliable communication methods, and proper permission handling.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}