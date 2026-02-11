// Separate verification screen for better UX
import 'package:eats/utils/common_methods.dart';
import 'package:flutter/material.dart';
import 'package:eats/utils/create_user_acc.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String userName;
  final bool isSignUp;
  final Function() onVerificationSuccess;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.userName,
    required this.isSignUp,
    required this.onVerificationSuccess,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final CreateOrSignUser _authService = CreateOrSignUser();
  bool _isLoading = false;
  bool _isResending = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _startVerification();

    // Setup focus node listeners
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && i < 5) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        }
      });
    }
  }

  void _startVerification() {
    if (widget.isSignUp) {
      _authService.createUserWithPhoneNumber(
        phoneNumber: widget.phoneNumber,
        userName: widget.userName,
        context: context,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        onVerified: widget.onVerificationSuccess,
      );
    } else {
      _authService.signInWithPhoneNumber(
        phoneNumber: widget.phoneNumber,
        userName: widget.userName,
        context: context,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        onVerified: widget.onVerificationSuccess,
      );
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
    });

    final code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      CommonMethods.displaySnackBar('Please enter the 6-digit code', context);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final success = await _authService.verifySmsCode(
      smsCode: code,
      context: context,
      userName: widget.userName,
      phoneNumber: widget.phoneNumber,
    );

    if (success) {
      widget.onVerificationSuccess();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    // Clear all fields
    for (var controller in _controllers) {
      controller.clear();
    }

    // Refocus on first field
    FocusScope.of(context).requestFocus(_focusNodes[0]);

    // Restart verification
    _startVerification();

    CommonMethods.displaySnackBar('Code resent successfully', context);

    setState(() {
      _isResending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.phone_android,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            Text(
              'Verify your phone number',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'We sent a verification code to',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 5),
            Text(
              widget.phoneNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context)
                            .requestFocus(_focusNodes[index + 1]);
                      }
                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context)
                            .requestFocus(_focusNodes[index - 1]);
                      }
                      // Auto submit when all fields are filled
                      if (index == 5 && value.isNotEmpty) {
                        bool allFilled = true;
                        for (var controller in _controllers) {
                          if (controller.text.isEmpty) {
                            allFilled = false;
                            break;
                          }
                        }
                        if (allFilled) {
                          _verifyCode();
                        }
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Resend Code
            TextButton(
              onPressed: _isResending ? null : _resendCode,
              child: _isResending
                  ? const Text('Resending...')
                  : const Text('Resend Code'),
            ),

            // Help Text
            const SizedBox(height: 30),
            const Text(
              'Didn\'t receive the code?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              'Make sure your phone number is correct and try again.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
