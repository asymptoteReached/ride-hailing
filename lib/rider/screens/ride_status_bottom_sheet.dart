import 'package:eats/models/ride_model.dart';
import 'package:flutter/material.dart';

class RideStatusBottomSheet extends StatefulWidget {
  final Ride? ride;
  final VoidCallback? onCancelRide;
  final Function(String)? onUpdateStatus;
  final VoidCallback? onClose;
  final bool isExpanded;

  const RideStatusBottomSheet({
    super.key,
    this.ride,
    this.onCancelRide,
    this.onUpdateStatus,
    this.onClose,
    this.isExpanded = false,
  });

  @override
  State<RideStatusBottomSheet> createState() => _RideStatusBottomSheetState();
}

class _RideStatusBottomSheetState extends State<RideStatusBottomSheet> {
  double _sheetHeight = 0.3;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (widget.ride == null) return const SizedBox();

    final ride = widget.ride!;
    final status = ride.status;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: MediaQuery.of(context).size.height * _sheetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Draggable handle
          GestureDetector(
            onVerticalDragStart: (_) => setState(() => _isDragging = true),
            onVerticalDragUpdate: (details) {
              final newHeight = _sheetHeight -
                  (details.delta.dy / MediaQuery.of(context).size.height);
              setState(() {
                _sheetHeight = newHeight.clamp(0.3, 0.8);
              });
            },
            onVerticalDragEnd: (_) => setState(() => _isDragging = false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // Header with status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusHeader(status),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(),

          // Ride details (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup and dropoff info
                  _buildLocationInfo(ride),

                  const SizedBox(height: 16),

                  // Progress indicator
                  _buildProgressIndicator(status),

                  // Driver tracking info for accepted rides
                  const SizedBox(height: 12),
                  _buildDriverTrackingInfo(status),

                  const SizedBox(height: 24),

                  // Fare info
                  _buildFareInfo(ride),

                  const SizedBox(height: 16),

                  // Customer info
                  _buildCustomerInfo(ride),

                  const SizedBox(height: 24),

                  // Action buttons based on status
                  _buildActionButtons(status),

                  const SizedBox(height: 16),

                  // Cancel button
                  if (status != 'completed' && status != 'cancelled')
                    _buildCancelButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    IconData icon;
    Color color;
    String text;
    String? subtitle;

    switch (status) {
      case 'pending':
        icon = Icons.search;
        color = Colors.orange;
        text = 'Finding Driver';
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
        text = 'Arrived at Pickup';
        break;
      case 'in_progress':
        icon = Icons.directions_car;
        color = Colors.purple;
        text = 'Trip in Progress';
        break;
      case 'completed':
        icon = Icons.done_all;
        color = Colors.green;
        text = 'Trip Completed';
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        text = 'Ride Cancelled';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        text = 'Ride Status';
    }

    return Row(
      children: [
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
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              )
            else
              Text(
                'Tap to ${_isDragging || _sheetHeight > 0.3 ? 'collapse' : 'expand'}',
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

  Widget _buildDriverTrackingInfo(String status) {
    // Only show for 'accepted' status
    if (status != 'accepted') return SizedBox();

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

  Widget _buildLocationInfo(Ride ride) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Route',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pickup: ${ride.pickup['address'] ?? '${ride.pickup['lat']}, ${ride.pickup['lng']}'}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Destination: ${ride.dropoff['address'] ?? '${ride.dropoff['lat']}, ${ride.dropoff['lng']}'}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(String status) {
    final steps = ['accepted', 'arrived', 'in_progress', 'completed'];
    final currentIndex = steps.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(steps.length, (index) {
            bool isActive = index <= currentIndex;
            bool isLast = index == steps.length - 1;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
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
                  Text(
                    _getStepLabel(steps[index]),
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.blue : Colors.grey,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 3,
                        color: isActive ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getStepLabel(String step) {
    switch (step) {
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

  Widget _buildFareInfo(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Estimated Fare:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'E${ride.fare.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Ride ride) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Info',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (ride.riderName != null)
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: Text(ride.riderName!),
          ),
        if (ride.riderPhone != null)
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone'),
            subtitle: Text(ride.riderPhone!),
          ),
      ],
    );
  }

  Widget _buildActionButtons(String status) {
    switch (status) {
      case 'accepted':
        return ElevatedButton.icon(
          onPressed: () => widget.onUpdateStatus?.call('arrived'),
          icon: const Icon(Icons.location_on),
          label: const Text('Mark as Arrived'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.orange,
          ),
        );
      case 'arrived':
        return ElevatedButton.icon(
          onPressed: () => widget.onUpdateStatus?.call('in_progress'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Trip'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue,
          ),
        );
      case 'in_progress':
        return ElevatedButton.icon(
          onPressed: () => widget.onUpdateStatus?.call('completed'),
          icon: const Icon(Icons.check_circle),
          label: const Text('Complete Trip'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.green,
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildCancelButton() {
    return OutlinedButton.icon(
      onPressed: widget.onCancelRide,
      icon: const Icon(Icons.cancel, color: Colors.red),
      label: const Text(
        'Cancel Ride',
        style: TextStyle(color: Colors.red),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: Colors.red),
      ),
    );
  }
}
