import 'package:eats/authentication/phone_sign_up_screen.dart';
import 'package:eats/rider/screens/rider_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:eats/utils/create_user_acc.dart';
import 'package:flutter/services.dart';

class PhoneLogin extends StatefulWidget {
  const PhoneLogin({
    super.key,
  });

  @override
  State<PhoneLogin> createState() => _PhoneLogin();
}

class _PhoneLogin extends State<PhoneLogin> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Swaziland phone number validation
  bool _isValidSwazilandPhone(String phone) {
    // Remove any spaces, dashes, or plus signs
    String cleaned = phone.replaceAll(RegExp(r'[\s\-+]'), '');

    // Check if it's a valid Swaziland mobile number
    // Swaziland mobile numbers typically start with 76, 77, 78, or 79
    // and are 8 digits total (76xxxxxx, etc.)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1); // Remove leading 0 if present
    }

    if (cleaned.startsWith('268')) {
      // International format with country code
      cleaned = cleaned.substring(3); // Remove 268
    }

    // Check if it's 8 digits and starts with valid Swaziland mobile prefix
    if (cleaned.length == 8) {
      final prefix = int.tryParse(cleaned.substring(0, 2));
      if (prefix == null) return false;

      // Valid Swaziland mobile prefixes
      return [76, 77, 78, 79].contains(prefix);
    }

    return false;
  }

  // Format phone number for display
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.startsWith('268')) {
      cleaned = cleaned.substring(3);
    }

    // Format as 76 123 456
    if (cleaned.length == 8) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)} ${cleaned.substring(5)}';
    }

    return phone;
  }

  // Format for Firebase Auth (with country code)
  String _formatForFirebase(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    if (!cleaned.startsWith('268')) {
      cleaned = '268$cleaned';
    }

    return '+$cleaned';
  }

  Future<void> _loginWithPhone() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String name = nameController.text.trim();
        final String phone = phoneController.text.trim();

        // Format phone number properly
        final String formattedPhone = _formatForFirebase(phone);

        await CreateOrSignUser().signInWithPhoneNumber(
          phoneNumber: formattedPhone,
          userName: name,
          context: context,
          onCodeSent: (String verificationId) {
            // Handle code sent if needed
          },
          onVerified: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RiderHomeScreen()),
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Enter your details to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Name Field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                        const Icon(Icons.person, color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                // Phone Field
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon:
                        const Icon(Icons.phone, color: Colors.deepPurple),
                    prefixText: '+268 ',
                    hintText: '76 123 456',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!_isValidSwazilandPhone(value)) {
                      return 'Please enter a valid Swaziland mobile number (e.g., 76123456)';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.length == 8) {
                      setState(() {
                        phoneController.text = _formatPhoneNumber(value);
                        phoneController.selection = TextSelection.fromPosition(
                          TextPosition(offset: phoneController.text.length),
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Text(
                    'Enter your 8-digit Swaziland mobile number (e.g., 76xxxxxx)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginWithPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sign Up Button
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PhoneSignUp(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
