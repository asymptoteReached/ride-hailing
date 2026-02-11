import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:eats/services/firebase_service.dart';
import 'package:eats/models/ride_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRequestListScreen extends StatefulWidget {
  const DriverRequestListScreen({super.key});

  @override
  State<DriverRequestListScreen> createState() =>
      _DriverRequestListScreenState();
}

class _DriverRequestListScreenState extends State<DriverRequestListScreen> {
  final FirebaseService _fs = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Ride? _acceptedRide;
  LocationData? _driverLocation;
  late final Location _location;
  String? _driverId;
  bool _locationServiceEnabled = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _location = Location();
    _getCurrentUser();
    _initLocation();
  }

  void _getCurrentUser() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _driverId = user.uid;
      });
    }
  }

  Future<void> _initLocation() async {
    // Check if location service is enabled
    _locationServiceEnabled = await _location.serviceEnabled();
    if (!_locationServiceEnabled) {
      _locationServiceEnabled = await _location.requestService();
      if (!_locationServiceEnabled) {
        return;
      }
    }

    // Check location permission
    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        return;
      }
    }

    _permissionGranted = permissionStatus == PermissionStatus.granted;

    if (_permissionGranted) {
      _location.onLocationChanged.listen((loc) {
        setState(() => _driverLocation = loc);
        if (_acceptedRide != null && _driverId != null) {
          _fs.updateDriverLocation(
            driverId: _driverId!,
            lat: loc.latitude ?? 0,
            lng: loc.longitude ?? 0,
          );
        }
      });
    }
  }

  Future<String> _formatAddress(Map<String, dynamic> coords) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        coords['lat'],
        coords['lng'],
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return "${p.street ?? ''}, ${p.locality ?? ''}";
      }
    } catch (_) {}
    return "${coords['lat']}, ${coords['lng']}";
  }

  Future<void> _updateRideStatus(String status) async {
    if (_acceptedRide == null || _driverId == null) return;

    try {
      await _fs.updateRide(_acceptedRide!.id, {'status': status});
      final updatedRideMap = _acceptedRide!.toMap();
      updatedRideMap['status'] = status;
      setState(() {
        _acceptedRide = Ride.fromMap(updatedRideMap);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating ride: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              _acceptedRide == null ? 'Available Requests' : 'Active Ride')),
      body: _driverId == null
          ? const Center(child: CircularProgressIndicator())
          : _acceptedRide == null
              ? _buildAvailableRides()
              : _buildActiveRide(),
    );
  }

  Widget _buildAvailableRides() {
    return StreamBuilder<List<Ride>>(
      stream: _fs.streamAvailableRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rides = snapshot.data!;
        if (rides.isEmpty) {
          return const Center(child: Text('No ride requests'));
        }
        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return ListTile(
              title: FutureBuilder<String>(
                future: _formatAddress(ride.pickup),
                builder: (context, snapshot) =>
                    Text('Pickup: ${snapshot.data ?? '...'}'),
              ),
              subtitle: FutureBuilder<String>(
                future: _formatAddress(ride.dropoff),
                builder: (context, snapshot) =>
                    Text('Dropoff: ${snapshot.data ?? '...'}'),
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  try {
                    await _fs.updateRide(ride.id, {
                      'status': 'accepted',
                      'driverId': _driverId,
                    });
                    setState(() {
                      _acceptedRide = Ride.fromMap({
                        ...ride.toMap(),
                        'status': 'accepted',
                        'driverId': _driverId,
                      });
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error accepting ride: $e')));
                  }
                },
                child: const Text('Accept'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveRide() {
    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _driverLocation?.latitude ?? _acceptedRide!.pickup['lat'],
                _driverLocation?.longitude ?? _acceptedRide!.pickup['lng'],
              ),
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: LatLng(
                  _acceptedRide!.pickup['lat'],
                  _acceptedRide!.pickup['lng'],
                ),
                infoWindow: const InfoWindow(title: 'Pickup'),
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: LatLng(
                  _acceptedRide!.dropoff['lat'],
                  _acceptedRide!.dropoff['lng'],
                ),
                infoWindow: const InfoWindow(title: 'Dropoff'),
              ),
              if (_driverLocation != null)
                Marker(
                  markerId: const MarkerId('driver'),
                  position: LatLng(
                    _driverLocation!.latitude!,
                    _driverLocation!.longitude!,
                  ),
                  infoWindow: const InfoWindow(title: 'You'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
                ),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text('Ride Status: ${_acceptedRide!.status}'),
              const SizedBox(height: 10),
              if (_acceptedRide!.status == 'accepted')
                ElevatedButton(
                  onPressed: () => _updateRideStatus('arrived'),
                  child: const Text('Mark Arrived'),
                ),
              if (_acceptedRide!.status == 'arrived')
                ElevatedButton(
                  onPressed: () => _updateRideStatus('in_progress'),
                  child: const Text('Start Trip'),
                ),
              if (_acceptedRide!.status == 'in_progress')
                ElevatedButton(
                  onPressed: () => _updateRideStatus('completed'),
                  child: const Text('Complete Trip'),
                ),
              if (_acceptedRide!.status == 'completed')
                ElevatedButton(
                  onPressed: () {
                    setState(() => _acceptedRide = null);
                  },
                  child: const Text('Finish & Go Back'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
