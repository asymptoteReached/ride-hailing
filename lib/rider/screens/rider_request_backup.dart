// import 'package:eats/MoMo/momo_payment_screen.dart';
// import 'package:eats/models/place_prediction_model.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';
// import 'package:eats/services/firebase_service.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'package:eats/widgets/fare_calculation.dart';
// import 'package:eats/widgets/rotating_gradient_border.dart';
// import 'dart:ui';
// import 'package:eats/utils/common_methods.dart';
// import 'dart:async';
// import 'package:eats/widgets/google_map_methods.dart';

// // State management class
// class RiderRequestState {
//   final String? currentRideId;
//   final LatLng? pickupLocation;
//   final LatLng? dropoffLocation;
//   final LatLng? driverLocation;
//   final double? fare;
//   final bool awaitingDropoff;
//   final bool requesting;
//   final bool isPaymentProcessing;
//   final bool isPaymentCompleted;
//   final bool isModalShown;
//   final List<PlacePredictionModel> dropOffPredictions;

//   const RiderRequestState({
//     this.currentRideId,
//     this.pickupLocation,
//     this.dropoffLocation,
//     this.driverLocation,
//     this.fare,
//     this.awaitingDropoff = false,
//     this.requesting = false,
//     this.isPaymentProcessing = false,
//     this.isPaymentCompleted = false,
//     this.isModalShown = false,
//     this.dropOffPredictions = const [],
//   });

//   RiderRequestState copyWith({
//     String? currentRideId,
//     LatLng? pickupLocation,
//     LatLng? dropoffLocation,
//     LatLng? driverLocation,
//     double? fare,
//     bool? awaitingDropoff,
//     bool? requesting,
//     bool? isPaymentProcessing,
//     bool? isPaymentCompleted,
//     bool? isModalShown,
//     List<PlacePredictionModel>? dropOffPredictions,
//   }) {
//     return RiderRequestState(
//       currentRideId: currentRideId ?? this.currentRideId,
//       pickupLocation: pickupLocation ?? this.pickupLocation,
//       dropoffLocation: dropoffLocation ?? this.dropoffLocation,
//       driverLocation: driverLocation ?? this.driverLocation,
//       fare: fare ?? this.fare,
//       awaitingDropoff: awaitingDropoff ?? this.awaitingDropoff,
//       requesting: requesting ?? this.requesting,
//       isPaymentProcessing: isPaymentProcessing ?? this.isPaymentProcessing,
//       isPaymentCompleted: isPaymentCompleted ?? this.isPaymentCompleted,
//       isModalShown: isModalShown ?? this.isModalShown,
//       dropOffPredictions: dropOffPredictions ?? this.dropOffPredictions,
//     );
//   }
// }

// class RiderRequestScreen extends StatefulWidget {
//   const RiderRequestScreen({super.key});
//   @override
//   State<RiderRequestScreen> createState() => _RiderRequestScreenState();
// }

// class _RiderRequestScreenState extends State<RiderRequestScreen>
//     with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
//   @override
//   bool get wantKeepAlive => true;

//   final FirebaseService _fs = FirebaseService();
//   final TextEditingController pickupController = TextEditingController();
//   final TextEditingController dropoffController = TextEditingController();
//   GoogleMapController? _mapController;
//   final Location _location = Location();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   RiderRequestState _state = const RiderRequestState();
//   StreamSubscription<LocationData>? _locationSubscription;
//   StreamSubscription? _rideSubscription;
//   StreamSubscription? _driverLocationSubscription;

//   // Constants
//   final List<Map<String, dynamic>> _vehicleTypes = [
//     {"name": "Standard", "fareMultiplier": 1.0, "icon": Icons.directions_car},
//     {"name": "Premium", "fareMultiplier": 1.5, "icon": Icons.local_taxi},
//     {"name": "Van", "fareMultiplier": 2.0, "icon": Icons.airport_shuttle},
//   ];
//   final String googleplacesKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initLocation();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       _location.changeSettings(interval: 0);
//       _locationSubscription?.pause();
//     } else if (state == AppLifecycleState.resumed) {
//       _location.changeSettings(interval: 1000);
//       _locationSubscription?.resume();
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _mapController?.dispose();
//     pickupController.dispose();
//     dropoffController.dispose();
//     _locationSubscription?.cancel();
//     _rideSubscription?.cancel();
//     _driverLocationSubscription?.cancel();
//     super.dispose();
//   }

//   // Update state with a function
//   void _updateState(RiderRequestState newState) {
//     if (mounted) {
//       setState(() {
//         _state = newState;
//       });
//     }
//   }

//   Future<void> _initLocation() async {
//     try {
//       bool serviceEnabled = await _location.serviceEnabled();
//       if (!serviceEnabled) {
//         serviceEnabled = await _location.requestService();
//         if (!serviceEnabled) {
//           CommonMethods.displaySnackBar(
//               'Location service is required', context);
//           return;
//         }
//       }

//       PermissionStatus permissionGranted = await _location.hasPermission();
//       if (permissionGranted == PermissionStatus.denied) {
//         permissionGranted = await _location.requestPermission();
//         if (permissionGranted != PermissionStatus.granted) {
//           CommonMethods.displaySnackBar('Location permission denied', context);
//           return;
//         }
//       }

//       final loc = await _location.getLocation();
//       if (loc.latitude == null || loc.longitude == null) {
//         CommonMethods.displaySnackBar('Unable to get location', context);
//         return;
//       }

//       final initialLatLng = LatLng(loc.latitude!, loc.longitude!);
//       String? address = await _reverseGeocode(initialLatLng);

//       _updateState(_state.copyWith(
//         pickupLocation: initialLatLng,
//       ));

//       pickupController.text = address ??
//           '${_state.pickupLocation!.latitude}, ${_state.pickupLocation!.longitude}';

//       if (_mapController != null && _state.pickupLocation != null) {
//         _animateToLocation(_state.pickupLocation!);
//       }

//       _locationSubscription =
//           _location.onLocationChanged.listen((locationData) {
//         if (locationData.latitude != null &&
//             locationData.longitude != null &&
//             _mapController != null &&
//             !_state.awaitingDropoff) {
//           final newLocation =
//               LatLng(locationData.latitude!, locationData.longitude!);
//           _mapController!.animateCamera(CameraUpdate.newLatLng(newLocation));
//         }
//       });
//     } catch (e) {
//       CommonMethods.displaySnackBar('Location error: $e', context);
//     }
//   }

//   String _getMapStyle() {
//     return '''
// [
//   {
//     "elementType": "geometry",
//     "stylers": [
//       {
//         "color": "#f5f5f5"
//       }
//     ]
//   },
//   {
//     "elementType": "labels.icon",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "elementType": "labels.text.fill",
//     "stylers": [
//       {
//         "color": "#616161"
//       }
//     ]
//   },
//   {
//     "elementType": "labels.text.stroke",
//     "stylers": [
//       {
//         "color": "#f5f5f5"
//       }
//     ]
//   },
//   {
//     "featureType": "administrative.land_parcel",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "featureType": "administrative.neighborhood",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "featureType": "poi",
//     "elementType": "geometry",
//     "stylers": [
//       {
//         "color": "#eeeeee"
//       }
//     ]
//   },
//   {
//     "featureType": "poi",
//     "elementType": "labels.text",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "featureType": "poi.park",
//     "elementType": "geometry",
//     "stylers": [
//       {
//         "color": "#d0f0c0"
//       }
//     ]
//   },
//   {
//     "featureType": "poi.park",
//     "elementType": "labels.text.fill",
//     "stylers": [
//       {
//         "color": "#9e9e9e"
//       }
//     ]
//   },
//   {
//     "featureType": "road",
//     "stylers": [
//       {
//         "visibility": "simplified"
//       }
//     ]
//   },
//   {
//     "featureType": "road",
//     "elementType": "geometry",
//     "stylers": [
//       {
//         "color": "#ffffff"
//       }
//     ]
//   },
//   {
//     "featureType": "road",
//     "elementType": "labels.icon",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "featureType": "road.arterial",
//     "elementType": "labels.text.fill",
//     "stylers": [
//       {
//         "color": "#757575"
//       }
//     ]
//   },
//   {
//     "featureType": "road.highway",
//     "elementType": "geometry",
//     "stylers": [
//       {
//         "color": "#dadada"
//       }
//     ]
//   },
//   {
//     "featureType": "road.highway",
//     "elementType": "labels.text.fill",
//     "stylers": [
//       {
//         "color": "#616161"
//       }
//     ]
//   },
//   {
//     "featureType": "road.local",
//     "elementType": "labels.text.fill",
//     "stylers": [
//       {
//         "color": "#9e9e9e"
//       }
//     ]
//   },
//   {
//     "featureType": "transit",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "featureType": "water",
//     "elementType": "geometry",
//     "stylers": [
//       {
//         "color": "#c9e6ff"
//       }
//     ]
//   },
//   {
//     "featureType": "water",
//     "elementType": "labels.text.fill",
//     "stylers": [
//       {
//         "color": "#9e9e9e"
//       }
//     ]
//   }
// ]
// ''';
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     _mapController!.setMapStyle(_getMapStyle());

//     if (_state.pickupLocation != null) {
//       _animateToLocation(_state.pickupLocation!);
//     }
//   }

//   void _animateToLocation(LatLng location, {double zoom = 16}) {
//     if (_mapController != null) {
//       _mapController!.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: location,
//             zoom: zoom,
//             bearing: 30,
//             tilt: 45,
//           ),
//         ),
//       );
//     }
//   }

//   void _onTap(LatLng position) async {
//     if (!_state.awaitingDropoff) {
//       _updateState(_state.copyWith(
//         pickupLocation: position,
//         awaitingDropoff: true,
//       ));

//       final addr = await _reverseGeocode(position);
//       if (addr != null) {
//         pickupController.text = addr;
//       }
//     } else {
//       _updateState(_state.copyWith(
//         dropoffLocation: position,
//         awaitingDropoff: false,
//       ));

//       final addr = await _reverseGeocode(position);
//       if (addr != null) {
//         dropoffController.text = addr;
//       }
//     }
//   }

//   Future<void> searchPlace(String userInput) async {
//     if (userInput.length > 1) {
//       String placesAPIUrl =
//           "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$userInput &key=$googleplacesKey&components=country:SZ";

//       try {
//         var responseFromPlacesAPI =
//             await GoogleMapMethods.sendRequestToAPI(placesAPIUrl, context);

//         if (responseFromPlacesAPI == 'error') {
//           return;
//         }

//         if (responseFromPlacesAPI['status'] == 'OK') {
//           var predictionResultInJson = responseFromPlacesAPI['predictions'];
//           var predictionResultInNormalFormat = (predictionResultInJson as List)
//               .map((eachPredictedPlace) =>
//                   PlacePredictionModel.fromJson(eachPredictedPlace))
//               .toList();

//           _updateState(_state.copyWith(
//             dropOffPredictions: predictionResultInNormalFormat,
//           ));
//         }
//       } catch (e) {
//         // Handle error silently or show a snackbar
//         debugPrint("Error searching places: $e");
//       }
//     } else {
//       _updateState(_state.copyWith(
//         dropOffPredictions: [],
//       ));
//     }
//   }

//   Set<Marker> _buildMarkers() {
//     final markers = <Marker>{};
//     if (_state.pickupLocation != null) {
//       markers.add(Marker(
//         markerId: const MarkerId('pickup'),
//         position: _state.pickupLocation!,
//         infoWindow: const InfoWindow(title: 'Pickup Location'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }
//     if (_state.dropoffLocation != null) {
//       markers.add(Marker(
//         markerId: const MarkerId('dropoff'),
//         position: _state.dropoffLocation!,
//         infoWindow: const InfoWindow(title: 'Destination'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }
//     if (_state.driverLocation != null) {
//       markers.add(Marker(
//         markerId: const MarkerId('driver'),
//         position: _state.driverLocation!,
//         infoWindow: const InfoWindow(title: 'Driver'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//       ));
//     }
//     return markers;
//   }

//   void _updateDriverLocation(LatLng newLocation) {
//     _updateState(_state.copyWith(
//       driverLocation: newLocation,
//     ));

//     if (_mapController != null) {
//       _mapController!.animateCamera(CameraUpdate.newLatLng(newLocation));
//     }
//   }

//   Future<void> _confirmRideWithVehicle(Map<String, dynamic> vehicleType) async {
//     if (_state.pickupLocation == null || _state.dropoffLocation == null) return;

//     final riderId = _auth.currentUser?.uid;
//     if (riderId == null) {
//       CommonMethods.displaySnackBar('You are not authenticated', context);
//       return;
//     }

//     _updateState(_state.copyWith(requesting: true));

//     final pickup = {
//       'lat': _state.pickupLocation!.latitude,
//       'lng': _state.pickupLocation!.longitude
//     };
//     final dropoff = {
//       'lat': _state.dropoffLocation!.latitude,
//       'lng': _state.dropoffLocation!.longitude
//     };

//     double baseFare = simpleFare(
//       _state.pickupLocation!,
//       _state.dropoffLocation!,
//     );

//     double fare = baseFare * vehicleType["fareMultiplier"];

//     try {
//       final id = await _fs.createRideRequest(
//         riderId: riderId,
//         pickup: pickup,
//         dropoff: dropoff,
//         fare: fare,
//         vehicleType: vehicleType["name"],
//       );

//       _updateState(_state.copyWith(
//         currentRideId: id,
//         fare: fare,
//         requesting: false,
//       ));

//       _showRideStatusModal();
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error creating ride: $e')));
//       _updateState(_state.copyWith(requesting: false));
//     }
//   }

//   Future<void> _completeRide() async {
//     if (_state.currentRideId == null) return;

//     try {
//       await _fs.completeRide(rideId: _state.currentRideId!);
//       _updateState(_state.copyWith(
//         currentRideId: null,
//         isPaymentCompleted: false,
//         isPaymentProcessing: false,
//       ));

//       Navigator.pop(context); // Close the modal
//     } catch (e) {
//       CommonMethods.displaySnackBar('Error completing ride: $e', context);
//     }
//   }

//   Future<LatLng?> _geocodeAddress(String address) async {
//     try {
//       final results = await geocoding.locationFromAddress(address);
//       if (results.isNotEmpty) {
//         return LatLng(results.first.latitude, results.first.longitude);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error finding location: $e')),
//       );
//     }
//     return null;
//   }

//   Future<String?> _reverseGeocode(LatLng position) async {
//     try {
//       final results = await geocoding.placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       if (results.isNotEmpty) {
//         final place = results.first;
//         return "${place.street}, ${place.locality}, ${place.country}";
//       }
//     } catch (e) {
//       debugPrint("Reverse geocoding error: $e");
//     }
//     return null;
//   }

//   void _showVehicleSelectionSheet() {
//     if (_state.pickupLocation == null || _state.dropoffLocation == null) {
//       CommonMethods.displaySnackBar(
//           'Please select both pickup and dropoff locations', context);
//       return;
//     }

//     String fare = _state.fare?.toStringAsFixed(2) ?? 'Price not Available';

//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "Choose Vehicle Type",
//                 style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black),
//               ),
//               const SizedBox(height: 16),
//               ..._vehicleTypes.map((type) {
//                 return ListTile(
//                   leading: Icon(type["icon"], color: Colors.black87),
//                   title: Text(type["name"]),
//                   subtitle: Text('E$fare'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _confirmRideWithVehicle(type);
//                   },
//                 );
//               }),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showRideStatusModal() {
//     if (_state.currentRideId == null || _state.isModalShown) return;

//     _updateState(_state.copyWith(isModalShown: true));

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => _RideStatusModal(
//         rideId: _state.currentRideId!,
//         fare: _state.fare,
//         fs: _fs,
//         onCompleteRide: _completeRide,
//         onPaymentSuccess: () {
//           _updateState(_state.copyWith(
//             isPaymentCompleted: true,
//             isPaymentProcessing: false,
//           ));
//         },
//         onPaymentError: (error) {
//           _updateState(_state.copyWith(
//             isPaymentProcessing: false,
//           ));
//           CommonMethods.displaySnackBar(error, context);
//         },
//         onPaymentProcessing: () {
//           _updateState(_state.copyWith(
//             isPaymentProcessing: true,
//           ));
//         },
//       ),
//     ).then((_) {
//       _updateState(_state.copyWith(isModalShown: false));
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return Scaffold(
//       body: Stack(
//         children: [
//           GoogleMap(
//             onMapCreated: _onMapCreated,
//             onTap: _onTap,
//             initialCameraPosition: CameraPosition(
//                 target:
//                     _state.pickupLocation ?? const LatLng(-26.2041, 28.0473),
//                 zoom: 14,
//                 bearing: 30,
//                 tilt: 45),
//             markers: _buildMarkers(),
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             compassEnabled: true,
//             mapToolbarEnabled: false,
//             buildingsEnabled: true,
//             rotateGesturesEnabled: true,
//             tiltGesturesEnabled: true,
//             zoomControlsEnabled: false,
//             padding: const EdgeInsets.only(
//               top: 150,
//               bottom: 100,
//             ),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 12,
//             left: 16,
//             right: 16,
//             child: Card(
//               elevation: 8,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 16,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     TextField(
//                       controller: pickupController,
//                       decoration: InputDecoration(
//                         labelText: 'Pickup location',
//                         hintText: 'Where are you?',
//                         prefixIcon:
//                             Icon(Icons.location_on, color: Colors.deepPurple),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey.shade50,
//                       ),
//                       onChanged: (value) async {
//                         if (value.isEmpty) {
//                           _updateState(_state.copyWith(pickupLocation: null));
//                           return;
//                         }
//                         final coords = await _geocodeAddress(value);
//                         if (coords != null) {
//                           _updateState(_state.copyWith(pickupLocation: coords));
//                           _animateToLocation(coords);
//                         }
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: dropoffController,
//                       decoration: InputDecoration(
//                         labelText: 'Destination',
//                         hintText: 'Where to?',
//                         prefixIcon: Icon(Icons.flag, color: Colors.red),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey.shade50,
//                       ),
//                       onChanged: (value) async {
//                         if (value.isEmpty) {
//                           _updateState(_state.copyWith(
//                             dropoffLocation: null,
//                             dropOffPredictions: [],
//                           ));
//                           return;
//                         }
//                         await searchPlace(value);
//                       },
//                     ),
//                     if (_state.dropOffPredictions.isNotEmpty)
//                       Container(
//                         margin: const EdgeInsets.only(top: 4),
//                         height: 200,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black26,
//                               blurRadius: 8,
//                               offset: Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: ListView.builder(
//                           itemCount: _state.dropOffPredictions.length,
//                           itemBuilder: (context, index) {
//                             final prediction = _state.dropOffPredictions[index];
//                             return ListTile(
//                               leading: Icon(Icons.location_on,
//                                   color: Colors.deepPurple),
//                               title: Text(prediction.main_text ?? ""),
//                               subtitle: Text(prediction.secondary_text ?? ""),
//                               onTap: () async {
//                                 dropoffController.text =
//                                     prediction.main_text ?? "";
//                                 _updateState(_state.copyWith(
//                                   dropOffPredictions: [],
//                                 ));

//                                 final coords = await _geocodeAddress(
//                                   "${prediction.main_text}, ${prediction.secondary_text}",
//                                 );
//                                 if (coords != null) {
//                                   _updateState(_state.copyWith(
//                                     dropoffLocation: coords,
//                                   ));
//                                   _animateToLocation(coords);
//                                 }
//                               },
//                             );
//                           },
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: MediaQuery.of(context).padding.bottom + 20,
//             left: 20,
//             right: 20,
//             child: RainbowButton(
//               backgroundColor: Colors.deepPurple,
//               onPressed: _state.requesting
//                   ? null
//                   : () async {
//                       if (_state.pickupLocation == null ||
//                           _state.dropoffLocation == null) {
//                         CommonMethods.displaySnackBar(
//                             'Please select both pickup and dropoff locations',
//                             context);
//                         return;
//                       }
//                       _showVehicleSelectionSheet();
//                     },
//               child: _state.requesting
//                   ? const SizedBox(
//                       height: 24,
//                       width: 24,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 3,
//                         color: Colors.white,
//                       ),
//                     )
//                   : const Text(
//                       'Confirm Ride',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: Colors.white,
//                       ),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Extracted modal widget for better state management
// class _RideStatusModal extends StatefulWidget {
//   final String rideId;
//   final double? fare;
//   final FirebaseService fs;
//   final VoidCallback onCompleteRide;
//   final VoidCallback onPaymentSuccess;
//   final Function(String) onPaymentError;
//   final VoidCallback onPaymentProcessing;

//   const _RideStatusModal({
//     required this.rideId,
//     required this.fare,
//     required this.fs,
//     required this.onCompleteRide,
//     required this.onPaymentSuccess,
//     required this.onPaymentError,
//     required this.onPaymentProcessing,
//   });

//   @override
//   __RideStatusModalState createState() => __RideStatusModalState();
// }

// class __RideStatusModalState extends State<_RideStatusModal> {
//   String? _driverId;
//   LatLng? _driverLocation;

//   @override
//   void initState() {
//     super.initState();
//     _listenToRideChanges();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void _listenToRideChanges() {
//     widget.fs.streamRide(widget.rideId).listen((ride) {
//       if (ride.driverId != null && ride.driverId != _driverId) {
//         setState(() {
//           _driverId = ride.driverId;
//         });

//         // Listen to driver location if driver is assigned
//         if (_driverId != null) {
//           widget.fs.streamDriverLocation(_driverId!).listen((location) {
//             if (mounted) {
//               setState(() {
//                 _driverLocation = LatLng(location?['lat'], location?['lng']);
//               });
//             }
//           });
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: widget.fs.streamRide(widget.rideId),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return _buildErrorCard(snapshot.error.toString());
//         }

//         if (!snapshot.hasData) {
//           return _buildFindingDriverCard();
//         }

//         final ride = snapshot.data!;
//         Widget content;

//         switch (ride.status) {
//           case 'requested':
//             content = _buildFindingDriverCard();
//             break;
//           case 'accepted':
//             content = _buildDriverAcceptedCard(ride.driverId!);
//             break;
//           case 'in_progress':
//             content = _buildInProgressCard();
//             break;
//           case 'completed':
//             content = _buildCompletedCard();
//             break;
//           default:
//             content = _buildFindingDriverCard();
//         }

//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: AnimatedSwitcher(
//             duration: Duration(milliseconds: 500),
//             switchInCurve: Curves.easeOut,
//             switchOutCurve: Curves.easeIn,
//             transitionBuilder: (child, animation) {
//               final offset = Tween<Offset>(
//                 begin: const Offset(0, 0.2),
//                 end: Offset.zero,
//               ).animate(animation);
//               return SlideTransition(
//                 position: offset,
//                 child: FadeTransition(opacity: animation, child: child),
//               );
//             },
//             layoutBuilder: (current, previous) =>
//                 Stack(alignment: Alignment.center, children: [
//               ...previous,
//               if (current != null) current,
//             ]),
//             child: content,
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildErrorCard(String error) => Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           color: Colors.white,
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.error, size: 40, color: Colors.red),
//               const SizedBox(height: 16),
//               Text(
//                 'Error: $error',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );

//   Widget _buildFindingDriverCard() => Container(
//         key: const ValueKey('requested'),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           gradient: LinearGradient(
//             colors: [
//               Colors.white.withOpacity(0.8),
//               Colors.white.withOpacity(0.6),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 12,
//               offset: Offset(0, 6),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.search, size: 40, color: Colors.deepPurple),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Finding a driver…',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   const CircularProgressIndicator(
//                     valueColor:
//                         AlwaysStoppedAnimation<Color>(Colors.deepPurple),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );

//   Widget _buildDriverAcceptedCard(String driverId) => Container(
//         key: const ValueKey('accepted'),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           gradient: LinearGradient(
//             colors: [
//               Colors.white.withOpacity(0.85),
//               Colors.white.withOpacity(0.65)
//             ],
//             begin: Alignment.topRight,
//             end: Alignment.bottomLeft,
//           ),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.directions_car,
//                           size: 30, color: Colors.deepPurple),
//                       const SizedBox(width: 12),
//                       Text(
//                         '$driverId has accepted',
//                         style: TextStyle(
//                             fontSize: 20, fontWeight: FontWeight.w600),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   _driverLocation != null
//                       ? Text(
//                           'On the way: ${_driverLocation!.latitude.toStringAsFixed(5)}, ${_driverLocation!.longitude.toStringAsFixed(5)}',
//                           style: TextStyle(color: Colors.black87),
//                         )
//                       : Text('Locating driver…',
//                           style: TextStyle(color: Colors.black54)),
//                   const SizedBox(height: 24),
//                   GestureDetector(
//                     onTap: _showPaymentModal,
//                     child: AnimatedContainer(
//                       duration: Duration(milliseconds: 300),
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 14, horizontal: 32),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.deepPurple, Colors.purpleAccent],
//                         ),
//                         borderRadius: BorderRadius.circular(30),
//                         boxShadow: [
//                           BoxShadow(
//                               color: Colors.purple.withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: Offset(0, 4)),
//                         ],
//                       ),
//                       child: Text(
//                         'Pay E${widget.fare?.toStringAsFixed(2) ?? "0.00"}',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );

//   Widget _buildInProgressCard() => Container(
//         key: const ValueKey('in_progress'),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           gradient: LinearGradient(
//             colors: [
//               Colors.white.withOpacity(0.9),
//               Colors.white.withOpacity(0.7)
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.directions_run,
//                       size: 40, color: Colors.deepPurple),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Ride in progress…',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 24),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pop(context);
//                       widget.onCompleteRide();
//                     },
//                     child: AnimatedContainer(
//                       duration: Duration(milliseconds: 300),
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 14, horizontal: 32),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.purpleAccent, Colors.deepPurple],
//                         ),
//                         borderRadius: BorderRadius.circular(30),
//                         boxShadow: [
//                           BoxShadow(
//                               color: Colors.purple.withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: Offset(0, 4)),
//                         ],
//                       ),
//                       child: Text(
//                         'Mark Complete',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );

//   Widget _buildCompletedCard() => Container(
//         key: const ValueKey('completed'),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           gradient: LinearGradient(
//             colors: [
//               Colors.white.withOpacity(0.95),
//               Colors.white.withOpacity(0.8)
//             ],
//             begin: Alignment.topRight,
//             end: Alignment.bottomLeft,
//           ),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.check, size: 50, color: Colors.deepPurple),
//                   const SizedBox(height: 16),
//                   Text('Ride Completed',
//                       style:
//                           TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
//                   const SizedBox(height: 24),
//                   GestureDetector(
//                     onTap: _showPaymentModal,
//                     child: AnimatedContainer(
//                       duration: Duration(milliseconds: 300),
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 14, horizontal: 32),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.deepPurple, Colors.purpleAccent],
//                         ),
//                         borderRadius: BorderRadius.circular(30),
//                         boxShadow: [
//                           BoxShadow(
//                               color: Colors.purple.withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: Offset(0, 4)),
//                         ],
//                       ),
//                       child: Text(
//                         'Pay Now',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );

//   void _showPaymentModal() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => MoMoPaymentScreen(
//         rideId: widget.rideId,
//         amount: widget.fare ?? 0.0,
//         onPaymentSuccess: widget.onPaymentSuccess,
//         onPaymentError: widget.onPaymentError,
//         onPaymentProcessing: widget.onPaymentProcessing,
//       ),
//     );
//   }
// }
