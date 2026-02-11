import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteResult {
  final Set<Marker> markers;
  final Set<Polyline> polyline;
  final LatLngBounds bounds;
  final double distanceKm;

  RouteResult({
    required this.markers,
    required this.polyline,
    required this.bounds,
    required this.distanceKm,
  });
}

class MapService {
  static const String _apiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  static Future<RouteResult> getRoute(String pickup, String dropoff) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$pickup&destination=$dropoff&key=$_apiKey";
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data["status"] != "OK") {
      throw Exception("Failed to fetch directions: ${data["status"]}");
    }

    final route = data["routes"][0];
    final leg = route["legs"][0];

    final start = LatLng(
      leg["start_location"]["lat"],
      leg["start_location"]["lng"],
    );
    final end = LatLng(
      leg["end_location"]["lat"],
      leg["end_location"]["lng"],
    );

    final distanceMeters = leg["distance"]["value"];
    final distanceKm = distanceMeters / 1000;

    final polylinePoints = route["overview_polyline"]["points"];
    final decodedPolyline = _decodePolyline(polylinePoints);

    return RouteResult(
      markers: {
        Marker(markerId: const MarkerId("pickup"), position: start),
        Marker(markerId: const MarkerId("dropoff"), position: end),
      },
      polyline: {
        Polyline(
          polylineId: const PolylineId("route"),
          points: decodedPolyline,
          width: 5,
        )
      },
      bounds: LatLngBounds(
        southwest: LatLng(
          route["bounds"]["southwest"]["lat"],
          route["bounds"]["southwest"]["lng"],
        ),
        northeast: LatLng(
          route["bounds"]["northeast"]["lat"],
          route["bounds"]["northeast"]["lng"],
        ),
      ),
      distanceKm: distanceKm,
    );
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}
