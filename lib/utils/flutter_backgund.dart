// import 'dart:async';
// import 'dart:ui';

// import 'package:background_location/background_location.dart';
// import 'package:background_sms/background_sms.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:telephony/telephony.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:vibration/vibration.dart';
// import 'package:sensors_plus/sensors_plus.dart';


 
//   double? latitude;
//   double? longitude;
//   Future<void> _getCurrentLocation() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         Fluttertoast.showToast(msg: "Location services are disabled.");
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           Fluttertoast.showToast(msg: "Location permission denied.");
//           return;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         Fluttertoast.showToast(
//             msg: "Location permission permanently denied. Please enable it from settings.");
//         return;
//       }

//       Position position = await Geolocator.getCurrentPosition();
//       latitude = position.latitude;
//       longitude = position.longitude;

//       await _sendLocationToContacts();
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error fetching location: $e");
//     }
//   }


// Future<void> _sendLocationToContacts() async {
//   final userId = FirebaseAuth.instance.currentUser?.uid;
//   double? latitude;
//   double? longitude;
//   if (userId == null) {
//     Fluttertoast.showToast(msg: "User not logged in.");
//     return;
//   }

//   // Check if latitude and longitude are fetched
//   if (latitude == null || longitude == null) {
//     Fluttertoast.showToast(msg: "Please fetch your location first.");
//     return;
//   }

//   try {
//     // Store location in Firestore
     

//     // Fetch emergency contacts
//     QuerySnapshot contactsSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .collection('contacts')
//         .get();

//     if (contactsSnapshot.docs.isEmpty) {
//       Fluttertoast.showToast(msg: "No emergency contacts found.");
//       return;
//     }

   
//     // Prepare message
//     String message =
//         "my battery is low! My current location is: https://www.google.com/maps?q=$latitude,$longitude";

 
//  List<String> contactNumbers = [];
//     for (QueryDocumentSnapshot contactDoc in contactsSnapshot.docs) {
//       final contactData = contactDoc.data() as Map<String, dynamic>;
//       final contactNumber = contactData['mobileNumber'];
//       if (contactNumber != null && contactNumber.isNotEmpty) {
//         contactNumbers.add(contactNumber);
//       }
//     }

//     if (contactNumbers.isEmpty) {
//       Fluttertoast.showToast(msg: "No valid contact numbers found.");
//       return;
//     }

//     // Combine all contact numbers into a single URI
//     Uri smsUri = Uri.parse(
//       "sms:${contactNumbers.join(',')}?body=${Uri.encodeComponent(message)}",
//     );

//     // Launch SMS app with the prepared URI
//     if (await launchUrl(smsUri)) {
//       Fluttertoast.showToast(msg: "SMS app launched successfully.");
//     } else {
//       Fluttertoast.showToast(msg: "Could not launch SMS app.");
//     }
//   } catch (e) {
//     Fluttertoast.showToast(msg: "Error: $e");
//   }
  
// }


// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();
//   AndroidNotificationChannel channel = AndroidNotificationChannel(
//     "script academy",
//     "foregrounf service",
//     "used for imp notifcation",
//     importance: Importance.low,
//   );
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//       iosConfiguration: IosConfiguration(),
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         isForegroundMode: true,
//         autoStart: true,
//         notificationChannelId: "script academy",
//         initialNotificationTitle: "foregrounf service",
//         initialNotificationContent: "initializing",
//         foregroundServiceNotificationId: 888,
//       ));
//   service.startService();
// }

// @pragma('vm-entry-point')
// void onStart(ServiceInstance service) async {
//   Location? clocation;

//   DartPluginRegistrant.ensureInitialized();
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });
//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
//   await BackgroundLocation.setAndroidNotification(
//     title: "Location tracking is running in the background!",
//     message: "You can turn it off from settings menu inside the app",
//     icon: '@mipmap/ic_logo',
//   );
//   BackgroundLocation.startLocationService(
//     distanceFilter: 20,
//   );

//   BackgroundLocation.getLocationUpdates((location) {
//     clocation = location;
//   });
//   if (service is AndroidServiceInstance) {
//     if (await service.isForegroundService()) {
//       // await Geolocator.getCurrentPosition(
//       //         desiredAccuracy: LocationAccuracy.high,
//       //         forceAndroidLocationManager: true)
//       //     .then((Position position) {
//       //   _curentPosition = position;
//       //   print("bg location ${position.latitude}");
//       // }).catchError((e) {
//       //   //Fluttertoast.showToast(msg: e.toString());
//       // });

//       ShakeDetector.autoStart(
//           shakeThresholdGravity: 7,
//           shakeSlopTimeMS: 500,
//           shakeCountResetTime: 3000,
//           minimumShakeCount: 1,
//           onPhoneShake: () async {
//             if (await Vibration.hasVibrator() ?? false) {
//               print("Test 2");
//               if (await Vibration.hasCustomVibrationsSupport() ?? false) {
//                 print("Test 3");
//                 Vibration.vibrate(duration: 1000);
//               } else {
//                 print("Test 4");
//                 Vibration.vibrate();
//                 await Future.delayed(Duration(milliseconds: 500));
//                 Vibration.vibrate();
//               }
//               print("Test 5");
//             }
//             String messageBody =
//                 "https://www.google.com/maps/search/?api=1&query=${clocation!.latitude}%2C${clocation!.longitude}";
//             sendMessage(messageBody);
//           });

//       flutterLocalNotificationsPlugin.show(
//         888,
//         "women safety app",
//         clocation == null
//             ? "please enable location to use app"
//             : "shake feature enable ${clocation!.latitude}",
//         NotificationDetails(
//             android: AndroidNotificationDetails(
//           "script academy",
//           "foregrounf service",
//           "used for imp notifcation",
//           icon: 'ic_bg_service_small',
//           ongoing: true,
//         )),
//       );
//     }
//   }
// }


