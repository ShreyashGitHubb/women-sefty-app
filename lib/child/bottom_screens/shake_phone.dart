import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShakeService {
  static ShakeService? _instance;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isShaking = false;
  DateTime? _shakeStartTime;
  int _remainingTime = 5; // Duration to detect shake (5 seconds)
  Timer? _countdownTimer;
  bool _isAlertSent = false;
  List<String> _trustedContacts = [];
  Function? _shakeCallback;

  // Singleton pattern for global access
  ShakeService._internal();

  factory ShakeService() {
    _instance ??= ShakeService._internal();
    return _instance!;
  }

  // Start listening to accelerometer events
  void startShakeDetection(Function shakeCallback) {
    _shakeCallback = shakeCallback;

    const double shakeThreshold = 12.0; // Adjust threshold as needed

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      double acceleration = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z);

      if (acceleration > shakeThreshold) {
        if (!_isShaking) {
          _shakeStartTime = DateTime.now();
          _isShaking = true;
          _remainingTime = 5; // Reset countdown
          _isAlertSent = false;
          startCountdown();
        }
      } else {
        stopCountdown();
        _isShaking = false;
      }
    });
  }

  // Stop listening to accelerometer events
  void stopShakeDetection() {
    _accelerometerSubscription?.cancel();
    _countdownTimer?.cancel();
  }

  // Start countdown after detecting shake
  void startCountdown() {
    _countdownTimer?.cancel(); // Cancel any existing timer
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
      } else {
        timer.cancel();
        if (!_isAlertSent) {
          sendLiveLocationToTrustedContacts();
          stopCountdown();
          _isShaking = false;
        }
      }
    });
  }

  // Stop countdown when shake is no longer detected
  void stopCountdown() {
    _countdownTimer?.cancel();
    _remainingTime = 0;
  }

  // Fetch trusted contacts from Firebase
  Future<void> fetchTrustedContacts() async {
    try {
      String userId = "exampleUserId"; // Replace with actual user ID logic

      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      _trustedContacts = snapshot.docs
          .map((doc) => doc['phone_number'] as String)
          .toList();
    } catch (e) {
      print('Failed to fetch contacts: $e');
    }
  }

  // Send live location to trusted contacts
  Future<void> sendLiveLocationToTrustedContacts() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String message =
          "Emergency! Here is my live location: https://www.google.com/maps?q=${position.latitude},${position.longitude}";

      for (String contact in _trustedContacts) {
        String encodedMessage = Uri.encodeComponent(message);
        Uri smsUri = Uri.parse("sms:$contact?body=$encodedMessage");

        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          throw 'Could not launch SMS to $contact';
        }
      }

      String emergencyNumber = "100"; // Emergency number for your country
      Uri callUri = Uri.parse("tel:$emergencyNumber");
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        throw 'Could not make a call to $emergencyNumber';
      }

      _isAlertSent = true;

      // Trigger the provided callback function (to notify the app)
      _shakeCallback?.call();
    } catch (e) {
      print('Failed to send location or make a call: $e');
    }
  }
}
