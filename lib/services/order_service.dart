import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eats/utils/common_methods.dart';

// We're fetching the unassigned/pending orders

class OrderService {
  Stream<QuerySnapshot> getPendingOrders() {
    // this will receive a new query snapshot every time the query results change (that is when a document is added, removed or modified)

    return FirebaseFirestore.instance.collection('orders').where('status',
        whereIn: [
          'accepted by restuarant',
          'preparing',
          'ready for pickup',
          'pending'
        ]).snapshots();
  }
}

//the accepting of orders by driver
// this needs to change the status of the order status in the firebase

// Future<void> acceptOrder(String orderId, String driverId) {
//   FirebaseFirestore.instance
//       .collection('orders')
//       .doc(orderId)
//       .update({'status': 'picking up order'});
// }

// Future<void> assigns a driver to an order in Firestore

Future<void> acceptOrder(BuildContext context, String orderId) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

    //Step 1: Check if the order is already assigned
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data();
      final currentStatus = data?['status'];

      if (currentStatus == 'assigned') {
        CommonMethods.displaySnackBar(
            'The order has already been assigned', context);

        return;
      }
      // no need for the if statement it would be redundant
      await docRef.update({'status': 'assigned'});
      CommonMethods.displaySnackBar('Order has been accepted', context);
    }
  } catch (e) {
    // Step 4: Error Handling
    CommonMethods.displaySnackBar('Failed to accept order', context);
  }
}

void updateStatus(String orderId) async {
  await FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .update({'status': 'accepted'});
}

void rejectStatus(String orderId) async {
  await FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .update({'status': 'rejected'});
}
// Since this function uses context, we must it from a widget that has access to a BuildContext. 
// like inside a button press

//Example
//ElevatedButton(
  //onPressed: () {
    //acceptOrder(context, orderId, driverId);
  //},
  //child: Text("Accept Order"),
//)
