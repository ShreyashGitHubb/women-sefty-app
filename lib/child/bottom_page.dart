import 'package:flutter/material.dart';
import '../utils/shake_handler.dart';

import 'bottom_screens/addContact_fire.dart';
import 'bottom_screens/chat_page.dart';
import 'bottom_screens/child_home_page.dart';
import 'bottom_screens/profile_view.dart';
import 'bottom_screens/review_page.dart';

class BottomPage extends StatefulWidget {
  const BottomPage({super.key});

  @override
  State<BottomPage> createState() => _BottomPageState();
}

class _BottomPageState extends State<BottomPage> {
  int currentIndex = 0;
  List<Widget> pages = [
    HomeScreen(),
    AddContactLocal(),
    QuickHelpActions(),
    ProfileViewPage(),
    ReviewPageLocal(),
  ];
  
  @override
  void initState() {
    super.initState();
    // Initialize shake detector for emergency help
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShakeHandler.initialize(context);
    });
  }
  
  @override
  void dispose() {
    // Clean up shake detector
    ShakeHandler.dispose();
    super.dispose();
  }
  
  onTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: onTapped,
        items: [
          BottomNavigationBarItem(label: 'home', icon: Icon(Icons.home)),
          BottomNavigationBarItem(
            label: 'contacts',
            icon: Icon(Icons.contacts),
          ),
          BottomNavigationBarItem(label: 'Quick help', icon: Icon(Icons.chat)),

          BottomNavigationBarItem(label: 'profile', icon: Icon(Icons.person)),
          BottomNavigationBarItem(label: 'Review', icon: Icon(Icons.reviews)),
        ],
      ),
    );
  }
}
