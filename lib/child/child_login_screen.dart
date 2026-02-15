import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin_panel/admin_register.dart';
import '../admin_panel/main_screen.dart';
import '../components/PrimaryButton.dart';
import '../components/SecondaryButton.dart';
import '../components/custom_textfield.dart';
import '../db/shared_pref.dart';
import '../parent/parent_home_screen.dart';
import '../parent/parent_register.dart';
import '../utils/constans.dart';
import 'bottom_page.dart';
import 'register_child.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordShown = true;
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, Object>{};
  bool isloading=false;
  _onSubmit() async
  {
    _formKey.currentState!.save();
    try {
      setState(() {
        isloading=true;
      });
  UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: _formData['email'].toString(),
    password: _formData['password'].toString(),
   );
  if(userCredential.user !=null)
  { setState(() {
        isloading=false;
      });
      FirebaseFirestore.instance.collection('users')
      .doc(userCredential.user!.uid)
      .get()
      .then((value){
        if(value['type']=='parent'){
          
          print(value['type']);
          MySharedPreference.saveUserType('parent');
          
          goTo(context, ParentHomeScreen());
        }
        else if(value['type']=='child'){
          MySharedPreference.saveUserType('child');
          goTo(context, BottomPage());
         }
         else
         {
          print(value['type']=='admin');
          MySharedPreference.saveUserType('admin');
          
         goTo(context, MainDashboard());
         }
        
      });
 }  
} on FirebaseAuthException catch (e) {
   setState(() {
        isloading=false;
      });
  if (e.code == 'user-not-found') {
    dialog(context,'No user found for that email.');
    print('No user found for that email.');
  } else if (e.code == 'wrong-password') {
    dialog(context, 'Wrong password provided for that user.');
    print('Wrong password provided for that user.');
  }
}
    print(_formData['email']);
    print(_formData['password']);

      }
   @override
  Widget build(BuildContext context) {
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Stack(
                      children: [
                        if (isloading)
                          Center(child: CircularProgressIndicator()) // Display loading indicator when loading
                        else
                          Column(
                            mainAxisAlignment: isKeyboardOpen
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              SizedBox(height: isKeyboardOpen ? 20 : 0),
                              Image.asset(
                                'assets/logo.png',
                                height: 80,
                                width: 100,
                              ),
                              SizedBox(height: isKeyboardOpen ? 10 : 20),
                              Text(
                                "USER LOGIN",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 30),
                              CustomTextfield(
                                hintText: 'Enter email',
                                textInputAction: TextInputAction.next,
                                keyboardtype: TextInputType.emailAddress,
                                prefix: Icon(Icons.person),
                                onsave: (email) {
                                  _formData['email'] = email ?? '';
                                },
                                validate: (email) {
                                  if (email!.isEmpty || email.length < 3 || !email.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 15),
                              CustomTextfield(
                                hintText: 'Enter password',
                                isPassword: !isPasswordShown,
                                prefix: Icon(Icons.lock),
                                suffix: IconButton(
                                  icon: Icon(
                                    isPasswordShown ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isPasswordShown = !isPasswordShown;
                                    });
                                  },
                                ),
                                onsave: (password) {
                                  _formData['password'] = password ?? '';
                                },
                                validate: (password) {
                                  if (password!.isEmpty || password.length < 8) {
                                    return 'Please enter a password with at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              PrimaryButton(
                                title: 'Login',
                                onPressed: _onSubmit,
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Forgot Password?",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SecondaryButton(
                                    title: 'click here',
                                    onPressed: () {
                                      // Forgot password logic
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              SecondaryButton(
                                title: 'register as child',
                                onPressed: () {
                                  goTo(context, RegisterChildScreen());
                                },
                              ),
                              SecondaryButton(
                                title: 'register as admin',
                                onPressed: () {
                                  goTo(context, registerAdmin());
                                },
                              ),
                              SecondaryButton(
                                title: 'register as parent',
                                onPressed: () {
                                  goTo(context, ParentRegister());
                                },
                              ),
                              SizedBox(height: 20),
                            ],
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
    );
  }
}