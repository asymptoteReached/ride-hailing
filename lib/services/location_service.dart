import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationService {
  final Location _location = Location();
  GoogleMapController? _mapController;

  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  LatLng? _driverLocation;
  Marker? _driverMarker;

  LatLng? get currentLocation => _pickupLocation;
  LatLng? get pickupLocation => _pickupLocation;
  LatLng? get dropoffLocation => _dropoffLocation;

  Future<void> initializeLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final loc = await _location.getLocation();
    _pickupLocation =
        LatLng(loc.latitude ?? -26.2041, loc.longitude ?? 28.0473);

    _location.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null &&
          locationData.longitude != null &&
          _mapController != null) {
        final newLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
        _mapController!.animateCamera(CameraUpdate.newLatLng(newLocation));
      }
    });
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pickupLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickupLocation!, zoom: 14),
        ),
      );
    }
  }

  void updatePickupLocation(LatLng location) {
    _pickupLocation = location;
  }

  void updateDropoffLocation(LatLng location) {
    _dropoffLocation = location;
  }

  void updateDriverLocation(LatLng newLocation) {
    _driverLocation = newLocation;
    _driverMarker = Marker(
      markerId: MarkerId('driver'),
      position: newLocation,
      infoWindow: InfoWindow(title: 'Driver'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
  }

  Set<Marker> buildMarkers() {
    final markers = <Marker>{};
    if (_pickupLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('pickup'),
        position: _pickupLocation!,
        infoWindow: InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    if (_dropoffLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('dropoff'),
        position: _dropoffLocation!,
        infoWindow: InfoWindow(title: 'Dropoff'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    if (_driverMarker != null) markers.add(_driverMarker!);
    return markers;
  }

  Future<String?> reverseGeocode(LatLng position) async {
    try {
      final results = await geocoding.placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (results.isNotEmpty) {
        final place = results.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      }
    } catch (e) {
      print("Reverse geocoding error: $e");
    }
    return null;
  }

  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final results = await geocoding.locationFromAddress(address);
      if (results.isNotEmpty) {
        return LatLng(results.first.latitude, results.first.longitude);
      }
    } catch (e) {
      print("Geocoding error: $e");
    }
    return null;
  }
}
