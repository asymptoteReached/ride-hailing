import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:eats/models/driver_model.dart';
import 'package:eats/utils/common_methods.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:eats/models/ride_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String rideCollection = 'rides';
  final _uuid = Uuid();

  // Create ride request - NO authentication required
  // Create ride request - UPDATED with GeoPoint support
  Future<String> createRideRequest({
    String? riderId,
    String? riderName,
    String? riderPhone,
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
    required double fare,
    required String vehicleType,
    BuildContext? context,
  }) async {
    try {
      final id = _uuid.v4();
      final now = FieldValue.serverTimestamp();

      // Validate pickup coordinates
      final dynamic pickupLat = pickup['lat'];
      final dynamic pickupLng = pickup['lng'];

      if (pickupLat == null || pickupLng == null) {
        ScaffoldMessenger.of(context!)
            .showSnackBar(SnackBar(content: Text('Invalid pickup location')));
        throw Exception('Invalid pickup location coordinates');
      }

      final pickupLatDouble = pickupLat is double
          ? pickupLat
          : double.tryParse(pickupLat.toString()) ?? 0.0;
      final pickupLngDouble = pickupLng is double
          ? pickupLng
          : double.tryParse(pickupLng.toString()) ?? 0.0;

      // Generate guest rider ID
      final guestRiderId = 'guest_${_uuid.v4()}';

      final Map<String, dynamic> data = {
        'id': id,
        'riderId': guestRiderId, // Guest ID instead of authenticated user ID
        'riderName': riderName,
        'riderPhone': riderPhone,
        'isGuest': true, // Flag to identify guest riders
        'driverId': null, // IMPORTANT: No automatic assignment
        'pickup': pickup,
        'dropoff': dropoff,
        'status': 'requested', // Changed from 'accepted' to 'requested'
        'fare': fare,
        'vehicleType': vehicleType,
        'paymentStatus': 'pending',
        'companyCut': fare * 0.2,
        'driverCut': fare * 0.8,
        'createdAt': now,
        'updatedAt': now,
        'pickupGeoPoint':
            GeoPoint(pickupLatDouble, pickupLngDouble), // ADD THIS
      };

      await _db.collection(rideCollection).doc(id).set(data);

      // DON'T update driver availability here - driver will accept manually
      return id;
    } catch (e) {
      print('Error creating ride request: $e');
      ScaffoldMessenger.of(context!).showSnackBar(SnackBar(
          content: Text('Failed to create ride request please try again')));
      throw Exception('Failed to create ride request. Please try again.');
    }
  }

  // Listen to available requests (for drivers)
  Stream<List<Ride>> streamAvailableRequests() {
    return _db
        .collection(rideCollection)
        .where('status', isEqualTo: 'requested')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Ride.fromMap(Map<String, dynamic>.from(d.data())))
            .toList());
  }

  // Listen to a single ride
  Stream<Ride> streamRide(String id) {
    return _db.collection(rideCollection).doc(id).snapshots().asyncMap((snap) {
      if (!snap.exists) {
        return Ride.empty();
      }

      final data = snap.data();
      if (data == null) {
        return Ride.empty();
      }

      return Ride.fromMap(Map<String, dynamic>.from(data));
    });
  }

// Get driver from Firestore
  Future<Driver?> getDriver(String driverId) async {
    try {
      final doc = await _db.collection('drivers').doc(driverId).get();

      if (doc.exists) {
        return Driver.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      print('Error getting driver: $e');
      return null;
    }
  }

  Stream<Driver> streamDriver(String driverId) {
    return FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Driver.fromMap({...snapshot.data()!, 'id': driverId});
      }
      throw Exception('Driver not found');
    });
  }

  // Driver accepts ride
  Future<void> acceptRide({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverPhone,
  }) async {
    await _db.collection(rideCollection).doc(rideId).update({
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Start ride
  Future<void> startRide({required String rideId}) async {
    await _db.collection(rideCollection).doc(rideId).update({
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Complete ride
  Future<void> completeRide({required String rideId}) async {
    final doc = await _db.collection(rideCollection).doc(rideId).get();
    if (!doc.exists) return;
    final data = doc.data()!;

    // Copy to history
    await _db.collection('rides_history').doc(rideId).set(data);

    // Delete from active
    await _db.collection(rideCollection).doc(rideId).delete();

    // Free up the driver
    if (data['driverId'] != null) {
      await _db.collection('drivers').doc(data['driverId']).update({
        'isAvailable': true,
        'currentRideId': null,
      });
    }
  }

  // Cancel ride
  Future<void> cancelRide({
    required String rideId,
    required String reason,
    String? cancelledBy,
  }) async {
    await _db.collection(rideCollection).doc(rideId).update({
      'status': 'cancelled',
      'cancellationReason': reason,
      'cancelledBy': cancelledBy ?? 'rider',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Free up the driver
    final doc = await _db.collection(rideCollection).doc(rideId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['driverId'] != null) {
        await _db.collection('drivers').doc(data['driverId']).update({
          'isAvailable': true,
          'currentRideId': null,
        });
      }
    }
  }

  Future<void> updateRide(String rideId, Map<String, dynamic> data) async {
    try {
      final updates = Map<String, dynamic>.from(data);
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(rideCollection).doc(rideId).update(updates);
    } catch (e) {
      print('Error updating ride $rideId: $e');
      rethrow;
    }
  }

  // Update driver location
  Future<void> updateDriverLocation({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    await _db.collection('drivers').doc(driverId).set({
      'location': {'lat': lat, 'lng': lng},
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Stream driver location
  Stream<Map<String, dynamic>?> streamDriverLocation(String driverId) {
    return _db.collection('drivers').doc(driverId).snapshots().map((s) {
      if (!s.exists) return null;
      final data = s.data();
      return data != null && data.containsKey('location')
          ? Map<String, dynamic>.from(data['location'])
          : null;
    }).handleError((error) {
      print('Error streaming driver location: $error');
    });
  }

  // Mark payment as requested
  Future<void> markPaymentRequested({
    required String rideId,
    required String paymentRequestId,
    required String provider,
  }) async {
    await _db.collection(rideCollection).doc(rideId).update({
      'paymentStatus': 'requested',
      'paymentRequestId': paymentRequestId,
      'paymentProvider': provider,
      'paymentRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark payment result
  Future<void> markPaymentResult({
    required String rideId,
    required bool success,
    String? providerRef,
  }) async {
    final updates = <String, dynamic>{
      'paymentStatus': success ? 'paid' : 'failed',
      'paymentConfirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (providerRef != null) updates['paymentProviderRef'] = providerRef;
    await _db.collection(rideCollection).doc(rideId).update(updates);
  }

  Future<String> findNearestDriver(LatLng pickupLocation) async {
    try {
      final allDrivers = await _db
          .collection('drivers')
          .where('isOnline', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();

      String nearestDriverId = '';
      double minDistance = double.maxFinite;

      for (var driver in allDrivers.docs) {
        final driverData = driver.data();
        if (!driverData.containsKey('location')) continue;

        final driverLoc = driverData['location'] as Map<String, dynamic>;
        final driverLatLng = LatLng(driverLoc['lat'], driverLoc['lng']);

        final distance = _calculateDistance(pickupLocation, driverLatLng);

        if (distance < minDistance) {
          minDistance = distance;
          nearestDriverId = driver.id;
        }
      }

      return nearestDriverId;
    } catch (e) {
      print('Error finding nearest driver: $e');
      return '';
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371e3; // meters
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  // Process refund
  Future<void> processRefund(String rideId, String reason) async {
    try {
      final rideDoc = await _db.collection(rideCollection).doc(rideId).get();
      final rideData = rideDoc.data();

      if (rideData != null && rideData['paymentStatus'] == 'paid') {
        await _db.collection(rideCollection).doc(rideId).update({
          'paymentStatus': 'refunded',
          'refundReason': reason,
          'refundedAt': FieldValue.serverTimestamp(),
          'status': 'cancelled',
        });
      }
    } catch (e) {
      print('Error processing refund: $e');
      throw Exception('Failed to process refund');
    }
  }

  static final functions = FirebaseFunctions.instance;

  static Future<Map<String, dynamic>> withdrawDriverFunds(
      String driverId, double amount) async {
    final callable = functions.httpsCallable('withdrawDriverFunds');
    final result =
        await callable.call({'driverId': driverId, 'amount': amount});
    return Map<String, dynamic>.from(result.data);
  }

  static Future<Map<String, dynamic>> capturePayPalOrder(
      String rideId, String orderId) async {
    final callable = functions.httpsCallable('capturePayPalOrder');
    final result = await callable.call({'rideId': rideId, 'orderId': orderId});
    return Map<String, dynamic>.from(result.data);
  }
}
