import 'package:flutter_mapbox_turn_by_turn/src/models/waypoint.dart';

bool isNullOrZero(dynamic val) {
  return val == 0.0 || val == null;
}

///This class contains all progress information at any given time during a navigation session.
///This progress includes information for the current route, leg and step the user is traversing along.
///With every new valid location update, a new route progress will be generated using the latest information.
class MapboxProgressChangeEvent {
  double? distance;
  double? duration;
  double? distanceTraveled;
  double? currentLegDistanceTraveled;
  double? currentLegDistanceRemaining;
  String? currentStepInstruction;
  RouteLeg? currentLeg;
  RouteLeg? priorLeg;
  List<RouteLeg>? remainingLegs;
  int? legIndex;
  int? stepIndex;
  bool? isProgressChangeEvent;

  MapboxProgressChangeEvent({
    this.distance,
    this.duration,
    this.distanceTraveled,
    this.currentLegDistanceTraveled,
    this.currentLegDistanceRemaining,
    this.currentStepInstruction,
    this.currentLeg,
    this.priorLeg,
    this.remainingLegs,
    this.legIndex,
    this.stepIndex,
    this.isProgressChangeEvent,
  });

  MapboxProgressChangeEvent.fromJson(Map<String, dynamic> json) {
    isProgressChangeEvent = json['arrived'] != null;
    distance = isNullOrZero(json['distance']) ? 0.0 : json["distance"] + .0;
    duration = isNullOrZero(json['duration']) ? 0.0 : json["duration"] + .0;
    distanceTraveled = isNullOrZero(json['distanceTraveled'])
        ? 0.0
        : json["distanceTraveled"] + .0;
    currentLegDistanceTraveled =
        isNullOrZero(json['currentLegDistanceTraveled'])
            ? 0.0
            : json["currentLegDistanceTraveled"] + .0;
    currentLegDistanceRemaining =
        isNullOrZero(json['currentLegDistanceRemaining'])
            ? 0.0
            : json["currentLegDistanceRemaining"] + .0;
    currentStepInstruction = json['currentStepInstruction'];
    currentLeg = json['currentLeg'] == null
        ? null
        : RouteLeg.fromJson(json['currentLeg'] as Map<String, dynamic>);
    priorLeg = json['priorLeg'] == null
        ? null
        : RouteLeg.fromJson(json['priorLeg'] as Map<String, dynamic>);
    remainingLegs = (json['remainingLegs'] as List?)
        ?.map((e) =>
            e == null ? null : RouteLeg.fromJson(e as Map<String, dynamic>))
        .cast<RouteLeg>()
        .toList();
    legIndex = json['legIndex'];
    stepIndex = json['stepIndex'];
  }
}

///A RouteLeg object defines a single leg of a route between two waypoints.
///If the overall route has only two waypoints, it has a single RouteLeg object that covers the entire route.
///The route leg object includes information about the leg, such as its name, distance, and expected travel time.
///Depending on the criteria used to calculate the route, the route leg object may also include detailed turn-by-turn instructions.
class RouteLeg {
  String? profileIdentifier;
  String? name;
  double? distance;
  double? expectedTravelTime;
  Waypoint? source;
  Waypoint? destination;
  List<RouteStep>? steps;

  RouteLeg(this.profileIdentifier, this.name, this.distance,
      this.expectedTravelTime, this.source, this.destination, this.steps);

  RouteLeg.fromJson(Map<String, dynamic> json) {
    profileIdentifier = json["profileIdentifier"];
    name = json["name"];
    distance = isNullOrZero(json["distance"]) ? 0.0 : json["distance"] + .0;
    expectedTravelTime = isNullOrZero(json["expectedTravelTime"])
        ? 0.0
        : json["expectedTravelTime"] + .0;
    source = json['source'] == null
        ? null
        : Waypoint.fromJson(json['source'] as Map<String, dynamic>);
    destination = json['destination'] == null
        ? null
        : Waypoint.fromJson(json['destination'] as Map<String, dynamic>);
    steps = (json['steps'] as List?)
        ?.map((e) =>
            e == null ? null : RouteStep.fromJson(e as Map<String, dynamic>))
        .cast<RouteStep>()
        .toList();
  }
}

///A RouteStep object represents a single distinct maneuver along a route and the approach to the next maneuver.
///The route step object corresponds to a single instruction the user must follow to complete a portion of the route.
///For example, a step might require the user to turn then follow a road.
class RouteStep {
  String? name;
  String? instructions;
  double? distance;
  double? expectedTravelTime;

  RouteStep(
      this.name, this.instructions, this.distance, this.expectedTravelTime);

  RouteStep.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    instructions = json["instructions"];
    distance = isNullOrZero(json["distance"]) ? 0.0 : json["distance"] + .0;
    expectedTravelTime = isNullOrZero(json["expectedTravelTime"])
        ? 0.0
        : json["expectedTravelTime"] + .0;
  }
}
