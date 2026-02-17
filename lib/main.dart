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

import 'package:flutter/material.dart';
import 'package:map_app/child/bottom_page.dart';
import 'package:map_app/login.dart';
import 'package:map_app/services/supabase_service.dart';
// import 'package:firebase_core/firebase_core.dart'; // Commented out Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize(
    url: 'https://bpqyhrougqpkejyxbaaf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwcXlocm91Z3Fwa2VqeXhiYWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzA3MTUsImV4cCI6MjA4NjkwNjcxNX0.Ezyxh_mtp6oPvG1JDvHWzSvQ2IQcPs8YToHYUhcp8FE',
  );

  // await Firebase.initializeApp(...) // Commented out Firebase

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
