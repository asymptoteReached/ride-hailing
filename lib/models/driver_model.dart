// models/driver_model.dart - UPDATED VERSION WITH GETTERS
import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? passwordHash;
  final String status;
  final String statusText;
  final bool isOnline;
  final bool isAvailable;
  final bool isVerified;
  final double rating;
  final int totalTrips;
  final double totalEarnings;
  final String carModel;
  final String licensePlate;
  final String licenseNumber;
  final String vehicleType;
  final String? color;
  final String city;
  final String country;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime joinedDate;
  final DateTime? lastLogin;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final List<Map<String, dynamic>> documents;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.passwordHash,
    required this.status,
    required this.isOnline,
    required this.isAvailable,
    required this.isVerified,
    required this.rating,
    required this.totalTrips,
    required this.totalEarnings,
    required this.carModel,
    required this.licensePlate,
    required this.licenseNumber,
    required this.vehicleType,
    this.color,
    required this.city,
    required this.country,
    this.profileImageUrl,
    required this.createdAt,
    required this.joinedDate,
    this.lastLogin,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.documents = const [],
  }) : statusText = _getStatusText(status);

  // Helper method to convert status to readable text
  static String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'active':
        return 'Active';
      case 'suspended':
        return 'Suspended';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  // Convenience getters for common checks
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isRejected => status == 'rejected';

  // Getter for display color based on status
  int get statusColor {
    switch (status) {
      case 'pending':
        return 0xFFFFA000; // Amber
      case 'active':
        return 0xFF4CAF50; // Green
      case 'suspended':
        return 0xFFF44336; // Red
      case 'rejected':
        return 0xFF9E9E9E; // Grey
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Factory method to create Driver from Firestore data
  factory Driver.fromMap(Map<String, dynamic> data) {
    try {
      // Handle rating conversion (Firestore might store as int)
      final dynamic ratingValue = data['rating'];
      double rating = 0.0;

      if (ratingValue != null) {
        if (ratingValue is int) {
          rating = ratingValue.toDouble();
        } else if (ratingValue is double) {
          rating = ratingValue;
        } else if (ratingValue is String) {
          rating = double.tryParse(ratingValue) ?? 0.0;
        }
      }

      // Handle totalEarnings conversion
      final dynamic earningsValue = data['totalEarnings'];
      double totalEarnings = 0.0;

      if (earningsValue != null) {
        if (earningsValue is int) {
          totalEarnings = earningsValue.toDouble();
        } else if (earningsValue is double) {
          totalEarnings = earningsValue;
        } else if (earningsValue is String) {
          totalEarnings = double.tryParse(earningsValue) ?? 0.0;
        }
      }

      // Handle totalTrips conversion
      final dynamic tripsValue = data['totalTrips'];
      int totalTrips = 0;

      if (tripsValue != null) {
        if (tripsValue is int) {
          totalTrips = tripsValue;
        } else if (tripsValue is String) {
          totalTrips = int.tryParse(tripsValue) ?? 0;
        }
      }

      // Handle Timestamp conversions
      DateTime parseTimestamp(dynamic timestamp) {
        if (timestamp == null) return DateTime.now();
        if (timestamp is Timestamp) return timestamp.toDate();
        if (timestamp is DateTime) return timestamp;
        if (timestamp is String) {
          return DateTime.tryParse(timestamp) ?? DateTime.now();
        }
        if (timestamp is int) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
        return DateTime.now();
      }

      // Handle documents list
      final dynamic docsValue = data['documents'];
      List<Map<String, dynamic>> documents = [];

      if (docsValue is List) {
        for (var item in docsValue) {
          if (item is Map<String, dynamic>) {
            documents.add(item);
          }
        }
      }

      // Handle boolean fields with null safety
      bool parseBool(dynamic value) {
        if (value == null) return false;
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        if (value is int) return value == 1;
        return false;
      }

      return Driver(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        passwordHash: data['passwordHash']?.toString(),
        status: data['status']?.toString() ?? 'pending',
        isOnline: parseBool(data['isOnline']),
        isAvailable: parseBool(data['isAvailable']),
        isVerified: parseBool(data['isVerified']),
        rating: rating,
        totalTrips: totalTrips,
        totalEarnings: totalEarnings,
        carModel: data['carModel']?.toString() ?? '',
        licensePlate: data['licensePlate']?.toString() ?? '',
        licenseNumber: data['licenseNumber']?.toString() ?? '',
        vehicleType: data['vehicleType']?.toString() ?? 'car',
        color: data['color']?.toString(),
        city: data['city']?.toString() ?? '',
        country: data['country']?.toString() ?? '',
        profileImageUrl: data['profileImageUrl']?.toString(),
        createdAt: parseTimestamp(data['createdAt']),
        joinedDate: parseTimestamp(data['joinedDate']),
        lastLogin: data['lastLogin'] != null
            ? parseTimestamp(data['lastLogin'])
            : null,
        verifiedAt: data['verifiedAt'] != null
            ? parseTimestamp(data['verifiedAt'])
            : null,
        verifiedBy: data['verifiedBy']?.toString(),
        rejectionReason: data['rejectionReason']?.toString(),
        documents: documents,
      );
    } catch (e) {
      print('Error parsing Driver from map: $e');
      print('Data: $data');

      // Return a default driver with safe values
      return Driver(
        id: data['id']?.toString() ?? 'unknown',
        name: data['name']?.toString() ?? 'Unknown Driver',
        email: data['email']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        status: data['status']?.toString() ?? 'pending',
        isOnline: false,
        isAvailable: false,
        isVerified: false,
        rating: 0.0,
        totalTrips: 0,
        totalEarnings: 0.0,
        carModel: data['carModel']?.toString() ?? '',
        licensePlate: data['licensePlate']?.toString() ?? '',
        licenseNumber: data['licenseNumber']?.toString() ?? '',
        vehicleType: data['vehicleType']?.toString() ?? 'car',
        city: data['city']?.toString() ?? '',
        country: data['country']?.toString() ?? '',
        createdAt: DateTime.now(),
        joinedDate: DateTime.now(),
      );
    }
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap({bool includePassword = false}) {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'phone': phone,
      'status': status,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'rating': rating,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'carModel': carModel,
      'licensePlate': licensePlate,
      'licenseNumber': licenseNumber,
      'vehicleType': vehicleType,
      'color': color,
      'city': city,
      'country': country,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'joinedDate': Timestamp.fromDate(joinedDate),
      'rejectionReason': rejectionReason,
      'documents': documents,
    };

    if (passwordHash != null && includePassword) {
      map['passwordHash'] = passwordHash;
    }

    if (lastLogin != null) {
      map['lastLogin'] = Timestamp.fromDate(lastLogin!);
    }

    if (verifiedAt != null) {
      map['verifiedAt'] = Timestamp.fromDate(verifiedAt!);
      map['verifiedBy'] = verifiedBy;
    }

    return map;
  }

  // Helper getter for formatted date
  String get formattedJoinedDate {
    return '${joinedDate.day}/${joinedDate.month}/${joinedDate.year}';
  }

  // Copy with method for updates
  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    String? status,
    bool? isOnline,
    bool? isAvailable,
    bool? isVerified,
    double? rating,
    int? totalTrips,
    double? totalEarnings,
    String? carModel,
    String? licensePlate,
    String? licenseNumber,
    String? vehicleType,
    String? color,
    String? city,
    String? country,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? joinedDate,
    DateTime? lastLogin,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? rejectionReason,
    List<Map<String, dynamic>>? documents,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      carModel: carModel ?? this.carModel,
      licensePlate: licensePlate ?? this.licensePlate,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      color: color ?? this.color,
      city: city ?? this.city,
      country: country ?? this.country,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      joinedDate: joinedDate ?? this.joinedDate,
      lastLogin: lastLogin ?? this.lastLogin,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      documents: documents ?? this.documents,
    );
  }

  @override
  String toString() {
    return 'Driver(id: $id, name: $name, status: $status, phone: $phone, isActive: $isActive)';
  }
}
