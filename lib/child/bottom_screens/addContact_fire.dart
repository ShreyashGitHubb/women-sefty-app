// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
// import '../child_login_screen.dart';
// import 'contacts_fire.dart';

class AddContactLocal extends StatefulWidget {
  const AddContactLocal({super.key});

  @override
  State<AddContactLocal> createState() => _AddContactLocalState();
}

class _AddContactLocalState extends State<AddContactLocal> {
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsData = prefs.getStringList('emergency_contacts') ?? [];
    setState(() {
      _contacts =
          contactsData.map((contactString) {
            final parts = contactString.split(',');
            return {'id': parts[0], 'name': parts[1], 'mobileNumber': parts[2]};
          }).toList();
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsData =
        _contacts
            .map(
              (contact) =>
                  '${contact['id']},${contact['name']},${contact['mobileNumber']}',
            )
            .toList();
    await prefs.setStringList('emergency_contacts', contactsData);
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);

    try {
      PermissionStatus status = await Permission.phone.request();
      print("Phone permission status: $status"); // Added logging

      if (status.isGranted) {
        final launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          Fluttertoast.showToast(
            msg: "Could not place call. Please check the number format.",
          );
        }
      } else if (status.isDenied) {
        Fluttertoast.showToast(
          msg:
              "Phone call permission denied. Please grant it in the app settings.",
        );
        openAppSettings(); // Open app settings for the user to grant permission
      } else if (status.isPermanentlyDenied) {
        Fluttertoast.showToast(
          msg:
              "Phone call permission permanently denied. Please enable it in the app settings.",
        );
        openAppSettings(); // Open app settings
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  Future<void> _deleteContact(String contactId) async {
    setState(() {
      _contacts.removeWhere((contact) => contact['id'] == contactId);
    });
    await _saveContacts();
    Fluttertoast.showToast(msg: "Contact removed successfully");
  }

  Future<void> _addContact(String name, String mobileNumber) async {
    if (name.isNotEmpty && mobileNumber.isNotEmpty) {
      setState(() {
        _contacts.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': name,
          'mobileNumber': mobileNumber,
        });
      });
      await _saveContacts();
      Fluttertoast.showToast(msg: "Contact added successfully");
    } else {
      Fluttertoast.showToast(msg: "Please enter both name and mobile number");
    }
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final mobileNumberController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              TextField(
                controller: mobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'Mobile Number'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _addContact(nameController.text, mobileNumberController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.pink,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _showAddContactDialog(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text("Add Emergency Contacts"),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Card(
                      color: Colors.pink.shade50,
                      child: ListTile(
                        title: Text(contact['name']!),
                        subtitle: Text("${contact['mobileNumber']!}"),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await _makePhoneCall(
                                    contact['mobileNumber']!,
                                  );
                                },
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.pink,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await _deleteContact(contact['id']!);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SafeHome extends StatefulWidget {
  const SafeHome({Key? key}) : super(key: key);

  @override
  _SafeHomeState createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  String locationMessage = 'Current location not fetched';
  String? latitude;
  String? longitude;
  bool isFetchingLocation = false;

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg:
            'Location permissions are permanently denied, we cannot request permissions.',
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location: $e');
      return null;
    }
  }

  void _openGoogleMaps() async {
    if (latitude != null && longitude != null) {
      final Uri googleMapsUri = Uri.parse(
        "https://www.google.com/maps?q=$latitude,$longitude",
      );
      if (await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      )) {
        print("Google Maps opened successfully.");
      } else {
        Fluttertoast.showToast(msg: "Could not open Google Maps.");
      }
    } else {
      Fluttertoast.showToast(msg: "Please fetch your location first.");
    }
  }

  Future<void> _sendLocationToContacts() async {
    if (latitude == null || longitude == null) {
      Fluttertoast.showToast(msg: "Please fetch your location first.");
      return;
    }

    String googleMapsLink =
        "https://www.google.com/maps?q=$latitude,$longitude";
    String message = "I need help! My current location is: $googleMapsLink";

    try {
      await Share.share(message);
      Fluttertoast.showToast(msg: "Share dialog opened successfully.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error sharing location: $e");
    }
  }

  void showModelSafeHome(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "SEND YOUR CURRENT LOCATION IMMEDIATELY TO YOUR EMERGENCY CONTACTS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(locationMessage, textAlign: TextAlign.center),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed:
                          isFetchingLocation
                              ? null
                              : () async {
                                setState(() {
                                  isFetchingLocation = true;
                                });
                                final position = await _getCurrentLocation();
                                if (position != null) {
                                  setState(() {
                                    latitude = position.latitude.toString();
                                    longitude = position.longitude.toString();
                                    locationMessage =
                                        "Latitude: $latitude, Longitude: $longitude";
                                  });
                                  Fluttertoast.showToast(
                                    msg: "Location fetched successfully.",
                                  );
                                }
                                setState(() {
                                  isFetchingLocation = false;
                                });
                              },
                      child:
                          isFetchingLocation
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text("Get Location"),
                    ),
                    SizedBox(height: 10),
                    PrimaryButton(
                      onPressed: _openGoogleMaps,
                      title: ("Open in Google Maps"),
                    ),
                    SizedBox(height: 20),
                    PrimaryButton(
                      onPressed: _sendLocationToContacts,
                      title: ("Send Location"),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModelSafeHome(context),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width * 0.7,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListTile(
                      title: Text(
                        'Send Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      subtitle: Text(
                        "Share your location with emergency contacts",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/location.jpg',
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: MediaQuery.of(context).size.width * 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;

  const PrimaryButton({Key? key, required this.onPressed, required this.title})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }
}
