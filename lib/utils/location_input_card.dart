import 'package:flutter/material.dart';

class LocationInputCard extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController dropoffController;
  final VoidCallback onConfirm;

  const LocationInputCard({
    super.key,
    required this.pickupController,
    required this.dropoffController,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[900],
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: pickupController,
              decoration: const InputDecoration(
                hintText: "Pickup location",
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dropoffController,
              decoration: const InputDecoration(
                hintText: "Dropoff location",
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text("Confirm"),
            )
          ],
        ),
      ),
    );
  }
}
