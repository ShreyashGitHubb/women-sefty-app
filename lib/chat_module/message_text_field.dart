import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:uuid/uuid.dart';

class MessageTextField extends StatefulWidget {
  final String currentId;
  final String friendId;

  const MessageTextField({super.key, required this.currentId, required this.friendId});

  @override
  State<MessageTextField> createState() => _MessageTextFieldState();
}

class _MessageTextFieldState extends State<MessageTextField> {
  Position? _currentPosition;
  String? _currentAddress;
  File? imageFile;
  TextEditingController _controller = TextEditingController();

  Future<bool> _isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  Future<bool> _isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  // Function to pick image (no Firebase Storage involved here)
  Future<void> getImage() async {
    // Check if camera permission is granted
    bool cameraPermissionGranted = await _isCameraPermissionGranted();
    if (!cameraPermissionGranted) {
      Fluttertoast.showToast(msg: "Camera permission denied");
      return;
    }

    ImagePicker _picker = ImagePicker();
    XFile? xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() {
        imageFile = File(xFile.path);
      });
    }
  }

  // This function sends the message to Firestore
  Future<void> sendMessage(String content, String type) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentId)
          .collection('messages')
          .doc(widget.friendId)
          .collection('chats')
          .add({
        'senderId': widget.currentId,
        'receiverId': widget.friendId,
        'message': content,
        'type': type,
        'date': DateTime.now(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendId)
          .collection('messages')
          .doc(widget.currentId)
          .collection('chats')
          .add({
        'senderId': widget.currentId,
        'receiverId': widget.friendId,
        'message': content,
        'type': type,
        'date': DateTime.now(),
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to send message: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!await _isLocationPermissionGranted()) {
      Fluttertoast.showToast(msg: "Location permission denied");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;
      await _getAddressFromLatLon();

      if (_currentPosition != null && _currentAddress != null) {
        String locationUrl =
            "https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}";
        String fullMessage = "$locationUrl ($_currentAddress)";
        await sendMessage(fullMessage, "link");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to get location: $e");
    }
  }

  Future<void> _getAddressFromLatLon() async {
    try {
      if (_currentPosition != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _currentAddress = "${place.street}, ${place.locality}, ${place.country}";
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to get address: $e");
    }
  }

  Widget bottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      child: Card(
        margin: EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            chatIcon(Icons.location_pin, "Location", _getCurrentLocation),
            chatIcon(Icons.camera_alt, "Camera", () {
              // Request camera permission before allowing camera use
              getImage();
            }),
            chatIcon(Icons.insert_photo, "Image", () async {
              // Open gallery for picking image
              getImage();
            }),
          ],
        ),
      ),
    );
  }

  Widget chatIcon(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 30, backgroundColor: Colors.pink, child: Icon(icon)),
          Text(title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                cursorColor: Colors.pink,
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type your message',
                  fillColor: Colors.grey[100],
                  filled: true,
                  prefixIcon: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) => bottomSheet(),
                      );
                    },
                    icon: Icon(Icons.add_box_rounded, color: Colors.pink),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                String message = _controller.text.trim();
                if (message.isNotEmpty) {
                  await sendMessage(message, "text");
                  _controller.clear();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.send, color: Colors.pink, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
