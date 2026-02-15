import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


import 'child/child_login_screen.dart';
import 'components/PrimaryButton.dart';
import 'components/SecondaryButton.dart';
import 'components/custom_textfield.dart';
import 'model/user_model.dart';
import 'utils/constans.dart';

class RegisterChildScreen extends StatefulWidget {
  const RegisterChildScreen({super.key});

  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
   bool isPasswordShown = true;
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, Object>{};
  bool isloading=false;
  bool isRetypePasswordShown=true;

  _onSubmit()async
  {
    _formKey.currentState!.save();
    if(_formData['password']!=_formData['rpassword'])
    {
      dialog(context, 'password andretype password should be equeal');
    }
    else
    {
      showLoadingDialog(context);
      try {
         setState(() {
        isloading=true;
      });
  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: _formData['email'].toString(),
    password: _formData['password'].toString()
  );
  if(userCredential.user!=null){
    final v=userCredential.user!.uid;
    DocumentReference<Map<String, dynamic>> db=FirebaseFirestore.instance.collection('users').doc(v);
         final user =UserModel(
          name: _formData['name'].toString(),
          phone: _formData['phone'].toString(),
          childEmail: _formData['email'].toString(),
          parentEmail: _formData['gemail'].toString(),
          id: v,
          type:'child'

         );
         final jsonData=user.toJson();

         await db.set(jsonData).whenComplete((){
           goTo(context,LoginScreen());
            setState(() {
              isloading=false;
      });    

         });
  }
} on FirebaseAuthException catch (e) {
   setState(() {
        isloading=false;
      });
  if (e.code == 'weak-password') {
    print('The password provided is too weak.');
     dialog(context, 'The password provided is too weak.');
  } else if (e.code == 'email-already-in-use') {
    print('The account already exists for that email.');
     dialog(context,'The account already exists for that email.');
  }
} catch (e) {
  print(e);
   setState(() {
        isloading=false;
      });
   dialog(context, e.toString());
}
        

    }
    print(_formData['email']);
    print(_formData['password']);

      }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            isloading
            ? showLoadingDialog(context)
              :SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40),
            
                    Image.asset(
                      'assets/logo.png',
                      height: 80,
                      width: 100,
                    ),
            
                    SizedBox(height: 20),
            
                    Text(
                      "REGISTER AS CHILD",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
            
                    SizedBox(height: 30),
            
            
                    CustomTextfield(
                      hintText: 'Enter name',
                      textInputAction: TextInputAction.next,
                      keyboardtype: TextInputType.name,
                      prefix: Icon(Icons.person),
                      onsave: (name) {
                        _formData['name'] = name ?? '';
                      },
                      validate: (name) {
                        if (name!.isEmpty) {
                          return 'Please enter a valid name';
                        }
                        return null;
                      },
                    ),
            
                    SizedBox(height: 15),
            
                    CustomTextfield(
                      hintText: 'Enter phone number',
                      textInputAction: TextInputAction.next,
                      keyboardtype: TextInputType.phone,
                      prefix: Icon(Icons.phone),
                      onsave: (phone) {
                        _formData['phone'] = phone ?? '';
                      },
                      validate: (phone) {
                        if (phone!.isEmpty || phone.length>10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
            
                    SizedBox(height: 15),
            
            
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
                      hintText: 'Enter guardian email',
                      textInputAction: TextInputAction.next,
                      keyboardtype: TextInputType.emailAddress,
                      prefix: Icon(Icons.person),
                      onsave: (gemail) {
                        _formData['gemail'] = gemail ?? '';
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
                          return 'Please enter a valid password';
                        }
                        return null;
                      },
                    ),
            
                    SizedBox(height: 15),
            
            
                    CustomTextfield(
                      hintText: 'Retype password',
                      isPassword: !isPasswordShown,
                      prefix: Icon(Icons.lock),
                      suffix: IconButton(
                        icon: Icon(
                          isRetypePasswordShown ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isRetypePasswordShown = !isRetypePasswordShown;
                          });
                        },
                      ),
                      onsave: (password) {
                        _formData['rpassword'] = password ?? '';
                      },
                      validate: (password) {
                        if (password!.isEmpty || password.length < 8) {
                          return 'Please enter a valid password';
                        }
                        return null;
                      },
                    ),
            
            
                    SizedBox(height: 20),
            
                    PrimaryButton(
                      title: 'REGISTER',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _onSubmit();
                        }
                      },
                    ),
            
                    SizedBox(height: 20),
            
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text("Forgot Password?", style: TextStyle(fontSize: 16)),
                    //     SecondaryButton(
                    //       title: 'Click here',
                    //       onPressed: () {},
                    //     ),
                    //   ],
                    // ),
            
                    SizedBox(height: 10),
            
                    SecondaryButton(
                      title: 'already have an account?login',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                    ),
            
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
