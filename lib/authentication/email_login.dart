import 'package:eats/authentication/email_sign_up.dart';
import 'package:eats/rider/screens/rider_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:eats/utils/create_user_acc.dart';

class EmailLogin extends StatefulWidget {
  const EmailLogin({
    super.key,
  });

  @override
  State<EmailLogin> createState() => _EmailLogin();
}

class _EmailLogin extends State<EmailLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
        ),
        body: Container(
          padding: EdgeInsets.all(15),
          margin: EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
          child: Column(
            children: [
              SizedBox(
                height: 5,
              ),
              TextField(
                  keyboardType: TextInputType.emailAddress,
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Enter your email'),
                  style: TextStyle(color: Colors.white)),
              SizedBox(height: 10),
              TextField(
                  keyboardType: TextInputType.emailAddress,
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Enter your password'),
                  obscureText: true,
                  style: TextStyle(color: Colors.white)),
              SizedBox(
                height: 5,
              ),
              ElevatedButton(
                onPressed: () async {
                  CircularProgressIndicator(color: Colors.white);
                  final String emailAddress = emailController.text.trim();
                  final String password = passwordController.text.trim();
                  await CreateOrSignUser().signInWithEmailAndPassword(
                      emailAddress, password, context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RiderHomeScreen()),
                  );
                },
                child: Text(
                    'Login'), // ✅ this belongs to the ElevatedButton itself
              ),
              SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: EdgeInsetsGeometry.all(20)),
                  Text('Don\'t have an account?'),
                  SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EmailSignUp()));
                      },
                      child: Text('Sign Up'))
                ],
              )
            ],
          ),
        ));
  }
}
