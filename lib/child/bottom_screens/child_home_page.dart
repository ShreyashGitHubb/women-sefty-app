import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../widgets/LiveSafe.dart';
import '../../widgets/home_widgets/customCarouel.dart';
import '../../widgets/home_widgets/custom_appBar.dart';
import '../../widgets/home_widgets/emergency.dart';
import '../../widgets/home_widgets/safehome/SafeHome.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int qindex = 0;
  bool isShaking = false;
  bool isAlertSent = false;
  DateTime? shakeStartTime;
  StreamSubscription? accelerometerSubscription;

  List<String> trustedContacts = [];
  int remainingTime = 1;
  Timer? countdownTimer;
  Timer? messageDisplayTimer;

  getRandomQuote() {
    Random random = Random();
    setState(() {
      qindex = random.nextInt(3);
    });
  }

  @override
  void initState() {
    super.initState();
    getRandomQuote();
    fetchTrustedContacts();
    startShakeDetection();
  }

  void startShakeDetection() {
    const double shakeThreshold = 12.0;

    accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > shakeThreshold) {
        if (!isShaking) {
          shakeStartTime = DateTime.now();
          isShaking = true;
          remainingTime = 1;
          isAlertSent = false;
          startCountdown();
        }
      } else {
        stopCountdown();
        isShaking = false;
      }
    });
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        if (!isAlertSent) {
          sendLiveLocationToTrustedContacts();
          stopCountdown();
          isShaking = false;
        }
      }
    });
  }

  void stopCountdown() {
    countdownTimer?.cancel();
    setState(() {
      remainingTime = 0;
    });
  }

  Future<void> fetchTrustedContacts() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "Unknown User";

      var snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('contacts')
              .get();

      setState(() {
        trustedContacts =
            snapshot.docs.map((doc) => doc['phone_number'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch contacts: $e')));
    }
  }

  Future<void> sendLiveLocationToTrustedContacts() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String message =
          "Emergency! Here is my live location: https://www.google.com/maps?q=${position.latitude},${position.longitude}";

      for (String contact in trustedContacts) {
        String encodedMessage = Uri.encodeComponent(message);
        Uri smsUri = Uri.parse("sms:$contact?body=$encodedMessage");

        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          throw 'Could not launch SMS to $contact';
        }
      }

      String emergencyNumber = "100";
      Uri callUri = Uri.parse("tel:$emergencyNumber");
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        throw 'Could not make a call to $emergencyNumber';
      }

      String userId = FirebaseAuth.instance.currentUser?.uid ?? "Unknown User";
      String alertId = const Uuid().v4();

      final alertData = {
        'alert_name': 'shake phone Alert',
        'alert_id': alertId,
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(position.latitude, position.longitude),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sos_alert')
          .add(alertData);

      setState(() {
        isAlertSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert sent ... emergency call made!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send location or make a call: $e')),
      );
    }
  }

  @override
  void dispose() {
    accelerometerSubscription?.cancel();
    countdownTimer?.cancel();
    messageDisplayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppbar(quoteIndex: qindex, onTap: getRandomQuote),
              const SizedBox(height: 20.0),
              const Customcarouel(),
              const SizedBox(height: 30.0),
              if (isShaking && !isAlertSent)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 40.0,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        "Shaking Detected!",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        "Sending alert in $remainingTime seconds...",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isShaking = false;
                            stopCountdown();
                            remainingTime = 0;
                          });
                        },
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text("Cancel"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor:
                              theme.colorScheme.onSecondaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      if (trustedContacts.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Alerting:",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            for (String contact in trustedContacts)
                              Text(
                                "- $contact",
                                style: theme.textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      if (trustedContacts.isEmpty)
                        Text(
                          "No trusted contacts added yet.",
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24.0),
              _buildSectionCard(
                context,
                title: "Emergency",
                icon: Icons.local_hospital_rounded,
                content: const Emergency(),
              ),
              const SizedBox(height: 16.0),
              _buildSectionCard(
                context,
                title: "Explore LiveSafe",
                icon: Icons.explore_rounded,
                content: const Livesafe(),
              ),
              const SizedBox(height: 16.0),
              _buildSectionCard(
                context,
                title: "Safe Home",
                icon: Icons.home,
                content: const SafeHome(),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8.0),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            content,
          ],
        ),
      ),
    );
  }
}
