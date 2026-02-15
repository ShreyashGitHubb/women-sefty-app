import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_widgets/live_safe/BusStationCard.dart';
import 'home_widgets/live_safe/HospitalCard.dart';
import 'home_widgets/live_safe/PharmacyCard.dart';
import 'home_widgets/live_safe/PoliceStationCard.dart';

class Livesafe extends StatelessWidget {
  const Livesafe({super.key});

  static Future<void> openMap(String location) async
  {
    String googleUrl='https://www.google.co.in/maps/search/$location';
    final Uri _url = Uri.parse(googleUrl);
    try{
      await launchUrl(_url);
    }catch (e)
    {
      Fluttertoast.showToast(msg: 'something went wrong! call emergency number');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      
      height: 90,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        scrollDirection: Axis.horizontal, // Set to horizontal scrolling

        physics: BouncingScrollPhysics(),
        children: [
          PoliceStationCard(onMapFunction:openMap),
           
          HospitalCard(onMapFunction:openMap),
           PharmacyCard(onMapFunction:openMap),
           BusStationCard(onMapFunction:openMap),
        ],
      ),
    );
  }
}