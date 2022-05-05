///A Geo-coordinate Point used for navigation.
class Waypoint {
  String? name;
  double? latitude;
  double? longitude;
  Waypoint(
      {required this.name, required this.latitude, required this.longitude});

  @override
  String toString() {
    return 'Point{latitude: $latitude, longitude: $longitude}';
  }

  Waypoint.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    latitude = json["latitude"] as double?;
    longitude = json["longitude"] as double?;
  }
}
