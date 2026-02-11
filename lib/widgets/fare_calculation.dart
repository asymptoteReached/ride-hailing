import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

double simpleFare(LatLng pickup, LatLng dropoff) {
  const double baseFare = 30.0; // fixed starting fare
  const double perKm = 2.0; // rate per km

  double toRadians(double degree) => degree * pi / 180;

  double lat1 = pickup.latitude;
  double lon1 = pickup.longitude;
  double lat2 = dropoff.latitude;
  double lon2 = dropoff.longitude;

  double dLat = toRadians(lat2 - lat1);
  double dLon = toRadians(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRadians(lat1)) *
          cos(toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  const R = 6371; // Earth radius in km
  double distanceKm = R * c;

  double fare = baseFare + (distanceKm * perKm);
  return double.parse(fare.toStringAsFixed(2)); // rounded to 2 decimals
}
