class PlacePredictionModel {
  String? placeId;
  String? mainText;
  String? secondaryText;
  late bool isCurrentLocation;

  PlacePredictionModel(
      {this.placeId,
      this.mainText,
      this.secondaryText,
      this.isCurrentLocation = false});

  PlacePredictionModel.fromJson(Map<String, dynamic> json) {
    placeId = json['place_id'];
    mainText = json['structured_formatting']['main_text'];
    secondaryText = json['structured_formatting']['secondary_text'];
    isCurrentLocation = false;
  }
}
