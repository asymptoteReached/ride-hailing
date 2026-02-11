import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final IconData? data;
  final String? hintText;
  final bool?
      isObsecure; // this is the dot dot dot form for security of password
  final bool? enabled;

  const CustomTextField({
    super.key,
    this.controller,
    this.data,
    this.hintText,
    this.isObsecure = true, // we're defaulting to true
    this.enabled = true, // this allows you to edit the text field when true.
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.all(10),
        child: TextFormField(
          enabled: enabled,
          controller: controller,
          obscureText:
              isObsecure!, //! is called the null assetion operator. It tells Dart "Im sure this value is not null(empty) -- treat it as non-null(non-empty)"
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(
                data,
                color: Colors.red,
              ),
              focusColor: Theme.of(context).primaryColor,
              hintText: hintText),
        ));
  }
}
