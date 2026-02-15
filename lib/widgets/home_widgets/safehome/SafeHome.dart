import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package

import '../../../components/PrimaryButton.dart';

class SafeHome extends StatefulWidget {
  const SafeHome({Key? key}) : super(key: key);

  @override
  _SafeHomeState createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  String locationMessage = 'Current location not fetched';
  String? latitude;
  String? longitude;
  bool isFetchingLocation = false; // Track location fetching state

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled.");
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied.");
        return Future.error('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg: "Location permission permanently denied. Please enable it from settings.",
      );
      return Future.error('Location permission permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
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

    // Prepare the message with the Google Maps link
    String googleMapsLink = "https://www.google.com/maps?q=$latitude,$longitude";
    String message = "I need help! My current location is: $googleMapsLink";

    try {
      // Use the share_plus package to open the share dialog
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(locationMessage, textAlign: TextAlign.center),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isFetchingLocation
                          ? null
                          : () async {
                              setState(() {
                                isFetchingLocation = true;
                              });
                              try {
                                final position = await _getCurrentLocation();
                                setState(() {
                                  latitude = position.latitude.toString();
                                  longitude = position.longitude.toString();
                                  locationMessage =
                                      "Latitude: $latitude, Longitude: $longitude";
                                });
                                Fluttertoast.showToast(
                                    msg: "Location fetched successfully.");
                              } catch (error) {
                                Fluttertoast.showToast(
                                    msg: "Error fetching location: $error");
                              } finally {
                                setState(() {
                                  isFetchingLocation = false;
                                });
                              }
                            },
                      child: isFetchingLocation
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