import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Gmail SMTP Configuration
  static const String _gmailEmail = 'hme05825@gmail.com';
  static const String _gmailAppPassword = 'ccnq oygl pzdk zqgz'; // App Password provided by user
  
  // Resend API Configuration (Fallback)
  static const String _resendApiKey = 're_CPxbJ5TY_7UK6QVNVGcuYPb87p3K7tVtz';
  static const String _fromEmailResend = 'onboarding@resend.dev';
  
  // Placeholder for default recipient if none provided
  static const String _defaultRecipientEmail = 'hme05825@gmail.com';
  
  static const String _resendApiUrl = 'https://api.resend.com/emails';

  /// Sends an urgent help email with the user's exact location
  /// Tries SMTP first, then falls back to Resend API
  static Future<bool> sendHelpEmail(Position position, List<String> recipients) async {
    // If no recipients provided, use default
    if (recipients.isEmpty) {
      recipients = [_defaultRecipientEmail];
    }
    
    // Filter out empty strings
    recipients = recipients.where((e) => e.isNotEmpty).toList();
    
    if (recipients.isEmpty) {
       print('⚠️ No valid recipients found.');
       return false;
    }

    try {
      // 1. Try sending via Gmail SMTP
      bool smtpSuccess = await _sendViaGmailSMTP(position, recipients);
      if (smtpSuccess) {
        return true;
      }
      
      print('⚠️ SMTP failed, falling back to Resend API...');
      
      // 2. Fallback to Resend API
      return await _sendViaResendAPI(position, recipients);
    } catch (e) {
      print('❌ Error in email sequence: $e');
      return false;
    }
  }

  static Future<bool> _sendViaGmailSMTP(Position position, List<String> recipients) async {
    final smtpServer = gmail(_gmailEmail, _gmailAppPassword);
    
    // Get address
    String address = await _getAddressFromCoordinates(position);
    String mapsUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

    final message = Message()
      ..from = Address(_gmailEmail, 'Women Safety App')
      ..recipients.addAll(recipients)
      ..subject = '🚨 URGENT: Emergency Help Alert via Gmail'
      ..html = _generateHtmlBody(address, mapsUrl, position, "Gmail SMTP");

    try {
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent via Gmail SMTP: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('❌ Gmail SMTP Error: $e');
      return false; // Trigger fallback
    }
  }

  static Future<bool> _sendViaResendAPI(Position position, List<String> recipients) async {
    try {
      String address = await _getAddressFromCoordinates(position);
      String mapsUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      
      // Resend might have limits, but we send as list
      final response = await http.post(
        Uri.parse(_resendApiUrl),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmailResend,
          'to': recipients,
          'subject': '🚨 URGENT: Emergency Help Alert (Resend Fallback)',
          'html': _generateHtmlBody(address, mapsUrl, position, "Resend API"),
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent via Resend API');
        return true;
      } else {
        print('❌ Resend API Failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Resend Error: $e');
      return false;
    }
  }
  
  static String _generateHtmlBody(String address, String mapsUrl, Position position, String method) {
      return '''
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
    .footer { margin-top: 20px; font-size: 0.8em; color: #777; }
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
      <p><em>Sent via: $method</em></p>
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
    
    <div class="footer">
      <p>⏰ Alert triggered at: ${DateTime.now().toString()}</p>
    </div>
  </div>
</body>
</html>
      ''';
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
