import 'package:flutter/material.dart';

class CommonMethods {
  static void displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class CountdoownAcceptButton extends StatefulWidget {
  const CountdoownAcceptButton({super.key});

  @override
  State<CountdoownAcceptButton> createState() => _CountdoownAcceptButtonState();
}

class _CountdoownAcceptButtonState extends State<CountdoownAcceptButton> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
