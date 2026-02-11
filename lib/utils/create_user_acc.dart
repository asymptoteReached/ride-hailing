import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:eats/utils/common_methods.dart';

class CreateOrSignUser {
  // Phone authentication variables
  String? _verificationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create user with phone number (for sign up)
  Future<bool> createUserWithPhoneNumber({
    required String phoneNumber,
    required String userName,
    required BuildContext context,
    required Function(String) onCodeSent,
    required Function() onVerified,
  }) async {
    try {
      // Start phone verification
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification on some devices
          await _auth.signInWithCredential(credential);
          await _createUserProfile(userName, phoneNumber, context);
          onVerified();
        },
        verificationFailed: (FirebaseAuthException e) {
          CommonMethods.displaySnackBar(
            'Verification failed: ${e.message}',
            context,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);

          // Show verification code dialog
          _showVerificationDialog(context, onVerified, userName, phoneNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );

      return true;
    } catch (e) {
      CommonMethods.displaySnackBar('Error: ${e.toString()}', context);
      return false;
    }
  }

  // Sign in with phone number (for login)
  Future<bool> signInWithPhoneNumber({
    required String phoneNumber,
    required String userName,
    required BuildContext context,
    required Function(String) onCodeSent,
    required Function() onVerified,
  }) async {
    try {
      // Start phone verification
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification on some devices
          await _auth.signInWithCredential(credential);

          // Check if user exists, if not create profile
          if (_auth.currentUser != null) {
            final userExists = await _checkUserExists(_auth.currentUser!.uid);
            if (!userExists) {
              await _createUserProfile(userName, phoneNumber, context);
            } else {
              // Update name if changed
              await _updateUserName(_auth.currentUser!.uid, userName, context);
            }
          }

          onVerified();
        },
        verificationFailed: (FirebaseAuthException e) {
          CommonMethods.displaySnackBar(
            'Verification failed: ${e.message}',
            context,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);

          // Show verification code dialog
          _showVerificationDialog(context, onVerified, userName, phoneNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );

      return true;
    } catch (e) {
      CommonMethods.displaySnackBar('Error: ${e.toString()}', context);
      return false;
    }
  }

  // Verify SMS code
  Future<bool> verifySmsCode({
    required String smsCode,
    required BuildContext context,
    required String userName,
    required String phoneNumber,
  }) async {
    try {
      if (_verificationId == null) {
        CommonMethods.displaySnackBar('Verification ID not found', context);
        return false;
      }

      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user exists in database
        final userExists = await _checkUserExists(userCredential.user!.uid);

        if (!userExists) {
          // Create new user profile
          await _createUserProfile(userName, phoneNumber, context);
        } else {
          // Update name if changed
          await _updateUserName(userCredential.user!.uid, userName, context);
        }

        return true;
      }

      return false;
    } catch (e) {
      CommonMethods.displaySnackBar('Invalid verification code', context);
      return false;
    }
  }

  // Check if user exists in database
  Future<bool> _checkUserExists(String userId) async {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: FirebaseAuth.instance.app,
        databaseURL:
            'https://eats-33686-default-rtdb.europe-west1.firebasedatabase.app/',
      );

      final userRef = database.ref().child('users').child(userId);
      final snapshot = await userRef.get();

      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(
    String userName,
    String phoneNumber,
    BuildContext context,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final database = FirebaseDatabase.instanceFor(
        app: FirebaseAuth.instance.app,
        databaseURL:
            'https://eats-33686-default-rtdb.europe-west1.firebasedatabase.app/',
      );

      DatabaseReference userRef =
          database.ref().child('users').child(currentUser.uid);

      Map userDataMap = {
        'name': userName,
        'phoneNumber': phoneNumber,
        'id': currentUser.uid,
        'email': '', // Empty for phone-only users
        'blockStatus': 'no',
        'createdAt': DateTime.now().toIso8601String(),
        'userType': 'rider', // Default to rider
      };

      await userRef.set(userDataMap);
    } catch (e) {
      CommonMethods.displaySnackBar('Error creating profile: $e', context);
    }
  }

  // Update user name
  Future<void> _updateUserName(
    String userId,
    String userName,
    BuildContext context,
  ) async {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: FirebaseAuth.instance.app,
        databaseURL:
            'https://eats-33686-default-rtdb.europe-west1.firebasedatabase.app/',
      );

      DatabaseReference userRef = database.ref().child('users').child(userId);

      await userRef.update({
        'name': userName,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail - name update isn't critical
    }
  }

  // Show verification code input dialog
  void _showVerificationDialog(
    BuildContext context,
    Function() onVerified,
    String userName,
    String phoneNumber,
  ) {
    final codeController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Enter Verification Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We sent a 6-digit code to your phone',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please check your SMS messages',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '123456',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Resend code logic
                    signInWithPhoneNumber(
                      phoneNumber: phoneNumber,
                      userName: userName,
                      context: context,
                      onCodeSent: (verificationId) {
                        _verificationId = verificationId;
                        CommonMethods.displaySnackBar(
                          'Code resent successfully',
                          context,
                        );
                      },
                      onVerified: onVerified,
                    );
                  },
                  child: const Text('Resend Code'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });

                        final success = await verifySmsCode(
                          smsCode: codeController.text,
                          context: context,
                          userName: userName,
                          phoneNumber: phoneNumber,
                        );

                        setState(() {
                          isLoading = false;
                        });

                        if (success) {
                          Navigator.pop(context); // Close dialog
                          onVerified();
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final database = FirebaseDatabase.instanceFor(
        app: FirebaseAuth.instance.app,
        databaseURL:
            'https://eats-33686-default-rtdb.europe-west1.firebasedatabase.app/',
      );

      final userRef = database.ref().child('users').child(currentUser.uid);
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get current user phone
  String? getCurrentUserPhone() {
    return _auth.currentUser?.phoneNumber;
  }

  // Original email methods (kept for compatibility)
  Future<bool> createUserWithEmailAndPassword(String name, String phoneNumber,
      String emailAddress, String password, BuildContext context) async {
    try {
      if (password.length < 8 || !emailAddress.contains('@')) {
        return false;
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailAddress, password: password);
      final database = FirebaseDatabase.instanceFor(
          app: FirebaseAuth.instance.app,
          databaseURL:
              'https://eats-33686-default-rtdb.europe-west1.firebasedatabase.app/');

      DatabaseReference userRef =
          database.ref().child('users').child(credential.user!.uid);

      Map userDataMap = {
        'name': name,
        'email': emailAddress,
        'id': credential.user!.uid,
        'phoneNumber': phoneNumber,
        'blockStatus': 'no',
      };

      await userRef.set(userDataMap);

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        CommonMethods.displaySnackBar('Create a stronger password.', context);
      } else if (e.code == 'email-already-in-use') {
        CommonMethods.displaySnackBar(
            'The account already exists for that email. Login.', context);
      }
      return false;
    } catch (e) {
      CommonMethods.displaySnackBar('An unexpected error occured', context);
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword(
      String emailAddress, String password, BuildContext context) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailAddress, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        CommonMethods.displaySnackBar(
            'User not found. Create an account', context);
        return false;
      } else if (e.code == 'wrong-password') {
        CommonMethods.displaySnackBar(
            'Wrong password provided for that user', context);
        return false;
      }
    }
    return false;
  }
}
