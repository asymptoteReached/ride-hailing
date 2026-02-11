import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

Future<String?> requestMomoPayment({
  required String phone,
  required double amount,
  required String rideId,
}) async {
  try {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('requestMomoPayment');

    final result = await callable.call(<String, dynamic>{
      'phone': phone,
      'amount': amount,
      'rideId': rideId,
    });

    return result.data['referenceId'] as String?;
  } catch (e) {
    print('Error requesting MoMo payment: $e');
    return null;
  }
}

void listenForPayment(String rideId) {
  FirebaseFirestore.instance
      .collection('rides')
      .doc(rideId)
      .snapshots()
      .listen((snapshot) {
    if (!snapshot.exists) return;

    final data = snapshot.data();
    final paid = data?['paid'] as bool? ?? false;
    final status = data?['momoStatus'] as String? ?? 'PENDING';

    if (paid) {
      print('Payment successful for ride $rideId!');
    } else {
      print('Payment status: $status');
    }
  });
}
