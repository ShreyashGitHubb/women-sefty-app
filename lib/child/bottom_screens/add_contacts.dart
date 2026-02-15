
 
import 'package:flutter/material.dart';
//import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../components/PrimaryButton.dart';
import '../../db/db_services.dart';
import '../../model/contactsm.dart';
import 'contacts_page.dart'; // Add permission_handler

class AddContacts extends StatefulWidget {
  const AddContacts({Key? key}) : super(key: key);

  @override
  State<AddContacts> createState() => _AddContactsState();
}

class _AddContactsState extends State<AddContacts> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<TContact>? contactlist = [];
  int count = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      showList();
    });
  }

  void showList() {
    databaseHelper.initializeDatabase().then((_) {
      databaseHelper.getContactList().then((contactList) {
        setState(() {
          this.contactlist = contactList;
          this.count = contactList.length;
        });
      });
    });
  }

  
   




  // Method to make phone calls using url_launcher
  // Future<void> _makePhoneCall(String number) async {
  //   final Uri phoneUri = Uri(scheme: 'tel', path: number);
  //   try {
  //     // Request permission before making the call
  //     PermissionStatus status = await Permission.phone.request();
  //     if (status.isGranted) {
  //       // Attempt to make the phone call
  //       if (await canLaunch(phoneUri.toString())) {
  //         await launch(phoneUri.toString());
  //       } else {
  //         Fluttertoast.showToast(msg: "Could not place call. Please check the number.");
  //       }
  //     } else {
  //       Fluttertoast.showToast(msg: "Permission denied. Cannot make a call.");
  //     }
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: "Error: ${e.toString()}");
  //   }
  // }

  Future<void> _makePhoneCall(String number) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: number);
  
  try {
    // Request phone call permission
    PermissionStatus status = await Permission.phone.request();

    if (status.isGranted) {
      // Directly launch the phone call
      bool launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      
      if (!launched) {
        // If the launch fails, display a Toast with an error message
        Fluttertoast.showToast(msg: "Could not place call. Please check the number format or permissions.");
      }
    } else {
      // Permission was denied
      Fluttertoast.showToast(msg: "Permission denied. Cannot make a call.");
    }
  } catch (e) {
    // Handle any errors that may occur
    Fluttertoast.showToast(msg: "Error: ${e.toString()}");
  }
}


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            PrimaryButton(
              title: "Add Emergency Contacts",
              onPressed: () async {
                bool result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactsPage()),
                );
                if (result == true) {
                  showList();
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: count,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(contactlist![index].name),
                        trailing: Container(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  // Debugging: Check the phone number format
                                  print('Making a call to: ${contactlist![index].number}');
                                  await _makePhoneCall(contactlist![index].number);
                                },
                                icon: Icon(
                                  Icons.call,
                                  color: Colors.green,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  deleteContact(contactlist![index]);
                                },
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  void deleteContact(TContact contact) async {
    int? result = await databaseHelper.deleteContact(contact.id);
    if (result != 0) {
      Fluttertoast.showToast(msg: "Contact removed successfully");
      showList();
    }
  }
}



/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:women/child/bottom_screens/contacts_page.dart';
//import 'add_contact.dart';

class AddContacts extends StatefulWidget {
  const AddContacts({Key? key}) : super(key: key);

  @override
  State<AddContacts> createState() => _AddContactsState();
}

class _AddContactsState extends State<AddContacts> {
  Stream<List<Map<String, dynamic>>> _getContactsStream() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'],
                'mobileNumber': data['mobileNumber'],
                'relation': data['relation'],
              };
            }).toList());
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);

    try {
      PermissionStatus status = await Permission.phone.request();

      if (status.isGranted) {
        bool launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);

        if (!launched) {
          Fluttertoast.showToast(
              msg: "Could not place call. Please check the number format or permissions.");
        }
      } else {
        Fluttertoast.showToast(msg: "Permission denied. Cannot make a call.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  Future<void> _deleteContact(String contactId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId)
        .delete();
    Fluttertoast.showToast(msg: "Contact removed successfully");
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactsPage(),
                    //MaterialPageRoute(builder: (context) => const ContactsPage(userId: 'userId: FirebaseAuth.instance.currentUser!.uid'),

                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                ),
                child: const Text("Add Emergency Contacts"),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getContactsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final contacts = snapshot.data!;
                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return Card(
                          color: Colors.pink.shade50,
                          child: ListTile(
                            title: Text(contact['name']),
                            subtitle: Text(
                                "${contact['relation']} - ${contact['mobileNumber']}"),
                            trailing: SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      await _makePhoneCall(
                                          contact['mobileNumber']);
                                    },
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.pink,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await _deleteContact(contact['id']);
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
}*/

