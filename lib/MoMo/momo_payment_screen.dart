import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';

class MoMoPaymentScreen extends StatefulWidget {
  final String rideId;
  final double amount;
  final VoidCallback onPaymentSuccess;
  final Function? onPaymentError;
  final VoidCallback? onPaymentProcessing;

  const MoMoPaymentScreen(
      {super.key,
      required this.rideId,
      required this.amount,
      required this.onPaymentSuccess,
      this.onPaymentError,
      this.onPaymentProcessing});

  @override
  State<MoMoPaymentScreen> createState() => _MoMoPaymentScreenState();
}

class _MoMoPaymentScreenState extends State<MoMoPaymentScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  String? statusMessage;

  Future<void> _payWithMoMo() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => statusMessage = "Please enter your phone number");
      return;
    }

    if (!phone.startsWith('7') || phone.length != 8) {
      setState(
          () => statusMessage = "Please enter a valid MTN number (7xxxxxxx)");
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = null;
    });

    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('initiateMoMoPayment');
      final result = await callable.call({
        'rideId': widget.rideId,
        'phoneNumber': phone,
        'amount': widget.amount,
      });

      setState(() {
        statusMessage = "Payment request sent! Approve on your phone.";
      });

      // Call the success callback
      widget.onPaymentSuccess();
    } catch (e) {
      setState(() {
        statusMessage = "Payment failed: $e";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Pay with MTN MoMo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Amount: E ${widget.amount.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Enter your phone (7xxxxxxx)",
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _payWithMoMo,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Pay Now"),
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              statusMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: statusMessage!.startsWith("Payment failed")
                      ? Colors.red
                      : Colors.green),
            ),
          ],
        ],
      ),
    );
  }
}
