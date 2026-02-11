// State management class
import 'package:eats/models/place_prediction_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final bool showGuestInfoDialog;
  final List<PlacePredictionModel> pickupPredictions;
  final List<PlacePredictionModel> dropOffPredictions;
  final String? riderName;
  final String? riderPhone;

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
    this.showGuestInfoDialog = false,
    this.pickupPredictions = const [],
    this.dropOffPredictions = const [],
    this.riderName,
    this.riderPhone,
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
    bool? showGuestInfoDialog,
    List<PlacePredictionModel>? pickupPredictions,
    List<PlacePredictionModel>? dropOffPredictions,
    String? riderName,
    String? riderPhone,
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
      showGuestInfoDialog: showGuestInfoDialog ?? this.showGuestInfoDialog,
      pickupPredictions: pickupPredictions ?? this.pickupPredictions,
      dropOffPredictions: dropOffPredictions ?? this.dropOffPredictions,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
    );
  }
}
