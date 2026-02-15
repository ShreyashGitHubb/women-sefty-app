import 'package:flutter/material.dart';

import '../../utils/quets.dart';

class CustomAppbar extends StatelessWidget {
  //const CustomAppbar({super.key});

  final Function? onTap;
  final int? quoteIndex;
  CustomAppbar({this.onTap,this.quoteIndex});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    onTap: onTap != null ? () => onTap!() : null,
      child: Container(
        child: Text(
          sweetSaying[quoteIndex!],
            style: TextStyle(
            fontSize: 22,
          ),
        ),
      )
    );
  }
}