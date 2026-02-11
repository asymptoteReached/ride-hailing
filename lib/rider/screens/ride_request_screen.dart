import 'package:eats/models/place_prediction_model.dart';
import 'package:eats/models/ride_model.dart';
import 'package:eats/rider/screens/google_maps.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:eats/services/firebase_service.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:eats/widgets/fare_calculation.dart';
import 'package:eats/widgets/rotating_gradient_border.dart';
import 'dart:async';
import 'package:eats/widgets/google_map_methods.dart';
import 'package:uuid/uuid.dart';

// State management class
class RiderRequestState {
  final String? currentRideId;
  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final LatLng? driverLocation;
  final double? fare;
  final bool awaitingDropoff;
  final bool requesting;
  final bool isPaymentProcessing;
  final bool isPaymentCompleted;
  final bool isModalShown;
  final bool showRiderInfoDialog;
  final bool showCashPaymentDialog;
  final List<PlacePredictionModel> pickupPredictions;
  final List<PlacePredictionModel> dropOffPredictions;
  final String? riderName;
  final String? riderPhone;
  final Ride? currentRide;
  final double sheetHeight;

  const RiderRequestState({
    this.currentRideId,
    this.pickupLocation,
    this.dropoffLocation,
    this.driverLocation,
    this.fare,
    this.awaitingDropoff = false,
    this.requesting = false,
    this.isPaymentProcessing = false,
    this.isPaymentCompleted = false,
    this.isModalShown = false,
    this.showRiderInfoDialog = false,
    this.showCashPaymentDialog = false,
    this.pickupPredictions = const [],
    this.dropOffPredictions = const [],
    this.riderName,
    this.riderPhone,
    this.currentRide,
    this.sheetHeight = 0.3,
  });

  RiderRequestState copyWith({
    String? currentRideId,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    LatLng? driverLocation,
    double? fare,
    bool? awaitingDropoff,
    bool? requesting,
    bool? isPaymentProcessing,
    bool? isPaymentCompleted,
    bool? isModalShown,
    bool? showRiderInfoDialog,
    bool? showCashPaymentDialog,
    List<PlacePredictionModel>? pickupPredictions,
    List<PlacePredictionModel>? dropOffPredictions,
    String? riderName,
    String? riderPhone,
    Ride? currentRide,
    double? sheetHeight,
  }) {
    return RiderRequestState(
      currentRideId: currentRideId ?? this.currentRideId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      driverLocation: driverLocation ?? this.driverLocation,
      fare: fare ?? this.fare,
      awaitingDropoff: awaitingDropoff ?? this.awaitingDropoff,
      requesting: requesting ?? this.requesting,
      isPaymentProcessing: isPaymentProcessing ?? this.isPaymentProcessing,
      isPaymentCompleted: isPaymentCompleted ?? this.isPaymentCompleted,
      isModalShown: isModalShown ?? this.isModalShown,
      showRiderInfoDialog: showRiderInfoDialog ?? this.showRiderInfoDialog,
      showCashPaymentDialog:
          showCashPaymentDialog ?? this.showCashPaymentDialog,
      pickupPredictions: pickupPredictions ?? this.pickupPredictions,
      dropOffPredictions: dropOffPredictions ?? this.dropOffPredictions,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      currentRide: currentRide ?? this.currentRide,
      sheetHeight: sheetHeight ?? this.sheetHeight,
    );
  }
}

class RiderRequestScreen extends StatefulWidget {
  const RiderRequestScreen({super.key});
  @override
  State<RiderRequestScreen> createState() => _RiderRequestScreenState();
}

class _RiderRequestScreenState extends State<RiderRequestScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  final FirebaseService _fs = FirebaseService();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropoffController = TextEditingController();

  GoogleMapController? _mapController;
  final Location _location = Location();

  RiderRequestState _state = const RiderRequestState();
  StreamSubscription<LocationData>? _locationSubscription;
  final Map<String, StreamSubscription> _subscriptions = {};
  Timer? _searchDebounce;
  PersistentBottomSheetController? _bottomSheetController;
  final bool _isSheetDragging = false;

  // Add GlobalKey for the Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Constants
  static const List<Map<String, dynamic>> _vehicleTypes = [
    {"name": "Standard", "fareMultiplier": 1.0, "icon": Icons.directions_car},
    {"name": "Premium", "fareMultiplier": 1.5, "icon": Icons.local_taxi},
    {"name": "Van", "fareMultiplier": 2.0, "icon": Icons.airport_shuttle},
  ];
  static const String googleplacesKey =
      'AIzaSyDoo8xg8i1eajh9Ft8ioADZNo27BajyonQ';

  // Cache for map style
  static final String _mapStyle = _getMapStyle();

  // Helper method to check if user can book a new ride
  bool get _canBookRide {
    // Check if there's no current ride ID
    if (_state.currentRideId == null) return true;

    // If there's a current ride, check its status
    if (_state.currentRide != null) {
      // Only allow booking new ride if current ride is completed or cancelled
      final status = _state.currentRide!.status;
      return status == 'completed' || status == 'cancelled';
    }

    return true;
  }

  // Helper method to safely manage subscriptions
  void _subscribeToStream<T>(
      String key, Stream<T> stream, void Function(T) onData) {
    // Cancel existing subscription if any
    _subscriptions[key]?.cancel();

    // Create new subscription
    _subscriptions[key] = stream.listen(
      (data) {
        if (mounted) {
          onData(data);
        }
      },
      onError: (error) {
        debugPrint("Stream error for $key: $error");
        // Don't show snackbar if widget is disposed
        if (mounted) {
          _showSnackBar('Connection error');
        }
      },
      cancelOnError: true,
    );
  }

  // Helper method to safely show snackbars
  void _showSnackBar(String message) {
    if (mounted &&
        _scaffoldKey.currentState != null &&
        _scaffoldKey.currentState!.mounted) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Auto-select current location when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrentLocation();
    });

    _initLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseLocationUpdates();
    } else if (state == AppLifecycleState.resumed) {
      _resumeLocationUpdates();
      // Refresh location when app resumes
      _refreshCurrentLocation();
    }
  }

  void _pauseLocationUpdates() {
    _location.changeSettings(interval: 0);
    _locationSubscription?.pause();
  }

  void _resumeLocationUpdates() {
    _location.changeSettings(interval: 1000);
    _locationSubscription?.resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Properly dispose the map controller
    _mapController?.dispose();
    _mapController = null;

    pickupController.dispose();
    dropoffController.dispose();
    _locationSubscription?.cancel();

    // Cancel all subscriptions
    _subscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    _subscriptions.clear();

    // Cancel debounce timer
    _searchDebounce?.cancel();

    // Close bottom sheet if open
    _bottomSheetController?.close();

    super.dispose();
  }

  // Update state with a function and mounted check
  void _updateState(RiderRequestState newState) {
    if (mounted) {
      setState(() {
        _state = newState;
      });
    }
  }

  // Helper method to refresh current location
  Future<void> _refreshCurrentLocation() async {
    try {
      final LocationData locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final LatLng currentLatLng = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );

        final String? address = await _reverseGeocode(currentLatLng);

        _updateState(_state.copyWith(
          pickupLocation: currentLatLng,
        ));

        pickupController.text = address ?? 'Current Location';

        if (_mapController != null) {
          _animateToLocation(currentLatLng);
        }

        if (mounted) {
          _showSnackBar('Location updated');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating location: $e');
      }
    }
  }

  Future<void> _initLocation() async {
    try {
      final bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        final bool serviceRequested = await _location.requestService();
        if (!serviceRequested) {
          if (mounted) {
            _showSnackBar('Location service is required');
          }
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          if (mounted) {
            _showSnackBar('Location permission denied');
          }
          return;
        }
      }

      // Get initial location
      final LocationData loc = await _location.getLocation();
      if (loc.latitude == null || loc.longitude == null) {
        if (mounted) {
          _showSnackBar('Unable to get location');
        }
        return;
      }

      final LatLng initialLatLng = LatLng(loc.latitude!, loc.longitude!);
      final String? address = await _reverseGeocode(initialLatLng);

      _updateState(_state.copyWith(
        pickupLocation: initialLatLng,
      ));

      pickupController.text =
          address ?? '${initialLatLng.latitude}, ${initialLatLng.longitude}';

      if (_mapController != null) {
        _animateToLocation(initialLatLng);
      }

      // Listen for location updates
      _locationSubscription =
          _location.onLocationChanged.listen((LocationData locationData) {
        if (locationData.latitude != null &&
            locationData.longitude != null &&
            _mapController != null &&
            !_state.awaitingDropoff) {
          // Only update if user hasn't manually selected a different pickup
          if (_state.pickupLocation == null ||
              _state.pickupLocation!.latitude == loc.latitude) {
            final LatLng newLocation =
                LatLng(locationData.latitude!, locationData.longitude!);

            _updateState(_state.copyWith(
              pickupLocation: newLocation,
            ));

            // Update the map to follow user
            _mapController!.animateCamera(CameraUpdate.newLatLng(newLocation));
          }
        }
      }, onError: (error) {
        debugPrint("Location stream error: $error");
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Location error: $e');
      }
    }
  }

  static String _getMapStyle() {
    return '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.neighborhood",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#d0f0c0"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off",
         "color": "#767B91"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#767B91"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#767B91"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#457B9D"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]
''';
  }

  void _onMapCreated(GoogleMapController controller) {
    // Don't recreate if already exists
    if (_mapController != null) return;

    _mapController = controller;
    _mapController!.setMapStyle(_mapStyle);

    if (_state.pickupLocation != null) {
      _animateToLocation(_state.pickupLocation!);
    }
  }

  void _animateToLocation(LatLng location, {double zoom = 16}) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: zoom,
            bearing: 30,
            tilt: 45,
          ),
        ),
      );
    }
  }

  void _onTap(LatLng position) async {
    FocusScope.of(context).unfocus();

    // Prevent location changes when user cannot book a new ride
    if (!_canBookRide) {
      // If there's an active ride, show a message
      if (mounted) {
        _showSnackBar(
            'Cannot change locations during an active ride. Cancel the ride first if you need to change locations.');
      }
      return;
    }

    if (!_state.awaitingDropoff) {
      _updateState(_state.copyWith(
        pickupLocation: position,
        awaitingDropoff: true,
      ));

      final String? addr = await _reverseGeocode(position);
      if (addr != null) {
        pickupController.text = addr;
      }
    } else {
      _updateState(_state.copyWith(
        dropoffLocation: position,
        awaitingDropoff: false,
      ));

      final String? addr = await _reverseGeocode(position);
      if (addr != null) {
        dropoffController.text = addr;
      }
    }
  }

  void _listenToRide(String rideId) {
    if (rideId.isEmpty) return;

    // Cancel any existing subscription
    _subscriptions['ride_$rideId']?.cancel();

    _subscribeToStream<Ride?>(
      'ride_$rideId',
      _fs.streamRide(rideId),
      (ride) {
        if (!mounted || ride == null) return;

        debugPrint("RIDE STATUS UPDATED: ${ride.status} - ${ride.driverName}");

        // Store previous ride status for comparison
        final previousStatus = _state.currentRide?.status;

        _updateState(_state.copyWith(currentRide: ride));

        // Show or update the persistent bottom sheet
        if (ride.isRequested ||
            ride.isAccepted ||
            ride.isInProgress ||
            ride.isCompleted ||
            ride.isCancelled) {
          _showOrUpdatePersistentBottomSheet(ride);
        }

        // Update UI based on ride status
        if (ride.isCancelled) {
          _showSnackBar('Ride was cancelled');
          _resetRideState();
          _closePersistentBottomSheet();
        } else if (ride.isCompleted) {
          _completeRide();
          _closePersistentBottomSheet();
        } else if (ride.isAccepted || ride.isInProgress) {
          if (ride.driverId != null) {
            _listenToDriverLocation(ride.driverId!);
          }
        }
      },
    );
  }

  void _showOrUpdatePersistentBottomSheet(Ride ride) {
    if (_bottomSheetController != null) {
      // Bottom sheet is already showing, we need to rebuild it
      // Since we can't directly rebuild a PersistentBottomSheetController,
      // we'll close it and open a new one
      _bottomSheetController?.close();
      _bottomSheetController = null;

      // Small delay to ensure the old sheet is closed
      Future.delayed(Duration(milliseconds: 100), () {
        _showPersistentBottomSheet(ride);
      });
    } else {
      _showPersistentBottomSheet(ride);
    }
  }

  void _showPersistentBottomSheet(Ride ride) {
    if (!mounted) return;

    _bottomSheetController = _scaffoldKey.currentState?.showBottomSheet(
      (context) => _buildPersistentBottomSheet(ride),
      backgroundColor: Colors.transparent,
      elevation: 0,
      enableDrag: true,
    );

    // When the sheet is dismissed (by user dragging down)
    _bottomSheetController?.closed.then((value) {
      _bottomSheetController = null;
      // Only reset if ride is not active
      if (_state.currentRide != null) {
        final status = _state.currentRide!.status;
        if (status == 'completed' || status == 'cancelled') {
          _resetRideState();
        }
      }
    });
  }

  void _closePersistentBottomSheet() {
    _bottomSheetController?.close();
    _bottomSheetController = null;
  }

  Widget _buildPersistentBottomSheet(Ride ride) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      height: MediaQuery.of(context).size.height * _state.sheetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Modern Minimal Handle
          GestureDetector(
            onVerticalDragUpdate: (details) {
              final newHeight = _state.sheetHeight -
                  (details.delta.dy / MediaQuery.of(context).size.height);
              _updateState(
                  _state.copyWith(sheetHeight: newHeight.clamp(0.25, 0.9)));
            },
            child: Container(
              width: double.infinity,
              color: Colors.transparent, // Larger hit area
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildModernHeader(ride),
                  const SizedBox(height: 24),
                  _buildRideStatusContent(ride),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(Ride ride) {
    return Row(
      children: [
        if (ride.status == 'requested')
          _buildPulsingSearchIcon()
        else
          _buildStatusIcon(ride.status),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusTitle(ride.status),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              Text(
                _getStatusSubtitle(ride),
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (ride.status != 'completed' && ride.status != 'cancelled')
          Material(
            color: Colors.grey.shade100,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: () {
                if (mounted) {
                  _showCancelRideDialog();
                }
              },
              icon: const Icon(Icons.close, size: 20, color: Colors.black87),
            ),
          ),
      ],
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'requested':
        return 'Finding your ride';
      case 'accepted':
        return 'Driver is coming';
      case 'arrived':
        return 'Driver is here';
      case 'in_progress':
        return 'En route';
      case 'completed':
        return 'Arrived safely';
      case 'cancelled':
        return 'Ride cancelled';
      default:
        return 'Ride Status';
    }
  }

  String _getStatusSubtitle(Ride ride) {
    switch (ride.status) {
      case 'requested':
        return 'Connecting to nearby drivers...';
      case 'accepted':
        return 'Track driver on map';
      case 'arrived':
        return 'Driver is waiting for you';
      case 'in_progress':
        return 'Heading to ${ride.dropoff['address'] ?? 'destination'}';
      case 'completed':
        return 'Hope you had a great trip!';
      default:
        return 'Tap for more details';
    }
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color color;

    switch (status) {
      case 'accepted':
        iconData = Icons.directions_car_rounded;
        color = Colors.green;
        break;
      case 'arrived':
        iconData = Icons.location_on_rounded;
        color = Colors.blue;
        break;
      case 'in_progress':
        iconData = Icons.auto_awesome_motion_rounded; // Gives a "moving" feel
        color = Colors.indigo;
        break;
      case 'completed':
        iconData = Icons.task_alt_rounded;
        color = Colors.green;
        break;
      default:
        iconData = Icons.info_outline_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildPulsingSearchIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
      ),
    );
  }

  Widget _buildLocationInfo(Ride ride) {
    return IntrinsicHeight(
        child: Row(
      children: [
        Column(
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.blue),
            Expanded(
              child: Container(
                width: 1.5,
                color: Colors.grey.shade200,
              ),
            ),
            const Icon(Icons.square, size: 8, color: Colors.black),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.pickup['address'] ?? 'Pickup',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                ride.dropoff['address'] ?? 'Destination',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildStatusHeader(Ride ride) {
    // Initialize with default values
    IconData icon = Icons.info;
    Color color = Colors.grey;
    String text = 'Ride Status';
    String subtitle = '';

    switch (ride.status) {
      case 'requested':
        icon = Icons.search;
        color = Colors.orange;
        text = 'Finding a Driver';
        subtitle = 'Searching nearby drivers...';
        break;
      case 'accepted':
        icon = Icons.directions_car;
        color = Colors.green;
        text = 'Driver On The Way';
        subtitle = 'Track driver on map';
        break;
      case 'arrived':
        icon = Icons.location_on;
        color = Colors.blue;
        text = 'Driver Arrived';
        subtitle =
            'Tap to ${_isSheetDragging || _state.sheetHeight > 0.3 ? 'collapse' : 'expand'}';
        break;
      case 'in_progress':
        icon = Icons.directions_car;
        color = Colors.purple;
        text = 'Trip in Progress';
        subtitle =
            'Tap to ${_isSheetDragging || _state.sheetHeight > 0.3 ? 'collapse' : 'expand'}';
        break;
      case 'completed':
        icon = Icons.done_all;
        color = Colors.green;
        text = 'Trip Completed';
        subtitle =
            'Tap to ${_isSheetDragging || _state.sheetHeight > 0.3 ? 'collapse' : 'expand'}';
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        text = 'Ride Cancelled';
        subtitle =
            'Tap to ${_isSheetDragging || _state.sheetHeight > 0.3 ? 'collapse' : 'expand'}';
        break;
      default:
        // Already initialized with defaults above
        subtitle =
            'Tap to ${_isSheetDragging || _state.sheetHeight > 0.3 ? 'collapse' : 'expand'}';
        break;
    }

    return Row(
      children: [
        // Animated icon for searching
        if (ride.status == 'requested')
          _buildAnimatedSearchIcon()
        else
          Icon(icon, color: color, size: 24),

        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

// Add animated search icon
  Widget _buildAnimatedSearchIcon() {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.linear,
        ),
      ),
      child: const Icon(Icons.search, color: Colors.orange, size: 24),
    );
  }

  Widget _buildRideStatusContent(Ride ride) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        _buildProgressIndicator(ride.status),

        const SizedBox(height: 16),

        // Driver tracking info for accepted rides
        if (ride.status == 'accepted') _buildDriverTrackingInfo(),

        const SizedBox(height: 16),

        // Pickup and dropoff info
        _buildLocationInfo(ride),

        const SizedBox(height: 20),

        // Fare info
        _buildFareInfo(ride),

        const SizedBox(height: 20),

        // Driver info (if available)
        if (ride.driverName != null || ride.driverPhone != null)
          _buildDriverInfo(ride),

        const SizedBox(height: 20),

        // Status-specific content
        _buildStatusSpecificContent(ride),

        const SizedBox(height: 20),

        // Cancel button (if applicable)
        if (ride.status != 'completed' && ride.status != 'cancelled')
          _buildCancelButton(),
      ],
    );
  }

  // Add driver tracking info widget
  Widget _buildDriverTrackingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.directions_car, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Driver Tracking',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Watch your driver\'s car move on the map',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(Ride ride) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ride.driverName ?? "Driver",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text("4.9 ★ • Toyota Corolla",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        _buildCircularIconButton(Icons.phone, Colors.green, () {}),
        const SizedBox(width: 8),
        _buildCircularIconButton(Icons.message, Colors.blue, () {}),
      ],
    );
  }

  Widget _buildProgressIndicator(String status) {
    final steps = [
      'requested', // Step 1: Searching for driver
      'accepted', // Step 2: Driver found
      'arrived', // Step 3: Driver arrived
      'in_progress', // Step 4: Trip started
      'completed' // Step 5: Trip completed
    ];

    final currentIndex = steps.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Trip Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Responsive layout using Wrap
        Wrap(
          spacing: 8, // Horizontal space between items
          runSpacing: 16, // Vertical space between lines
          alignment: WrapAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            bool isActive = index <= currentIndex;
            bool isLast = index == steps.length - 1;

            return SizedBox(
              width: 60, // Fixed width for each step
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circle with number
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? Colors.blue : Colors.grey.shade300,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Label
                  Text(
                    _getStepLabel(steps[index]),
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.blue : Colors.grey,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),

                  // Connector line (except for last item)
                  if (!isLast &&
                      index % 2 == 0) // Only show connectors on first row
                    Positioned(
                      right: -10,
                      top: 18,
                      child: Container(
                        width: 20,
                        height: 2,
                        color: isActive ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),

        // OR use this alternative: Simple horizontal line at bottom
        Container(
          height: 2,
          margin: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.grey.shade300,
          child: FractionallySizedBox(
            widthFactor: (currentIndex + 1) / steps.length,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 2,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  String _getStepLabel(String step) {
    switch (step) {
      case 'requested':
        return 'Requested';
      case 'accepted':
        return 'Accepted';
      case 'arrived':
        return 'Arrived';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return '';
    }
  }

  Widget _buildCircularIconButton(
      IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      shape: const CircleBorder(),
      child: IconButton(
          onPressed: onTap, icon: Icon(icon, color: color, size: 20)),
    );
  }

  Widget _buildFareInfo(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Total Fare",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xff000000))),
          Text(
            "E${ride.fare.toStringAsFixed(2)}",
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSpecificContent(Ride ride) {
    switch (ride.status) {
      case 'requested':
        return Column(
          children: [
            // Animated search icon
            _buildSearchingAnimation(),
            const SizedBox(height: 16),
            const Text(
              'Searching for available drivers...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            // Search status details
            _buildSearchDetails(),

            const SizedBox(height: 16),

            // Estimated time card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Estimated Wait Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '2-5 minutes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Finding the nearest available driver',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            _buildCancelButton(),
          ],
        );
      case 'accepted':
        return Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Driver Accepted Your Ride!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your driver is on the way to the pickup location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Driver location tracking info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_car,
                            size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Live Driver Tracking',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Watch your driver\'s car move on the map',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Real-time Updates',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 'arrived':
        return Column(
          children: [
            const Icon(
              Icons.location_on,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Driver Has Arrived!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please proceed to the pickup location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'Have your payment ready: E cash only',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      case 'in_progress':
        return Column(
          children: [
            const Icon(
              Icons.directions_car,
              size: 48,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            const Text(
              'Enjoy Your Ride!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your trip is currently in progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'Payment Reminder',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please have E${ride.fare.toStringAsFixed(2) ?? '0.00'} cash ready',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'completed':
        return Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Trip Completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for riding with us',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _resetRideState();
                _closePersistentBottomSheet();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Book Another Ride'),
            ),
          ],
        );
      case 'cancelled':
        return Column(
          children: [
            const Icon(
              Icons.cancel,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ride Cancelled',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ride.cancellationReason ?? 'The ride was cancelled',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _resetRideState();
                _closePersistentBottomSheet();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

// Add this new method for the search animation
  Widget _buildSearchingAnimation() {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 1500),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),

          // Middle pulsing circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 1500),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.4),
            ),
          ),

          // Inner search icon
          const Icon(
            Icons.search,
            size: 30,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

// Add search details widget
  Widget _buildSearchDetails() {
    return Card(
      color: Color(0xfffbfbfb),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xff000000),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Finding drivers near your pickup location',
                    style: TextStyle(fontSize: 13, color: Color(0xff000000)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Matching with suitable vehicle type',
                    style: TextStyle(fontSize: 13, color: Color(0xff000000)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Checking driver availability',
                    style: TextStyle(fontSize: 13, color: Color(0xff000000)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton(
      onPressed: () {
        if (mounted) {
          _showCancelRideDialog();
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: Colors.red),
      ),
      child: const Text(
        'Cancel Ride',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Future<void> _showCancelRideDialog() async {
    // Check if widget is still mounted
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    // Check if widget is still mounted and user confirmed cancellation
    if (mounted && result == true) {
      try {
        await _fs.cancelRide(
          rideId: _state.currentRideId!,
          reason: 'Cancelled by rider',
          cancelledBy: 'rider',
        );
        _resetRideState();
        _closePersistentBottomSheet();
        _showSnackBar('Ride cancelled');
      } catch (e) {
        _showSnackBar('Error cancelling ride: $e');
      }
    }
  }

  void _listenToDriverLocation(String driverId) {
    if (driverId.isEmpty) return;

    // Cancel any existing subscription for this driver
    _subscriptions['driver_$driverId']?.cancel();

    _subscribeToStream<Map<String, dynamic>?>(
      'driver_$driverId',
      _fs.streamDriverLocation(driverId),
      (location) {
        if (!mounted || location == null) return;

        debugPrint(
            "DRIVER LOCATION UPDATED: ${location['lat']}, ${location['lng']}");

        final LatLng driverLoc = LatLng(location['lat'], location['lng']);
        _updateState(_state.copyWith(driverLocation: driverLoc));

        // Animate to driver location when they're moving
        if (_mapController != null &&
            _state.currentRide?.status == 'accepted') {
          // Smooth animation to follow driver
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(driverLoc),
          );
        }
      },
    );
  }

  Future<void> searchPlace(String userInput, {required bool isPickup}) async {
    List<PlacePredictionModel> predictions = [];

    // Always add current location as first option for pickup searches
    if (isPickup) {
      try {
        final LocationData locationData = await _location.getLocation();
        if (locationData.latitude != null && locationData.longitude != null) {
          final LatLng currentLatLng = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );

          final String? currentAddress = await _reverseGeocode(currentLatLng);

          predictions.add(PlacePredictionModel(
            mainText: "Current Location",
            secondaryText: currentAddress ?? 'Your current position',
            isCurrentLocation: true,
          ));
        }
      } catch (e) {
        debugPrint("Error getting current location for search: $e");
      }
    }

    if (userInput.isEmpty) {
      if (mounted) {
        _updateState(isPickup
            ? _state.copyWith(pickupPredictions: predictions)
            : _state.copyWith(dropOffPredictions: predictions));
      }
      return;
    }

    if (userInput.length > 1) {
      final String placesAPIUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=$userInput&key=$googleplacesKey&components=country:SZ"
          "&location=${_state.pickupLocation?.latitude ?? -26.2041},${_state.pickupLocation?.longitude ?? 28.0473}"
          "&radius=50000";

      try {
        final dynamic responseFromPlacesAPI =
            await GoogleMapMethods.sendRequestToAPI(placesAPIUrl, context);

        if (responseFromPlacesAPI == 'error') return;

        if (responseFromPlacesAPI['status'] == 'OK') {
          // Add Google Places results
          final List<dynamic> placesData =
              responseFromPlacesAPI['predictions'] ?? [];
          for (var placeData in placesData) {
            try {
              final prediction = PlacePredictionModel.fromJson(placeData);
              predictions.add(prediction);
            } catch (e) {
              debugPrint("Error parsing place prediction: $e");
            }
          }

          if (mounted) {
            _updateState(isPickup
                ? _state.copyWith(pickupPredictions: predictions)
                : _state.copyWith(dropOffPredictions: predictions));
          }
        } else if (responseFromPlacesAPI['status'] == 'ZERO_RESULTS') {
          if (mounted) {
            _updateState(isPickup
                ? _state.copyWith(pickupPredictions: predictions)
                : _state.copyWith(dropOffPredictions: predictions));
          }
        }
      } catch (e) {
        debugPrint("Error searching places: $e");
        if (mounted) {
          _updateState(isPickup
              ? _state.copyWith(pickupPredictions: predictions)
              : _state.copyWith(dropOffPredictions: predictions));
        }
      }
    } else {
      if (mounted) {
        _updateState(isPickup
            ? _state.copyWith(pickupPredictions: predictions)
            : _state.copyWith(dropOffPredictions: predictions));
      }
    }
  }

  Widget _buildPredictionList(List<PlacePredictionModel> predictions,
      {required bool isPickup}) {
    if (predictions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: predictions.length,
        itemBuilder: (BuildContext context, int index) {
          final prediction = predictions[index];
          return Container(
            decoration: BoxDecoration(
              border: index < predictions.length - 1
                  ? Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade200, width: 0.5))
                  : null,
            ),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: Icon(
                prediction.isCurrentLocation
                    ? Icons.my_location
                    : Icons.location_on,
                color: prediction.isCurrentLocation
                    ? Colors.blue
                    : Colors.deepPurple,
                size: 18,
              ),
              title: Text(
                prediction.mainText ?? "",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
              subtitle: prediction.secondaryText != null
                  ? Text(
                      prediction.secondaryText!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    )
                  : null,
              onTap: () async {
                FocusScope.of(context).unfocus();

                // Prevent location changes when user cannot book a new ride
                if (!_canBookRide) {
                  // If there's an active ride, show a message
                  if (mounted) {
                    _showSnackBar(
                        'Cannot change locations during an active ride. Cancel the ride first if you need to change locations.');
                  }
                  return;
                }

                if (prediction.isCurrentLocation) {
                  // Handle current location selection
                  if (isPickup) {
                    try {
                      // Get fresh current location
                      final LocationData locationData =
                          await _location.getLocation();
                      if (locationData.latitude != null &&
                          locationData.longitude != null) {
                        final LatLng currentLatLng = LatLng(
                          locationData.latitude!,
                          locationData.longitude!,
                        );

                        // Update pickup location
                        _updateState(_state.copyWith(
                          pickupLocation: currentLatLng,
                          pickupPredictions: [],
                        ));

                        // Get address for display
                        final String? address =
                            await _reverseGeocode(currentLatLng);
                        pickupController.text = address ?? 'Current Location';

                        // Animate to location
                        _animateToLocation(currentLatLng);
                      }
                    } catch (e) {
                      _showSnackBar('Error getting current location: $e');
                    }
                  } else {
                    try {
                      // Get fresh current location for dropoff
                      final LocationData locationData =
                          await _location.getLocation();
                      if (locationData.latitude != null &&
                          locationData.longitude != null) {
                        final LatLng currentLatLng = LatLng(
                          locationData.latitude!,
                          locationData.longitude!,
                        );

                        // Update dropoff location
                        _updateState(_state.copyWith(
                          dropoffLocation: currentLatLng,
                          dropOffPredictions: [],
                        ));

                        // Get address for display
                        final String? address =
                            await _reverseGeocode(currentLatLng);
                        dropoffController.text = address ?? 'Current Location';

                        // Animate to location
                        _animateToLocation(currentLatLng);
                      }
                    } catch (e) {
                      _showSnackBar('Error getting current location: $e');
                    }
                  }
                } else {
                  final fullText = prediction.secondaryText != null
                      ? "${prediction.mainText}, ${prediction.secondaryText}"
                      : prediction.mainText ?? "";

                  if (isPickup) {
                    pickupController.text = fullText;
                    _updateState(_state.copyWith(pickupPredictions: []));
                  } else {
                    dropoffController.text = fullText;
                    _updateState(_state.copyWith(dropOffPredictions: []));
                  }

                  final LatLng? coords = await _geocodeAddress(fullText);
                  if (coords != null) {
                    _updateState(isPickup
                        ? _state.copyWith(pickupLocation: coords)
                        : _state.copyWith(dropoffLocation: coords));
                    _animateToLocation(coords);
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  void onPickupSearchChanged(String text) {
    // Prevent search when user cannot book a new ride
    if (!_canBookRide) return;

    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(text, isPickup: true);
    });
  }

  void onDropoffSearchChanged(String text) {
    // Prevent search when user cannot book a new ride
    if (!_canBookRide) return;

    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(text, isPickup: false);
    });
  }

  Future<void> _confirmRideWithVehicle(Map<String, dynamic> vehicleType) async {
    FocusScope.of(context).unfocus();

    if (_state.pickupLocation == null || _state.dropoffLocation == null) {
      _showSnackBar('Please select both locations');
      return;
    }

    // Show cash payment confirmation dialog
    _showCashPaymentDialog(vehicleType);
  }

  Future<void> _createRideRequest(Map<String, dynamic> vehicleType) async {
    // Hide keyboard when confirming ride
    FocusScope.of(context).unfocus();

    _updateState(_state.copyWith(requesting: true));

    final Map<String, double> pickup = {
      'lat': _state.pickupLocation!.latitude,
      'lng': _state.pickupLocation!.longitude
    };
    final Map<String, double> dropoff = {
      'lat': _state.dropoffLocation!.latitude,
      'lng': _state.dropoffLocation!.longitude
    };

    final double baseFare = simpleFare(
      _state.pickupLocation!,
      _state.dropoffLocation!,
    );

    final double fare = baseFare * (vehicleType["fareMultiplier"] as double);

    try {
      final String id = await _fs.createRideRequest(
        riderId: 'guest_${Uuid().v4()}', // Add rider ID
        pickup: pickup,
        dropoff: dropoff,
        fare: fare,
        vehicleType: vehicleType["name"] as String,
        context: context,
      );

      _updateState(_state.copyWith(
        currentRideId: id,
        fare: fare,
        requesting: false,
      ));

      // Start listening to ride updates
      _listenToRide(id);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error creating ride: $e');
      }
      _updateState(_state.copyWith(requesting: false));
    }
  }

  Future<void> _completeRide() async {
    if (_state.currentRideId == null) return;

    try {
      await _fs.completeRide(rideId: _state.currentRideId!);
      _resetRideState();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error completing ride: $e');
      }
    }
  }

  void _resetRideState() {
    _updateState(_state.copyWith(
      currentRideId: null,
      currentRide: null,
      isPaymentCompleted: false,
      isPaymentProcessing: false,
      driverLocation: null,
      sheetHeight: 0.3,
    ));

    // Cancel ride and driver subscriptions
    _subscriptions['ride_${_state.currentRideId}']?.cancel();
    _subscriptions.remove('ride_${_state.currentRideId}');
    _subscriptions.removeWhere((key, _) => key.startsWith('driver_'));

    // Reset pickup and dropoff
    dropoffController.clear();
    _updateState(_state.copyWith(
      dropoffLocation: null,
      awaitingDropoff: false,
    ));
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final List<geocoding.Location> results =
          await geocoding.locationFromAddress(address);
      if (results.isNotEmpty) {
        return LatLng(results.first.latitude, results.first.longitude);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error finding location: $e');
      }
    }
    return null;
  }

  Future<String?> _reverseGeocode(LatLng position) async {
    try {
      final List<geocoding.Placemark> results =
          await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (results.isNotEmpty) {
        final geocoding.Placemark place = results.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
    return null;
  }

  void _showVehicleSelectionSheet() {
    if (_state.pickupLocation == null || _state.dropoffLocation == null) {
      _showSnackBar('Please select both pickup and dropoff locations');
      return;
    }

    final double baseFare = simpleFare(
      _state.pickupLocation!,
      _state.dropoffLocation!,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Vehicle Type",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 16),
              ..._vehicleTypes.map((Map<String, dynamic> type) {
                final double fare =
                    baseFare * (type["fareMultiplier"] as double);
                return ListTile(
                  leading:
                      Icon(type["icon"] as IconData, color: Colors.black87),
                  title: Text(type["name"] as String),
                  subtitle: Text('E${fare.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmRideWithVehicle(type);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showCashPaymentDialog(Map<String, dynamic> vehicleType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final double fare = simpleFare(
              _state.pickupLocation!,
              _state.dropoffLocation!,
            ) *
            (vehicleType["fareMultiplier"] as double);

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.money, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Cash only',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please note:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• All rides are cash-only payments'),
              const SizedBox(height: 4),
              const Text('• Please have exact cash ready'),
              const SizedBox(height: 4),
              const Text('• Driver will collect payment at end of trip'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estimated fare: E${fare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
                _createRideRequest(vehicleType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Confirm & Book Ride'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Use the separate widget for the map
          GoogleMapWidget(
            onMapCreated: _onMapCreated,
            onTap: _onTap,
            pickupLocation: _state.pickupLocation,
            dropoffLocation: _state.dropoffLocation,
            driverLocation: _state.driverLocation,
            bottomPadding: _state.currentRideId != null ? 200 : 100,
            isInteractive: _canBookRide,
          ),
          // Location refresh button
          Positioned(
            top: MediaQuery.of(context).padding.top + 180,
            right: 20,
            child: FloatingActionButton.small(
              onPressed: _refreshCurrentLocation,
              backgroundColor: Colors.white,
              child:
                  const Icon(Icons.my_location, color: Colors.blue, size: 20),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: pickupController,
                      decoration: InputDecoration(
                        labelText: 'Pickup location',
                        hintText: 'Where are you?',
                        prefixIcon: const Icon(Icons.location_on,
                            color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: onPickupSearchChanged,
                      readOnly: !_canBookRide,
                    ),
                    if (_state.pickupPredictions.isNotEmpty)
                      _buildPredictionList(_state.pickupPredictions,
                          isPickup: true),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dropoffController,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        hintText: 'Where to?',
                        prefixIcon: const Icon(Icons.flag, color: Colors.red),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: onDropoffSearchChanged,
                      readOnly: !_canBookRide,
                    ),
                    if (_state.dropOffPredictions.isNotEmpty)
                      _buildPredictionList(_state.dropOffPredictions,
                          isPickup: false),
                  ],
                ),
              ),
            ),
          ),
          // Show Confirm Ride button only when user can book a ride
          if (_canBookRide)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    RainbowButton(
                      backgroundColor: Colors.deepPurple,
                      onPressed: _state.requesting
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();
                              if (_state.pickupLocation == null ||
                                  _state.dropoffLocation == null) {
                                _showSnackBar(
                                    'Please select both pickup and dropoff locations');
                                return;
                              }
                              _showVehicleSelectionSheet();
                            },
                      child: _state.requesting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Ride',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
