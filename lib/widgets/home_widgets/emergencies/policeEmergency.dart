import 'package:flutter/material.dart';
// import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';

class policeEmergency extends StatelessWidget {
  //const policeEmergency({super.key});
// _callNumber(String number) async{
   
//     await FlutterPhoneDirectCaller.callNumber(number);
// }
void _callNumber(String number) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: number,
  );
  await launchUrl(launchUri);
}

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 10.0, bottom: 5),
        child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
              20,
            )),
            child:InkWell(

             onTap: () => _callNumber('100'),            
            child: Container(
              height: 180,
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                    Color(0xFFFD8080),
                    Color(0xFFFB8580),
                    Color(0xFFFBD079),
                  ])),

          child:Padding(
                    padding: const EdgeInsets.only(left: 10.0, bottom: 5),

              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    child: Image.asset('assets/alert.png'),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,


                      children: [
                        Text(
                          'Police Emergency',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.06,
                          ),
                          
                        ),


                        Text(
                          'call 1-0-0 for emergency ',
                          style: TextStyle(
                            color: Colors.white,
                            // overflow: TextOverflow.ellipsis,
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                          ),
                        ),



                        Container(
                          height: 30,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),

                          ),

                          child:Center(

                          
                          child: Text(
                            '0-1-5',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontWeight: FontWeight.bold,

                              // overflow: TextOverflow.ellipsis,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.055,
                            ),
                          ),
                          )
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
          )
        )
      )
    );
  }
}
