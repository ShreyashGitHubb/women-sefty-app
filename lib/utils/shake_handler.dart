import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/email_service.dart';

class ShakeHandler {
  static StreamSubscription<AccelerometerEvent>? _subscription;
  static bool _isProcessing = false;
  static DateTime? _lastShakeTime;
  static const Duration _cooldownDuration = Duration(seconds: 30);
  
  // Shake detection parameters
  static const double _shakeThreshold = 2.7; // Gravity threshold
  static const int _shakeDuration = 500; // ms
  static int _shakeCount = 0;
  static DateTime? _firstShakeTime;

  /// Initialize the shake detector using sensors_plus
  static void initialize(BuildContext context) {
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      _detectShake(event, context);
    });
    
    print('🔔 Shake detector initialized - Shake your phone 3 times for emergency help');
  }

  /// Detect shake from accelerometer data
  static void _detectShake(AccelerometerEvent event, BuildContext context) {
    // Calculate acceleration magnitude
    double x = event.x;
    double y = event.y;
    double z = event.z;
    
    double acceleration = sqrt(x * x + y * y + z * z);
    double gForce = acceleration / 9.81; // Normalize to g-force
    
    // Check if acceleration exceeds threshold
    if (gForce > _shakeThreshold) {
      DateTime now = DateTime.now();
      
      if (_firstShakeTime == null) {
        _firstShakeTime = now;
        _shakeCount = 1;
      } else {
        int timeDiff = now.difference(_firstShakeTime!).inMilliseconds;
        
        if (timeDiff < _shakeDuration * 3) {
          _shakeCount++;
          
          // If 3 shakes detected within time window
          if (_shakeCount >= 3) {
            _handleShake(context);
            _resetShakeDetection();
          }
        } else {
          // Reset if too much time passed
          _resetShakeDetection();
        }
      }
    }
  }

  /// Reset shake detection counters
  static void _resetShakeDetection() {
    _firstShakeTime = null;
    _shakeCount = 0;
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

      // Send help email
      bool emailSent = await EmailService.sendHelpEmail(position);

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
