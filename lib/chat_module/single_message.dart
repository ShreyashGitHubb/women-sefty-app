import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SingleMessage extends StatelessWidget {
  final String? message;
  final bool? isme;
  final String? image;
  final String? type;
  final Timestamp?  date;
  final String? myName;
  final String? friendName;
  const SingleMessage({super.key, this.message, this.isme, this.image, this.type, this.date, this.myName, this.friendName});

  @override
  Widget build(BuildContext context) {
    final size=MediaQuery.of(context).size;
    DateTime d=DateTime.parse(date!.toDate().toString());
    String cDate="${d.hour}" + ":"+"${d.minute}";
    
    return type=="text"?
     Container(
      constraints: BoxConstraints(
        maxWidth: size.width/2,

      ),
      alignment: isme! ? Alignment.centerRight:Alignment.centerLeft,
      padding: EdgeInsets.all(10),
      
      
      child: Container(
        
        decoration: BoxDecoration(
          color: isme! ?Colors.pink:Colors.black,
        borderRadius: isme! ?
         BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomLeft: Radius.circular(15),
          )
          :BorderRadius.only(
            topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
          ),
        
      ),
         padding: EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxWidth: size.width/2,
        ),
        alignment: isme !? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          children: [
             Align(
              alignment: Alignment.centerRight,
                child: Text(isme! ?myName!:friendName!,
                style: TextStyle(fontSize: 15,color: Colors.white70),
                )
                ),
            
            Align(
              alignment: Alignment.centerRight,
                child: Text(message!,
                style: TextStyle(fontSize: 18,color: Colors.white),
                )
                ),
                
            Align(
              alignment: Alignment.centerRight,
                child: Text(
                  "$cDate",
                style: TextStyle(fontSize: 15,color: Colors.white70),
                )
                )
          ],
        )
            ),
    ): Container(
      constraints: BoxConstraints(
        maxWidth: size.width/2,

      ),
      alignment: isme! ? Alignment.centerRight:Alignment.centerLeft,
      padding: EdgeInsets.all(10),
      
      
      child: Container(
        
        decoration: BoxDecoration(
          color: isme! ?Colors.pink:Colors.black,
        borderRadius: isme! ?
         BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomLeft: Radius.circular(15),
          )
          :BorderRadius.only(
            topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
          ),
          
        
      ),
         padding: EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxWidth: size.width/2,
        ),
        alignment: isme !? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          children: [
             Align(
              alignment: Alignment.centerRight,
                child: Text(isme! ?myName!:friendName!,
                style: TextStyle(fontSize: 15,color: Colors.white70),
                )
                ),
            
            Align(
              alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async{
                    await launchUrl(Uri.parse("$message"));
                  },
                  child: Text(message!,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,color: Colors.white),
                  ),
                )
                ),
                
            Align(
              alignment: Alignment.centerRight,
                child: Text(
                  "$cDate",
                style: TextStyle(fontSize: 15,color: Colors.white70),
                )
                )
          ],
        )
            ),
    );
  
  
  
  }
}