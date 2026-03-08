import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/email_service.dart';

class ShakeHandler {
  static StreamSubscription<AccelerometerEvent>? _subscription;
  static bool _isProcessing = false;
  static DateTime? _lastShakeTime;
  static const Duration _cooldownDuration = Duration(seconds: 30);
  
  // Shake detection parameters — tuned to match app-level shake (like Instagram/YouTube)
  // Normal walking/handling produces ~1.0–2.0g. A deliberate shake starts at ~3.0g.
  static const double _shakeThreshold = 3.5;   // g-force required per shake (raised from 2.7)
  static const int _shakeWindowMs = 1500;       // total window to collect 3 shakes (ms)
  static const int _shakeDebounceMs = 300;       // min gap between individual shakes (ms)
  static int _shakeCount = 0;
  static DateTime? _firstShakeTime;
  static DateTime? _lastSingleShakeTime;         // debounce individual shake pulses

  /// Initialize the shake detector using sensors_plus
  static void initialize(BuildContext context) {
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      _detectShake(event, context);
    });
    print('🔔 Shake detector initialized — shake firmly 3× for emergency help');
  }

  /// Detect shake from accelerometer data
  static void _detectShake(AccelerometerEvent event, BuildContext context) {
    double x = event.x;
    double y = event.y;
    double z = event.z;

    double acceleration = sqrt(x * x + y * y + z * z);
    double gForce = acceleration / 9.81; // Normalize to g-force

    if (gForce > _shakeThreshold) {
      DateTime now = DateTime.now();

      // Debounce: ignore if the last individual shake was too recent
      // (this collapses a single shake "burst" of many high-g samples into one count)
      if (_lastSingleShakeTime != null &&
          now.difference(_lastSingleShakeTime!).inMilliseconds < _shakeDebounceMs) {
        return;
      }
      _lastSingleShakeTime = now;

      if (_firstShakeTime == null) {
        _firstShakeTime = now;
        _shakeCount = 1;
      } else {
        int timeDiff = now.difference(_firstShakeTime!).inMilliseconds;

        if (timeDiff < _shakeWindowMs) {
          _shakeCount++;
          // 3 deliberate shakes within the time window = emergency
          if (_shakeCount >= 3) {
            _handleShake(context);
            _resetShakeDetection();
          }
        } else {
          // Time window expired — start fresh from this shake
          _firstShakeTime = now;
          _shakeCount = 1;
        }
      }
    }
  }

  /// Reset shake detection counters
  static void _resetShakeDetection() {
    _firstShakeTime = null;
    _shakeCount = 0;
    _lastSingleShakeTime = null;
  }

  /// Handle shake event
  static Future<void> _handleShake(BuildContext context) async {
    // Prevent multiple simultaneous shake events
    if (_isProcessing) {
      print('⏳ Already processing a shake event...');
      return;
    }

    // Cooldown check to prevent accidental multiple alerts
    if (_lastShakeTime != null) {
      final timeSinceLastShake = DateTime.now().difference(_lastShakeTime!);
      if (timeSinceLastShake < _cooldownDuration) {
        final remainingSeconds = (_cooldownDuration - timeSinceLastShake).inSeconds;
        Fluttertoast.showToast(
          msg: "⏱️ Please wait $remainingSeconds seconds before sending another alert",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }
    }

    _isProcessing = true;
    _lastShakeTime = DateTime.now();

    try {
      // Show initial feedback
      Fluttertoast.showToast(
        msg: "🚨 Emergency alert activated! Getting your location...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );

      // Check and request location permission
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        Fluttertoast.showToast(
          msg: "❌ Location permission denied. Please enable location access.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        _isProcessing = false;
        return;
      }

      // Get high-accuracy location
      Position position = await _getCurrentLocation();

      // Get trusted contacts emails from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final contactsData = prefs.getStringList('emergency_contacts') ?? [];
      List<String> recipients = [];
      
      for (String contact in contactsData) {
        final parts = contact.split(',');
        // Check if email exists (index 3)
        if (parts.length >= 4 && parts[3].isNotEmpty) {
          recipients.add(parts[3]);
        }
      }

      // Send help email
      bool emailSent = await EmailService.sendHelpEmail(position, recipients);

      if (emailSent) {
        Fluttertoast.showToast(
          msg: "✅ Emergency alert sent successfully with your location!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        
        // Show confirmation dialog
        if (context.mounted) {
          _showConfirmationDialog(context, position);
        }
      } else {
        Fluttertoast.showToast(
          msg: "❌ Failed to send alert. Please check your internet connection.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Error handling shake: $e');
      Fluttertoast.showToast(
        msg: "❌ Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Check and request location permission
  static Future<bool> _checkLocationPermission() async {
    PermissionStatus permission = await Permission.location.status;

    if (permission.isDenied) {
      permission = await Permission.location.request();
    }

    if (permission.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return permission.isGranted;
  }

  /// Get current location with high accuracy
  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    );
  }

  /// Show confirmation dialog
  static void _showConfirmationDialog(BuildContext context, Position position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Alert Sent', style: TextStyle(color: Colors.green[900])),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your emergency alert has been sent successfully!',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 Your Location:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text('Lat: ${position.latitude.toStringAsFixed(6)}'),
                    Text('Lon: ${position.longitude.toStringAsFixed(6)}'),
                    Text('Accuracy: ${position.accuracy.toStringAsFixed(1)}m'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Help is on the way! 🚑',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  /// Dispose the shake detector
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _resetShakeDetection();
    print('🔕 Shake detector disposed');
  }
}
