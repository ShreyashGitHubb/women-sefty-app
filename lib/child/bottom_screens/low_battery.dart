import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
 

class LowBatteryAlert {
  final Battery _battery = Battery();
  //late AudioPlayer _audioPlayer;
  //bool _isAlarmActive = false;
  int _batteryLevel = 100;
  double? latitude;
  double? longitude;
  
  LowBatteryAlert() {
    //_audioPlayer = AudioPlayer();
  }

  // Check battery level and handle low battery
  Future<void> checkBattery() async {
    _batteryLevel = await _battery.batteryLevel;
    if (_batteryLevel >= 10 ) {
      Fluttertoast.showToast(msg: "Battery is low! sending location...");
     await _createSOSAlert();
       await _getCurrentLocation();
    }
  }

 Future<void> _createSOSAlert() async {
  try {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "Unknown User";
    String alertId = Uuid().v4(); // Generate a unique alert ID

    // Prepare alert data
    final alertData = {
      'alert_name': 'Low Battery Alert',
      'alert_id': alertId,
      'timestamp': FieldValue.serverTimestamp(),
     // 'location': "https://www.google.com/maps?q=$latitude,$longitude", // Include location if available
     'latitude':latitude,
     'longtitude':longitude,
    };

    // Store SOS alert data inside the user's document under the sos_alert collection
    await FirebaseFirestore.instance
        .collection('users')        // Access 'users' collection
        .doc(userId)                // Access user's document
        .collection('sos_alert')    // Create the sos_alert collection inside the user document
        .add(alertData);            // Add the alert document

   // Fluttertoast.showToast(msg: "SOS alert stored successfully with ID: $alertId");
  } catch (e) {
    Fluttertoast.showToast(msg: "Error creating SOS alert: $e");
  }
}



  // Fetch current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: "Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: "Location permission denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
            msg: "Location permission permanently denied. Please enable it from settings.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      latitude = position.latitude;
      longitude = position.longitude;

      await _sendLocationToContacts();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching location: $e");
    }
  }



Future<void> _sendLocationToContacts() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    Fluttertoast.showToast(msg: "User not logged in.");
    return;
  }

  // Check if latitude and longitude are fetched
  if (latitude == null || longitude == null) {
    Fluttertoast.showToast(msg: "Please fetch your location first.");
    return;
  }

  try {
    // Store location in Firestore
     

    // Fetch emergency contacts
    QuerySnapshot contactsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .get();

    if (contactsSnapshot.docs.isEmpty) {
      Fluttertoast.showToast(msg: "No emergency contacts found.");
      return;
    }

   
    // Prepare message
    String message =
        "my battery is low! My current location is: https://www.google.com/maps?q=$latitude,$longitude";

 
 List<String> contactNumbers = [];
    for (QueryDocumentSnapshot contactDoc in contactsSnapshot.docs) {
      final contactData = contactDoc.data() as Map<String, dynamic>;
      final contactNumber = contactData['mobileNumber'];
      if (contactNumber != null && contactNumber.isNotEmpty) {
        contactNumbers.add(contactNumber);
      }
    }

    if (contactNumbers.isEmpty) {
      Fluttertoast.showToast(msg: "No valid contact numbers found.");
      return;
    }

    // Combine all contact numbers into a single URI
    Uri smsUri = Uri.parse(
      "sms:${contactNumbers.join(',')}?body=${Uri.encodeComponent(message)}",
    );

    // Launch SMS app with the prepared URI
    if (await launchUrl(smsUri)) {
      Fluttertoast.showToast(msg: "SMS app launched successfully.");
    } else {
      Fluttertoast.showToast(msg: "Could not launch SMS app.");
    }
  } catch (e) {
    Fluttertoast.showToast(msg: "Error: $e");
  }
  
}



  // Toggle alarm (play/pause sound)
   

  // Cleanup resources
  
}
