import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:eats/utils/car_marker_utils.dart'; // Add this import

// Separate widget for GoogleMap to isolate its state
class GoogleMapWidget extends StatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final Function(LatLng) onTap;
  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final LatLng? driverLocation;
  final double bottomPadding;
  final bool isInteractive;

  const GoogleMapWidget({
    super.key,
    required this.onMapCreated,
    required this.onTap,
    this.pickupLocation,
    this.dropoffLocation,
    this.driverLocation,
    this.bottomPadding = 100,
    this.isInteractive = true,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  BitmapDescriptor? _carIcon;
  LatLng? _previousDriverLocation;

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
  }

  Future<void> _loadCarIcon() async {
    _carIcon = await CarMarkerUtils.getDriverCarIcon();
    if (mounted) setState(() {});
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = <Marker>{};

    // Add pickup marker
    if (widget.pickupLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupLocation!,
        infoWindow: const InfoWindow(title: 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    // Add dropoff marker
    if (widget.dropoffLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.dropoffLocation!,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    // Add driver marker with custom car icon
    if (widget.driverLocation != null && _carIcon != null) {
      double bearing = 0;

      // Calculate bearing if we have previous location
      if (_previousDriverLocation != null) {
        bearing = CarMarkerUtils.calculateBearing(
          _previousDriverLocation!,
          widget.driverLocation!,
        );
      }

      _previousDriverLocation = widget.driverLocation!;

      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: widget.driverLocation!,
        infoWindow: const InfoWindow(title: 'Your Driver'),
        icon: _carIcon!, // Use custom car icon
        rotation: bearing, // Car faces direction of movement
        anchor: const Offset(0.5, 0.5), // Center the marker
        flat: true, // Make marker flat on the map
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    // Determine initial camera position
    LatLng initialPosition =
        const LatLng(-26.2041, 28.0473); // Default to Johannesburg

    if (widget.driverLocation != null) {
      // If driver location is available, focus on driver
      initialPosition = widget.driverLocation!;
    } else if (widget.pickupLocation != null) {
      // Otherwise focus on pickup
      initialPosition = widget.pickupLocation!;
    }

    return GoogleMap(
      key: const ValueKey('google_map'),
      onMapCreated: widget.onMapCreated,
      onTap: widget.isInteractive ? widget.onTap : null,
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 14,
        bearing: 30,
        tilt: 45,
      ),
      markers: _buildMarkers(),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      rotateGesturesEnabled: widget.isInteractive,
      tiltGesturesEnabled: widget.isInteractive,
      zoomControlsEnabled: false,
      scrollGesturesEnabled: widget.isInteractive,
      zoomGesturesEnabled: widget.isInteractive,
      padding: EdgeInsets.only(
        top: 200,
        bottom: widget.bottomPadding,
      ),
      trafficEnabled: true, // Show traffic for better context
    );
  }
}
