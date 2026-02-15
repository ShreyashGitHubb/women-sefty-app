// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:map_app/child/bottom_page.dart';
// import 'package:map_app/forgot.dart';

// import 'sign_up.dart';

// class UserData {
//   final String? id;
//   final String name;
//   final String email;

//   UserData({required this.id, required this.name, required this.email});

//   Map<String, dynamic> toJson() {
//     return {'id': id, 'name': name, 'email': email};
//   }
// }

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late String _email;
//   late String _password;
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _obscureText = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _login() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         UserCredential userCredential = await FirebaseAuth.instance
//             .signInWithEmailAndPassword(
//               email: _emailController.text.trim(),
//               password: _passwordController.text,
//             );
//         // Navigate to GetStarted screen upon successful login
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => BottomPage()),
//         );
//       } on FirebaseAuthException catch (e) {
//         if (e.code == 'user-not-found') {
//           // Handle user not found error
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('Login Error'),
//                 content: const Text('No user found for that email.'),
//                 actions: <Widget>[
//                   TextButton(
//                     child: const Text('OK'),
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                 ],
//               );
//             },
//           );
//         } else if (e.code == 'wrong-password') {
//           // Handle wrong password error
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('Login Error'),
//                 content: const Text('Wrong password provided for that user.'),
//                 actions: <Widget>[
//                   TextButton(
//                     child: const Text('OK'),
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                 ],
//               );
//             },
//           );
//         } else {
//           // Handle other exceptions
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('Login Error'),
//                 content: const Text(
//                   'An error occurred. Please try again later.',
//                 ),
//                 actions: <Widget>[
//                   TextButton(
//                     child: const Text('OK'),
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                 ],
//               );
//             },
//           );
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: //isloading! ? center(loader) :
//           Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/bown_login.png'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           Center(
//             child: Container(
//               height: 450,
//               width: 330,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black87,
//                     offset: Offset(0, 4),
//                     blurRadius: 10,
//                   ),
//                 ],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(40),
//                         child: const Image(
//                           height: 124,
//                           width: 150,
//                           image: AssetImage('assets/new_photo.avif'),
//                         ),
//                       ),
//                       const SizedBox(height: 1),
//                       TextFormField(
//                         controller: _emailController,
//                         decoration: InputDecoration(
//                           hintText: 'Email',
//                           filled: true,
//                           fillColor: const Color.fromARGB(255, 224, 199, 187),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value!.isEmpty || !value.contains('@')) {
//                             return 'Enter a valid email address';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) {
//                           _email = value!;
//                         },
//                       ),
//                       const SizedBox(height: 10),
//                       TextFormField(
//                         controller: _passwordController,
//                         decoration: InputDecoration(
//                           hintText: 'Password',
//                           filled: true,
//                           fillColor: const Color.fromARGB(255, 224, 199, 187),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           suffixIcon: GestureDetector(
//                             onTap: () {
//                               setState(() {
//                                 _obscureText = !_obscureText;
//                               });
//                             },
//                             child: Icon(
//                               _obscureText
//                                   ? Icons.visibility_off
//                                   : Icons.visibility,
//                               color: Colors.brown,
//                             ),
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value!.isEmpty || value.length < 6) {
//                             return 'Password must be at least 6 characters long';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) {
//                           _password = value!;
//                         },
//                         obscureText: _obscureText,
//                       ),
//                       const SizedBox(height: 10),
//                       ElevatedButton(
//                         onPressed: _login,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.brown,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 40,
//                             vertical: 15,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         child: const Text(
//                           'Login',
//                           style: TextStyle(fontSize: 18, color: Colors.white),
//                         ),
//                       ),
//                       const SizedBox(height: 1),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           TextButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const ForgotPassword(),
//                                 ),
//                               );
//                             },
//                             child: const Text(
//                               'Forgot Password',
//                               style: TextStyle(color: Colors.brown),
//                             ),
//                           ),
//                           const Text(
//                             '|',
//                             style: TextStyle(color: Colors.brown),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const Signup(),
//                                 ),
//                               );
//                             },
//                             child: const Text(
//                               'Sign Up',
//                               style: TextStyle(color: Colors.brown),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
