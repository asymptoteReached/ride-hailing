import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Ride {
  final String id;
  final String riderId;
  final String? riderName;
  final String? riderPhone;
  final bool isGuest;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final String status;
  final double fare;
  final String vehicleType;
  final String paymentStatus;
  final double? companyCut;
  final double? driverCut;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final String? paymentRequestId;
  final String? paymentProvider;
  final DateTime? paymentRequestedAt;
  final DateTime? paymentConfirmedAt;
  final String? paymentProviderRef;
  final String? refundReason;
  final DateTime? refundedAt;
  final LatLng? driverLocation;

  Ride({
    required this.id,
    required this.riderId,
    this.riderName,
    this.riderPhone,
    this.isGuest = false,
    this.driverId,
    this.driverName,
    this.driverPhone,
    required this.pickup,
    required this.dropoff,
    required this.status,
    required this.fare,
    required this.vehicleType,
    required this.paymentStatus,
    this.companyCut,
    this.driverCut,
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    this.paymentRequestId,
    this.paymentProvider,
    this.paymentRequestedAt,
    this.paymentConfirmedAt,
    this.paymentProviderRef,
    this.refundReason,
    this.refundedAt,
    this.driverLocation,
  });

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] ?? '',
      riderId: map['riderId'] ?? '',
      riderName: map['riderName'],
      riderPhone: map['riderPhone'],
      isGuest: map['isGuest'] ?? false,
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      pickup: Map<String, dynamic>.from(map['pickup'] ?? {}),
      dropoff: Map<String, dynamic>.from(map['dropoff'] ?? {}),
      status: map['status'] ?? 'requested',
      fare: (map['fare'] ?? 0).toDouble(),
      vehicleType: map['vehicleType'] ?? 'Standard',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      companyCut: map['companyCut'] != null
          ? (map['companyCut'] as num).toDouble()
          : null,
      driverCut: map['driverCut'] != null
          ? (map['driverCut'] as num).toDouble()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? (map['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: map['cancellationReason'],
      cancelledBy: map['cancelledBy'],
      paymentRequestId: map['paymentRequestId'],
      paymentProvider: map['paymentProvider'],
      paymentRequestedAt: map['paymentRequestedAt'] != null
          ? (map['paymentRequestedAt'] as Timestamp).toDate()
          : null,
      paymentConfirmedAt: map['paymentConfirmedAt'] != null
          ? (map['paymentConfirmedAt'] as Timestamp).toDate()
          : null,
      paymentProviderRef: map['paymentProviderRef'],
      refundReason: map['refundReason'],
      refundedAt: map['refundedAt'] != null
          ? (map['refundedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory Ride.empty() {
    return Ride(
      id: '',
      riderId: '',
      pickup: {},
      dropoff: {},
      status: '',
      fare: 0.0,
      vehicleType: '',
      paymentStatus: '',
      isGuest: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'isGuest': isGuest,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'pickup': pickup,
      'dropoff': dropoff,
      'status': status,
      'fare': fare,
      'vehicleType': vehicleType,
      'paymentStatus': paymentStatus,
      'companyCut': companyCut,
      'driverCut': driverCut,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      'paymentRequestId': paymentRequestId,
      'paymentProvider': paymentProvider,
      'paymentRequestedAt': paymentRequestedAt != null
          ? Timestamp.fromDate(paymentRequestedAt!)
          : null,
      'paymentConfirmedAt': paymentConfirmedAt != null
          ? Timestamp.fromDate(paymentConfirmedAt!)
          : null,
      'paymentProviderRef': paymentProviderRef,
      'refundReason': refundReason,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
    };
  }

  bool get isRequested => status == 'requested';
  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
