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

  final initialRouteWidget = SupabaseService.client.auth.currentUser == null
      ? const LoginScreen()
      : const BottomPage();

  runApp(MyApp(initialRouteWidget: initialRouteWidget));
}

class MyApp extends StatelessWidget {
  final Widget initialRouteWidget;

  const MyApp({super.key, required this.initialRouteWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialRouteWidget,
    );
  }
}
