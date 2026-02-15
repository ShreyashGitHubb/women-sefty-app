import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  //const CustomTextfield({super.key});

  final String? hintText;
  final TextEditingController? controller;
  final  String? Function(String?)? validate;
  final  Function(String?)? onsave;

  final int? maxlines;
  final bool isPassword;
  final bool enable;
  final bool check;

  final TextInputType? keyboardtype;
  final TextInputAction? textInputAction;
  final FocusNode?focusNode;
  final Widget? prefix;
  final Widget?suffix;

const CustomTextfield({
    Key? key,
    this.hintText,
    this.controller,
    this.validate,
    this.onsave,
    this.maxlines,
    this.isPassword = false,
    this.enable = true,
    this.check=true,
    this.keyboardtype,
    this.textInputAction,
    this.focusNode,
    this.prefix,
    this.suffix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  TextFormField(
      enabled: enable==true? true:enable,
      maxLines: maxlines==null?1:maxlines,
      onSaved: onsave,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: keyboardtype==null?TextInputType.name:keyboardtype,
      controller: controller,
      validator: validate,
      obscureText: isPassword==false?false:isPassword,

      decoration: InputDecoration(
        prefixIcon: prefix,
        suffixIcon: suffix,
        labelText: hintText ??"hint text..",

        focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          style: BorderStyle.solid,
          color:Theme.of(context).primaryColor,
        )
      ),

       enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
         borderSide: BorderSide(
          style: BorderStyle.solid,
          color: Color(0xFF909A9E),
        )
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
         borderSide: BorderSide(
          style: BorderStyle.solid,
          color:Theme.of(context).primaryColor,
        )
      ),

        errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
         borderSide: BorderSide(
          style: BorderStyle.solid,
          color: Colors.red,
        )
      ),
      ),
    );
  }
}