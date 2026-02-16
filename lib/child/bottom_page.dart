import 'package:flutter/material.dart';
import '../utils/shake_handler.dart';
import '../services/voice_service.dart';
import 'bottom_screens/voice_settings_screen.dart';

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
      VoiceService.initialize();
      VoiceService.startListening(context);
    });
  }
  
  @override
  void dispose() {
    // Clean up shake detector
    ShakeHandler.dispose();
    VoiceService.stopListening();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VoiceSettingsScreen()),
          );
        },
        backgroundColor: Colors.pink,
        child: Icon(Icons.record_voice_over),
        heroTag: "voice_settings_btn",
      ),
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
