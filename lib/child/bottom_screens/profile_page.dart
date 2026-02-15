
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../components/PrimaryButton.dart';
import '../../components/custom_textfield.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameC = TextEditingController();
  TextEditingController emailC = TextEditingController();
  TextEditingController phoneC = TextEditingController();
  TextEditingController parentC = TextEditingController();

  final key = GlobalKey<FormState>();

  String? id;
  String? profilepic;

  // Fetch user data from Firestore
  getname() async {
    await FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      nameC.text = value.docs.first['name'];
      emailC.text=value.docs.first['childEmail'];
      phoneC.text=value.docs.first['phone'];
     // parentC.text=value.docs.first['parentEmail'];
      id = value.docs.first.id;
      profilepic = value.docs.first['profilepic'];
    });
    setState(() {});
  }

  // Select an image from the local drive
  Future<void> selectImageFromDrive() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        profilepic = result.files.single.path;
      });
    } else {
      Fluttertoast.showToast(msg: 'No image selected');
    }
  }

  // Delete the selected image
  Future<void> deleteImage() async {
    setState(() {
      profilepic = null;
    });

    if (id != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update({'profilepic': null}).then((value) {
        Fluttertoast.showToast(msg: 'Image deleted successfully');
      }).catchError((e) {
        Fluttertoast.showToast(msg: 'Failed to delete image: $e');
      });
    }
  }

  // Logout function
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(msg: 'Logged out successfully');
    Navigator.of(context).pop(); // Redirect to login page or initial screen
  }

  @override
  void initState() {
    super.initState();
    getname();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text(
          "Profile",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
       // centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Update Your Profile",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: selectImageFromDrive,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.pink[100],
                      backgroundImage:
                          profilepic != null ? FileImage(File(profilepic!)) : null,
                      child: profilepic == null
                          ? Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.pinkAccent,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  profilepic != null
                      ? TextButton(
                          onPressed: deleteImage,
                          child: const Text(
                            "Remove Image",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : Container(),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: nameC,
                    hintText: "Enter your name",
                    validate: (v) {
                      if (v!.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                   CustomTextfield(
                    controller: emailC,
                    hintText: "Enter your email",
                    validate: (v) {
                      if (v!.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  //  CustomTextfield(
                  //   controller: parentC,
                  //   hintText: "Enter your parent email",
                  //   validate: (v) {
                  //     if (v!.isEmpty) {
                  //       return 'Please enter your parent email';
                  //     }
                  //     return null;
                  //   },
                 // ),
                  const SizedBox(height: 20),

                   CustomTextfield(
                    controller: phoneC,
                    hintText: "Enter your phone number",
                    validate: (v) {
                      if (v!.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    title: "Update Profile",
                    onPressed: () async {
                      if (key.currentState!.validate()) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(id)
                            .update({

                              'name': nameC.text,
                              'childEmail':emailC.text,
                          //    'parentEmail':parentC.text,
                              'phone':phoneC.text,
                              'profilepic': profilepic,
                            })
                            .then((value) => Fluttertoast.showToast(
                                msg: 'Profile updated successfully'))
                            .catchError((e) {
                          Fluttertoast.showToast(
                              msg: 'Failed to update profile: $e');
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

