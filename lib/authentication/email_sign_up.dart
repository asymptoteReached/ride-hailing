import 'package:eats/authentication/email_login.dart';
import 'package:eats/rider/screens/rider_home_screen.dart';
import 'package:eats/utils/common_methods.dart';
import 'package:flutter/material.dart';
import 'package:eats/utils/create_user_acc.dart';

class EmailSignUp extends StatefulWidget {
  const EmailSignUp({
    super.key,
  });

  @override
  State<EmailSignUp> createState() => _EmailSignUp();
}

class _EmailSignUp extends State<EmailSignUp> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Create an account'),
        ),
        body: Container(
          padding: EdgeInsets.all(5),
          margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
          child: Column(
            children: [
              Padding(padding: EdgeInsetsGeometry.all(5)),
              TextField(
                keyboardType: TextInputType.text,
                controller: nameController,
                decoration: InputDecoration(labelText: 'Enter your Name'),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(
                height: 10,
              ),
              TextField(
                keyboardType: TextInputType.number,
                controller: phoneNumberController,
                decoration:
                    InputDecoration(labelText: 'Enter your phone number'),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(
                height: 10,
              ),
              TextField(
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
                decoration: InputDecoration(labelText: 'Enter your email'),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(
                height: 10,
              ),
              TextField(
                keyboardType: TextInputType.emailAddress,
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Create your password'),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  CircularProgressIndicator();
                  final String name = nameController.text.trim();
                  final String phoneNumber = phoneNumberController.text.trim();
                  final String emailAddress = emailController.text.trim();
                  final String password = passwordController.text.trim();

                  if (password.length < 8) {
                    CommonMethods.displaySnackBar(
                        'Password must have 8 or more characters', context);
                    return;
                  }

                  bool success = await CreateOrSignUser()
                      .createUserWithEmailAndPassword(
                          name, phoneNumber, emailAddress, password, context);

                  if (success == true) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RiderHomeScreen()),
                    );
                  }
                },

                child: Text(
                    'Sign Up'), // ✅ this belongs to the ElevatedButton itself
              ),
              SizedBox(
                height: 7,
              ),
              Row(
                children: [
                  Text('Already have account?'),
                  SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) {
                          return EmailLogin();
                        }));
                      },
                      child: Text('Login here'))
                ],
              )
            ],
          ),
        ));
  }
}
