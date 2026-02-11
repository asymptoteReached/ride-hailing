// utils/car_marker_utils.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:math';

class CarMarkerUtils {
  // Cache for icons
  static BitmapDescriptor? _cachedCarIcon;
  static BitmapDescriptor? _cachedDriverCarIcon;

  // Create car icon for driver
  static Future<BitmapDescriptor> createCarIcon({
    Color carColor = const Color(0xFF4285F4),
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = Size(80, 80);

    // Draw car body (rounded rectangle with car shape)
    final paint = Paint()..color = carColor;
    final carPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw car body (rounded rectangle)
    final carRect = Rect.fromLTWH(10, 15, 30, 20);
    final carRRect = RRect.fromRectAndRadius(carRect, Radius.circular(8));
    canvas.drawRRect(carRRect, carPaint);

    // Draw car top (windshield)
    final topRect = Rect.fromLTWH(15, 10, 20, 10);
    final topRRect = RRect.fromRectAndRadius(topRect, Radius.circular(4));
    canvas.drawRRect(topRRect, carPaint);

    // Draw windows
    final windowPaint = Paint()..color = Color(0xFF1A73E8);
    canvas.drawRect(Rect.fromLTWH(18, 12, 4, 6), windowPaint);
    canvas.drawRect(Rect.fromLTWH(28, 12, 4, 6), windowPaint);

    // Draw wheels
    final wheelPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(16, 35), 4, wheelPaint);
    canvas.drawCircle(Offset(34, 35), 4, wheelPaint);

    // Draw car outline
    final outlinePaint = Paint()
      ..color = carColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(carRRect, outlinePaint);
    canvas.drawRRect(topRRect, outlinePaint);

    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // Get car icon (cached)
  static Future<BitmapDescriptor> getCarIcon() async {
    _cachedCarIcon ??= await createCarIcon();
    return _cachedCarIcon!;
  }

  // Get driver car icon with blue color
  static Future<BitmapDescriptor> getDriverCarIcon() async {
    _cachedDriverCarIcon ??= await createCarIcon(carColor: Color(0xFF4285F4));
    return _cachedDriverCarIcon!;
  }

  // Calculate bearing between two points
  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (pi / 180);
    final lon1 = start.longitude * (pi / 180);
    final lat2 = end.latitude * (pi / 180);
    final lon2 = end.longitude * (pi / 180);

    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }
}
