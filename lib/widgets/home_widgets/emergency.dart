import 'package:flutter/material.dart';
import 'emergencies/AmbulanceEmergency.dart';
import 'emergencies/ArmyEmerGency.dart';
import 'emergencies/FirebrigadeEmergency.dart';
import 'emergencies/policeEmergency.dart';


class Emergency extends StatelessWidget {
  const Emergency({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(

      width: MediaQuery.of(context).size.width,
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,

        physics: BouncingScrollPhysics(),
        children: [
          ArmyEmerGency(),
          policeEmergency(),
          FirebrigadeEmergency(),
          AmbulanceEmergency(),
        ],
      ),
    );
  }
}