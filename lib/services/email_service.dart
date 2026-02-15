import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EmailService {
  // Resend API Configuration
  static const String _resendApiKey = 're_CPxbJ5TY_7UK6QVNVGcuYPb87p3K7tVtz';
  
  // Verified sender email from Resend
  static const String _fromEmail = 'onboarding@resend.dev';
  
  // Recipient email (trusted contact who receives emergency alerts)
  static const String _recipientEmail = 'hme05825@gmail.com';
  
  static const String _resendApiUrl = 'https://api.resend.com/emails';

  /// Sends an urgent help email with the user's exact location
  static Future<bool> sendHelpEmail(Position position) async {
    try {
      // Get address from coordinates
      String address = await _getAddressFromCoordinates(position);
      
      // Create Google Maps link
      String mapsUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      
      // Create email body with HTML formatting
      String htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .alert-header { background-color: #dc3545; color: white; padding: 15px; border-radius: 5px; text-align: center; }
    .info-section { background-color: #f8f9fa; padding: 15px; margin: 15px 0; border-left: 4px solid #dc3545; }
    .location-details { margin: 10px 0; }
    .maps-button { 
      display: inline-block; 
      background-color: #28a745; 
      color: white; 
      padding: 12px 24px; 
      text-decoration: none; 
      border-radius: 5px; 
      margin-top: 15px;
    }
    .timestamp { color: #6c757d; font-size: 0.9em; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="alert-header">
      <h1>🚨 EMERGENCY HELP ALERT 🚨</h1>
    </div>
    
    <div class="info-section">
      <p><strong>This is an automated emergency alert from the Women Safety App.</strong></p>
      <p>A user has triggered the shake-to-help feature. Please take immediate action.</p>
    </div>
    
    <div class="info-section">
      <h2>📍 Location Details</h2>
      <div class="location-details">
        <p><strong>Address:</strong><br>${address}</p>
        <p><strong>Coordinates:</strong><br>
          Latitude: ${position.latitude.toStringAsFixed(6)}<br>
          Longitude: ${position.longitude.toStringAsFixed(6)}
        </p>
        <p><strong>Accuracy:</strong> ${position.accuracy.toStringAsFixed(2)} meters</p>
      </div>
      
      <a href="$mapsUrl" class="maps-button">📍 Open in Google Maps</a>
    </div>
    
    <div class="timestamp">
      <p>⏰ <strong>Alert triggered at:</strong> ${DateTime.now().toString()}</p>
    </div>
  </div>
</body>
</html>
      ''';

      // Plain text version as fallback
      String textBody = '''
🚨 EMERGENCY HELP ALERT 🚨

This is an automated emergency alert from the Women Safety App.
A user has triggered the shake-to-help feature. Please take immediate action.

📍 LOCATION DETAILS:
Address: $address

Coordinates:
Latitude: ${position.latitude.toStringAsFixed(6)}
Longitude: ${position.longitude.toStringAsFixed(6)}
Accuracy: ${position.accuracy.toStringAsFixed(2)} meters

Google Maps Link: $mapsUrl

⏰ Alert triggered at: ${DateTime.now()}
      ''';

      // Send email via Resend API
      final response = await http.post(
        Uri.parse(_resendApiUrl),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmail,
          'to': [_recipientEmail],
          'subject': '🚨 URGENT: Emergency Help Alert with Location',
          'html': htmlBody,
          'text': textBody,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Emergency email sent successfully');
        return true;
      } else {
        print('❌ Failed to send email: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending help email: $e');
      return false;
    }
  }

  /// Converts coordinates to a human-readable address
  static Future<String> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}'
            .replaceAll(RegExp(r',\s*,'), ',')
            .replaceAll(RegExp(r'^,\s*'), '')
            .replaceAll(RegExp(r',\s*$'), '');
      }
    } catch (e) {
      print('⚠️ Could not get address: $e');
    }
    
    // Fallback to coordinates if address lookup fails
    return 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}';
  }
}
