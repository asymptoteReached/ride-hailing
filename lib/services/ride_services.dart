import 'package:eats/models/ride_model.dart';
import 'package:eats/services/firebase_service.dart';

class RideService {
  final FirebaseService _firebaseService = FirebaseService();
  Future<String> createRideRequest({
    required String riderName,
    required String riderPhone,
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
    required double fare,
    required String vehicleType,
  }) async {
    return await _firebaseService.createRideRequest(
        riderName: riderName,
        riderPhone: riderPhone,
        pickup: pickup,
        dropoff: dropoff,
        fare: fare,
        vehicleType: vehicleType);
  }

  Future<void> completeRide({required String rideId}) async {
    return await _firebaseService.completeRide(rideId: rideId);
  }

  // Fix: Return Stream<Ride> instead of Stream<Map<String, dynamic>>
  Stream<Ride> streamRide(String rideId) {
    return _firebaseService.streamRide(rideId);
  }

  Stream<Map<String, dynamic>?> streamDriverLocation(String driverId) {
    return _firebaseService.streamDriverLocation(driverId);
  }
}
