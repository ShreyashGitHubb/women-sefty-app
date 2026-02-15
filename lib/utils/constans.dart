import 'package:flutter/material.dart';

Color primaryColor=Color(0xfffc3b77,);

void goTo(BuildContext context,Widget nextScreen)
{
  Navigator.push(context, MaterialPageRoute(builder: (context)=>nextScreen,));

}

Widget showLoadingDialog(BuildContext context){
   return Center(child: CircularProgressIndicator(
        backgroundColor: primaryColor,
        color: Colors.red,
        strokeWidth: 7,
      ));
}

// void dialog(BuildContext context,String text)
// {
//     showDialog(
//       context: context, 
//       builder:(context)=>AlertDialog(
//         title: Text(text),
//       ),
//    );

// }

void dialog(BuildContext context, String text) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(text),
    ),
  );
}
