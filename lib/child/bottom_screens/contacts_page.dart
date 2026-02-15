import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../db/db_services.dart';
import '../../model/contactsm.dart';
import '../../utils/constans.dart';
/*
class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  void _saveContact() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final contact = {
          'name': _nameController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'relation': _relationController.text.trim(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('contacts')
            .add(contact);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency contact added successfully!'),
            backgroundColor: Colors.pinkAccent,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Emergency Contact'),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a mobile number';
                  } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _relationController,
                decoration: const InputDecoration(
                  labelText: 'Relation',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a relation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/





/* *********************************************************************************************  */
class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];
  List<Contact> contactsfilter = [];
  DatabaseHelper _databaseHelper=DatabaseHelper();
TextEditingController searchcontroller=TextEditingController();
  @override
  void initState() {
    super.initState();
    askPermissions();
  }

  String flattenPhoneNumber(String phonestr){
    return phonestr.replaceAllMapped(RegExp(r'^(\+)|\D'),(Match m){
      return m[0]=="+"?"+":"";
    });
    
  }
  filtercontact(){
  List<Contact> _contacts = [];
  _contacts.addAll(contacts);
  if(searchcontroller.text.isNotEmpty){
      _contacts.retainWhere((element){ 
    String searchTerm=searchcontroller.text.toLowerCase();
    String searchTermFlatteren =flattenPhoneNumber(searchTerm);
    String contactname=element.displayName.toLowerCase();
   bool namematch =contactname.contains(searchTerm);
   if(namematch==true){
        return true;
   }
   if(searchTermFlatteren.isEmpty){
    return false;
   }
   var phone=element.phones!.firstWhere((p){
    String phnFlattered=flattenPhoneNumber(p.number!);
    return phnFlattered.contains(searchTermFlatteren);
   });
   return phone.number!=null;

      });
  }
    setState(() {
      contactsfilter=_contacts;
    });
  } 

  Future<void> askPermissions() async {
    PermissionStatus permissionStatus = await getContactsPermission();
    if (permissionStatus == PermissionStatus.granted) {
      getAllContacts();
      searchcontroller.addListener((){
        filtercontact();
      });
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  void handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      dialog(context, "Access to the contacts was denied by the user.");
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      dialog(context, "Contacts access is permanently denied on this device.");
    }
  }

  Future<PermissionStatus> getContactsPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  getAllContacts() async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> _Contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: true);
      setState(() {
        contacts = _Contacts;
      });
      debugPrint("Contacts loaded: ${contacts.length}");
    } else {
      debugPrint("Permission denied or failed.");
    }
  }

  // Create initials from the name
  String getInitials(Contact contact) {
  if (contact.displayName != null && contact.displayName!.isNotEmpty) {
    List<String> names = contact.displayName!.split(' ');

    // Ensure names list has at least one element before accessing it
    if (names.isNotEmpty) {
      String initials = names[0][0];  // First letter of the first name
      if (names.length > 1 && names[1].isNotEmpty) {
        initials += names[1][0];  // First letter of the second name (if available)
      }
      return initials.toUpperCase();
    }
  }
  return '';  // Default initials when name is null or empty
}


  @override
  Widget build(BuildContext context) {
    bool issearchIng =searchcontroller.text.isNotEmpty;
    bool listItemExit=(contactsfilter.length>0 || contacts.length>0);
    return Scaffold(
      body: contacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchcontroller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "search contact",
                      prefixIcon: Icon(Icons.search)
                      )
                    ),
                ),
                listItemExit==true?

                 Expanded(
                   child: ListView.builder(

                      itemCount: issearchIng==true?contactsfilter.length:contacts.length,
                      itemBuilder: (BuildContext context, int index) {
                        Contact contact = issearchIng==true?contactsfilter[index]: contacts[index];
                                 
                        // Safely access the displayName, use a fallback value if it's null
                        String displayName = contact.displayName ?? 'No Name';
                                 
                        // Safely check if the photo exists and is not empty
                        Widget avatar = (contact.photo != null && contact.photo!.isNotEmpty)
                            ? CircleAvatar(
                                backgroundColor: primaryColor,
                                backgroundImage: MemoryImage(contact.photo!),
                              )
                            : CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Text(getInitials(contact)),
                              );
                                 
                        // Safely handle phone numbers (check if phones is non-null and has entries)
                        String phoneNumber = 'No phone number';
                        if (contact.phones != null && contact.phones!.isNotEmpty) {
                          phoneNumber = contact.phones!.first.number ?? 'No phone number';
                        }
                                 
                        debugPrint("Contact: ${contact.displayName}, Phone: $phoneNumber");
                                 
                        return ListTile(
                          title: Text(displayName),
                          subtitle: Text(phoneNumber),
                          leading: avatar, // Safely use the avatar
                        
                        onTap: (){
                          if(contact.phones!.length>0){
                                  final String phoneNum=contact.phones!.elementAt(0).number;
                                  final String name=contact.displayName!;
                                  _addcontact(TContact(phoneNum, name));
                            }
                          else{
                          Fluttertoast.showToast(msg: "OOPS! phone number of this contact does not exits");
                        }
                        },
                        );
                      },
                    ),
                 )
                 :Container(child: Text("searching"),),
              ],
            ),
          ),
    );
  }

  /*void _addcontact(TContact newContact)async{
       int? result= await _databaseHelper.insertContact(newContact);
       if(result!=0){
        Fluttertoast.showToast(msg: "contact added successfully");

       }
       else{
        Fluttertoast.showToast(msg: "failed to add contact");
       }
       Navigator.of(context).pop(true);

  }*/

 // import 'package:firebase_auth/firebase_auth.dart';

void _addcontact(TContact newContact) async {
  // Save to SQLite
  int? result = await _databaseHelper.insertContact(newContact);

  if (result != null && result > 0) {
    Fluttertoast.showToast(msg: "Contact added locally successfully");

    // Get the current user's UID
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        // Save to Firestore under the current user's document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('contacts')
            .add({
          'name': newContact.name,
          'number': newContact.number,
          'timestamp': FieldValue.serverTimestamp(),
        });

        Fluttertoast.showToast(msg: "Contact added to Firebase successfully");
      } catch (error) {
        Fluttertoast.showToast(msg: "Failed to add contact to Firebase: $error");
      }
    } else {
      Fluttertoast.showToast(msg: "No user is logged in. Unable to save to Firebase.");
    }
  } else {
    Fluttertoast.showToast(msg: "Failed to add contact locally");
  }

  Navigator.of(context).pop(true);
}

}


/* ********************************************************************************************************************************************* */



/*
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPage extends StatefulWidget {
  final String userId; // Pass the logged-in user's ID
  const ContactsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> deviceContacts = [];
  List<Contact> filteredContacts = [];
  TextEditingController searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    askPermissions();
    searchController.addListener(() {
      filterContacts();
    });
  }

  Future<void> askPermissions() async {
    PermissionStatus permissionStatus = await getContactsPermission();
    if (permissionStatus == PermissionStatus.granted) {
      getAllContacts();
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> getContactsPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  void handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      Fluttertoast.showToast(msg: "Access to the contacts was denied.");
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      Fluttertoast.showToast(msg: "Contacts access is permanently denied.");
    }
  }

  void filterContacts() {
    List<Contact> _contacts = [];
    _contacts.addAll(deviceContacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((element) {
        String searchTerm = searchController.text.toLowerCase();
        String contactName = element.displayName.toLowerCase();
        return contactName.contains(searchTerm);
      });
    }
    setState(() {
      filteredContacts = _contacts;
    });
  }

  Future<void> getAllContacts() async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> contacts = await FlutterContacts.getContacts();
      setState(() {
        deviceContacts = contacts;
      });
    }
  }

  Future<void> addContactToFirebase(String name, String number) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('contacts')
          .add({'name': name, 'number': number});
      Fluttertoast.showToast(msg: "Contact added to Firebase.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to add contact: $e");
    }
  }

  Future<void> deleteContactFromFirebase(String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('contacts')
          .doc(contactId)
          .delete();
      Fluttertoast.showToast(msg: "Contact deleted from Firebase.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to delete contact: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Contacts")),
      body: deviceContacts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Search Contacts",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: isSearching
                          ? filteredContacts.length
                          : deviceContacts.length,
                      itemBuilder: (context, index) {
                        Contact contact = isSearching
                            ? filteredContacts[index]
                            : deviceContacts[index];
                        String displayName = contact.displayName;
                        String phoneNumber = contact.phones.isNotEmpty
                            ? contact.phones.first.number
                            : 'No phone number';

                        return ListTile(
                          title: Text(displayName),
                          subtitle: Text(phoneNumber),
                          leading: CircleAvatar(
                            child: Text(
                              displayName[0].toUpperCase(),
                            ),
                          ),
                          onTap: () {
                            addContactToFirebase(displayName, phoneNumber);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              // Find the contact id from Firebase to delete it
                              final querySnapshot = await _firestore
                                  .collection('users')
                                  .doc(widget.userId)
                                  .collection('contacts')
                                  .where('name', isEqualTo: displayName)
                                  .where('number', isEqualTo: phoneNumber)
                                  .get();

                              if (querySnapshot.docs.isNotEmpty) {
                                String contactId = querySnapshot.docs.first.id;
                                await deleteContactFromFirebase(contactId);
                              }
                            },
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
}*/


