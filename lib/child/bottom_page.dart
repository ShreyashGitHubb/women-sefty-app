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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize shake detector for emergency help
      ShakeHandler.initialize(context);
      // Initialize voice service (but DO NOT start listening yet)
      await VoiceService.initialize();
      // Start listening only if we're on the home tab
      if (currentIndex == 0) {
        VoiceService.startListening(context);
      }
    });
  }

  @override
  void dispose() {
    ShakeHandler.dispose();
    VoiceService.stopListening(); // Always stop mic when leaving the app
    super.dispose();
  }

  void onTapped(int index) {
    if (index == currentIndex) return; // No change, do nothing

    setState(() {
      currentIndex = index;
    });

    // Control mic based on which tab we're on
    if (index == 0) {
      // Arriving at Home tab — start listening
      VoiceService.startListening(context);
    } else {
      // Leaving Home tab — stop listening so mic doesn't block other audio
      VoiceService.stopListening();
    }
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
