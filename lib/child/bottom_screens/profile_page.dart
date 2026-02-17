
import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart'; 
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:map_app/services/supabase_service.dart';

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
  // Fetch user data from Supabase
  getname() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    
    final profile = await SupabaseService.getProfile(user.id);
    if (profile != null) {
        nameC.text = profile['full_name'] ?? "";
        emailC.text = profile['child_email'] ?? ""; // prioritize child email if that's what we want
        phoneC.text = profile['phone'] ?? "";
        id = profile['id'];
        profilepic = profile['avatar_url']; // Assuming we mapped it this way
    }
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
       try {
         // Pass null to profilePic to remove it (assuming updateProfile handles it, 
         // or we might need to pass other fields too if we don't want to wipe them 
         // or if updateProfile is partial).
         // My updateProfile implementation above uses 'updates' map.
         // If I call it with other fields as null, it might wipe them or be ignored.
         // Let's reuse SupabaseService.updateProfile but pass current controller values for other fields.
         
         await SupabaseService.updateProfile(
             name: nameC.text,
             childEmail: emailC.text,
             phone: phoneC.text,
             parentEmail: null,
             profilePic: null
         );
         
         Fluttertoast.showToast(msg: 'Image deleted successfully');
       } catch (e) {
          Fluttertoast.showToast(msg: 'Failed to delete image: $e');
       }
    }
  }

  // Logout function
  Future<void> logout() async {
    await SupabaseService.signOut();
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
                        try {
                          await SupabaseService.updateProfile(
                              name: nameC.text,
                              childEmail: emailC.text,
                              // parentEmail: parentC.text, // commented out in UI too
                              parentEmail: null,
                              phone: phoneC.text,
                              profilePic: profilepic,
                          );
                          Fluttertoast.showToast(msg: 'Profile updated successfully');
                        } catch (e) {
                          Fluttertoast.showToast(msg: 'Failed to update profile: $e');
                        }
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

