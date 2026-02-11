import 'package:flutter/material.dart';
import 'package:eats/services/firebase_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google Maps
import 'package:location/location.dart'; // Location tracking

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final FirebaseService _fs = FirebaseService();
  final Location _location = Location();
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = await _location.getLocation();
    setState(() {
      _currentLocation = LatLng(loc.latitude!, loc.longitude!);
    });

    _location.onLocationChanged.listen((locData) {
      if (_mapController != null) {
        final newLoc = LatLng(locData.latitude!, locData.longitude!);
        _mapController!.animateCamera(CameraUpdate.newLatLng(newLoc));
        _fs.updateDriverLocation(
          driverId: 'driver_test_1',
          lat: locData.latitude!,
          lng: locData.longitude!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _currentLocation!, zoom: 14),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
