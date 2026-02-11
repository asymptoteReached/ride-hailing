import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  final HttpsCallable createPayPalOrderCallable =
      FirebaseFunctions.instance.httpsCallable('createPayPalOrder');

  final HttpsCallable capturePayPalOrderCallable =
      FirebaseFunctions.instance.httpsCallable('capturePayPalOrder');

  final HttpsCallable requestMomoPaymentCallable =
      FirebaseFunctions.instance.httpsCallable('requestMomoPayment');

  final HttpsCallable verifyMomoPaymentCallable =
      FirebaseFunctions.instance.httpsCallable('verifyMomoPayment');

  /// PayPal: create order
  Future<Map<String, dynamic>> createPayPalOrder({
    required String rideId,
    required double amount,
  }) async {
    final result = await createPayPalOrderCallable.call({
      'rideId': rideId,
      'amount': amount,
    });

    return Map<String, dynamic>.from(result.data);
  }

  /// PayPal: capture order
  Future<Map<String, dynamic>> capturePayPalOrder({
    required String rideId,
    required String orderId,
  }) async {
    final result = await capturePayPalOrderCallable.call({
      'rideId': rideId,
      'orderId': orderId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// MoMo: request payment
  Future<String> requestMomoPayment({
    required String rideId,
    required double amount,
    required String phone,
  }) async {
    final result = await requestMomoPaymentCallable.call({
      'rideId': rideId,
      'amount': amount,
      'phone': phone,
    });
    return result.data['referenceId'];
  }

  /// MoMo: verify payment
  Future<bool> verifyMomoPayment({
    required String rideId,
    required String referenceId,
  }) async {
    final result = await verifyMomoPaymentCallable.call({
      'rideId': rideId,
      'referenceId': referenceId,
    });
    return result.data['success'];
  }
}
