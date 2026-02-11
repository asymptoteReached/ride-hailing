import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:eats/utils/common_methods.dart';

class GoogleMapMethods {
  static sendRequestToAPI(String apiUrl, context) async {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (errorMsg) {
      CommonMethods.displaySnackBar('Error occured: $errorMsg', context);
      return "error";
    }
  }

  static Future<LatLng?> getLatLngFromPlaceId(String placeId,
      {required String googleApiKey}) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey';
    final response = await sendRequestToAPI(url, null);
    if (response != null && response['status'] == 'OK') {
      final location = response['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
    return null;
  }
}
