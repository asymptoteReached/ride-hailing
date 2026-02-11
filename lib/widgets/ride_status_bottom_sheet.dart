import 'package:eats/services/ride_services.dart';
import 'package:flutter/material.dart';
import 'package:eats/models/ride_model.dart';
import 'package:eats/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideStatusBottomSheet extends StatelessWidget {
  final String rideId;
  final RideService rideService;
  final LocationService locationService;
  final VoidCallback onCompleteRide;
  final VoidCallback onShowPayment;

  const RideStatusBottomSheet({
    super.key,
    required this.rideId,
    required this.rideService,
    required this.locationService,
    required this.onCompleteRide,
    required this.onShowPayment,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Ride>(
      stream: rideService.streamRide(rideId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildFindingDriverCard();

        final ride = snapshot.data!;
        Widget content;

        if (ride.status == 'requested') {
          content = _buildFindingDriverCard();
        } else if (ride.status == 'accepted' && ride.driverId != null) {
          content = _buildDriverAcceptedCard(ride.driverId!);
        } else if (ride.status == 'in_progress') {
          content = _buildInProgressCard(context);
        } else if (ride.status == 'completed') {
          content = _buildCompletedCard();
        } else {
          content = _buildFindingDriverCard();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: content,
        );
      },
    );
  }

  Widget _buildFindingDriverCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Finding a driver...", style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );

  Widget _buildDriverAcceptedCard(String driverId) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Driver has accepted your ride!",
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 12),
              StreamBuilder<Map<String, dynamic>?>(
                stream: rideService.streamDriverLocation(driverId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text('Fetching driver location...');
                  }
                  final loc = snapshot.data as Map<String, dynamic>;
                  locationService
                      .updateDriverLocation(LatLng(loc['lat'], loc['lng']));
                  return Text(
                      'Driver is on the way: ${loc['lat']}, ${loc['lng']}');
                },
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: onShowPayment,
                child: Text("Pay / View Payment Options"),
              ),
            ],
          ),
        ),
      );

  Widget _buildInProgressCard(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Ride in progress...", style: TextStyle(fontSize: 18)),
              SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onCompleteRide();
                  },
                  child: Text("Mark Complete"))
            ],
          ),
        ),
      );

  Widget _buildCompletedCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 12),
              Text("Ride Completed!", style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
}
