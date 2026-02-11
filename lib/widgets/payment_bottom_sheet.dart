import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentBottomSheet extends StatelessWidget {
  final String rideId;

  const PaymentBottomSheet({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Payment Options",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Show MoMo payment widget in a new bottom sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => MoMoPaymentWidget(rideId: rideId),
                );
              },
              child: const Text("Pay with MoMo"),
            ),
            ElevatedButton(
              onPressed: () {
                // Placeholder for other payment methods
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Other payment selected')),
                );
              },
              child: const Text("Other Payment Methods"),
            ),
          ],
        ),
      ),
    );
  }
}

class MoMoPaymentWidget extends StatefulWidget {
  final String rideId;

  const MoMoPaymentWidget({super.key, required this.rideId});

  @override
  State<MoMoPaymentWidget> createState() => _MoMoPaymentWidgetState();
}

class _MoMoPaymentWidgetState extends State<MoMoPaymentWidget> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  String? statusMessage;

  Future<void> _payWithMoMo() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => statusMessage = "Please enter your phone number");
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
        'phoneNumber': phone, // backend will add the country code
      });

      setState(() {
        statusMessage = "Payment request sent! Approve on your phone.";
      });
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Enter your phone (7xxxxxxx)",
              border: OutlineInputBorder(),
            ),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
