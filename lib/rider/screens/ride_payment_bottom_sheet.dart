import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:eats/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RidePaymentBottomSheet extends StatefulWidget {
  final String rideId;
  final double amount;
  final VoidCallback onPaymentSuccess;
  final Function(String) onPaymentError;
  final VoidCallback onPaymentProcessing;

  const RidePaymentBottomSheet({
    required this.rideId,
    required this.amount,
    required this.onPaymentSuccess,
    required this.onPaymentError,
    required this.onPaymentProcessing,
    super.key,
  });

  @override
  State<RidePaymentBottomSheet> createState() => _RidePaymentBottomSheetState();
}

class _RidePaymentBottomSheetState extends State<RidePaymentBottomSheet> {
  bool _isProcessing = false;
  final PaymentService _paymentService = PaymentService();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.65)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pay for your ride',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Amount: \$${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              _isProcessing
                  ? const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    )
                  : Column(
                      children: [
                        _buildPaymentButton(
                          label: 'Pay with MoMo',
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                          onPressed: _payWithMomo,
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentButton(
                          label: 'Pay with PayPal',
                          colors: [Colors.green, Colors.lightGreen],
                          onPressed: _payWithPayPal,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton({
    required String label,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: colors.last.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _payWithMomo() async {
    setState(() => _isProcessing = true);
    widget.onPaymentProcessing();

    try {
      final referenceId = await _paymentService.requestMomoPayment(
        rideId: widget.rideId,
        amount: widget.amount,
        phone: 'YOUR_PHONE_HERE', // Pass user phone dynamically
      );

      // Poll until payment confirmed
      bool paid = false;
      int attempts = 0;
      while (!paid && attempts < 10) {
        await Future.delayed(const Duration(seconds: 3));
        paid = await _paymentService.verifyMomoPayment(
          rideId: widget.rideId,
          referenceId: referenceId,
        );
        attempts++;
      }

      if (paid) {
        widget.onPaymentSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        widget.onPaymentError('MoMo payment not confirmed');
      }
    } catch (e) {
      widget.onPaymentError(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _payWithPayPal() async {
    setState(() => _isProcessing = true);
    widget.onPaymentProcessing();

    try {
      final orderData = await _paymentService.createPayPalOrder(
        rideId: widget.rideId,
        amount: widget.amount,
      );

      final approvalLink = orderData['approvalLink'] as String?;
      if (approvalLink == null) throw Exception('Approval link missing');

      final uri = Uri.parse(approvalLink);
      if (await canLaunch(uri.toString())) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // After user approves payment, capture it in your backend
        widget.onPaymentSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        widget.onPaymentError('Cannot open PayPal checkout');
      }
    } catch (e) {
      widget.onPaymentError(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
