// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'child/bottom_page.dart';
// import 'db/shared_pref.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await MySharedPreference.init();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Rakshak',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         textTheme: GoogleFonts.firaSansTextTheme(Theme.of(context).textTheme),
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: const BottomPage(),
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:map_app/child/bottom_page.dart';
import 'package:map_app/login.dart';
import 'package:map_app/sign_up.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBGLX2-DvjRAHrmwH0hcZ97f35D9K7_aWw",
      appId: "1:82815931514:android:d0f1202f8b54369edf57c3",
      messagingSenderId: "82815931514",
      projectId: "women-7b8aa",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BottomPage(),
    );
  }
}
