// swiftlint:disable force_cast
import Flutter
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import UIKit

public class TurnByTurnNative: NSObject, FlutterStreamHandler {
  let frame: CGRect
  var navigationMapView: NavigationMapView?
  var arguments: NSDictionary?

  var navigationViewController: NavigationViewController?
  var eventSink: FlutterEventSink?

  let messenger: FlutterBinaryMessenger
  let methodChannel: FlutterMethodChannel
  let eventChannel: FlutterEventChannel

  var routeResponse: RouteResponse?
  var selectedRouteIndex = 0
  var routeOptions: NavigationRouteOptions?
  var navigationService: NavigationService!

  var mapInitialized = false
  var locationManager = CLLocationManager()
  let allowRouteSelection = false
  let isMultipleUniqueRoutes = false
  var isEmbeddedNavigation = false

  var distanceRemaining: Double?
  var durationRemaining: Double?
  var navigationMode: String?
  var routes: [Route]?
  var waypoints = [Waypoint]()
  var lastKnownLocation: CLLocation?

  var options: NavigationRouteOptions?

  // flutter creation parameters
  private var zoom: Double?
  private var pitch: Double?
  private var disableGesturesWhenFollowing: Bool?
  private var navigateOnLongClick: Bool?
  private var muted: Bool?
  private var showMuteButton: Bool?
  private var showStopButton: Bool?
  private var showSpeedIndicator: Bool = true
  private var speedThreshold: Int = 5
  private var navigationCameraType: String?
  private var routeProfile: String
  private var language: String
  private var showAlternativeRoutes: Bool
  private var allowUTurnsAtWaypoints: Bool
  private var mapStyleUrlDay: String?
  private var mapStyleUrlNight: String?
  private var measurementUnits: String = "metric"
  private var routeCasingColor: String
  private var routeDefaultColor: String
  private var restrictedRoadColor: String
  private var routeLineTraveledColor: String
  private var routeLineTraveledCasingColor: String
  private var routeClosureColor: String
  private var routeLowCongestionColor: String
  private var routeModerateCongestionColor: String
  private var routeHeavyCongestionColor: String
  private var routeSevereCongestionColor: String
  private var routeUnknownCongestionColor: String

  init(
    frame: CGRect,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger?
  ) {
    self.frame = frame

    self.arguments = args as! NSDictionary

    self.messenger = messenger!
    self.methodChannel =
      FlutterMethodChannel(
        name: "flutter_mapbox_turn_by_turn/map_view/method",
        binaryMessenger: self.messenger
      )
    self.eventChannel =
      FlutterEventChannel(
        name: "flutter_mapbox_turn_by_turn/map_view/events",
        binaryMessenger: self.messenger
      )

    zoom = arguments?["zoom"] as? Double
    pitch = arguments?["pitch"] as? Double
    disableGesturesWhenFollowing = arguments?["disableGesturesWhenFollowing"] as? Bool
    navigateOnLongClick = arguments?["navigateOnLongClick"] as? Bool
    muted = arguments?["muted"] as? Bool
    showMuteButton = arguments?["showMuteButton"] as? Bool
    showStopButton = arguments?["showStopButton"] as? Bool
    showSpeedIndicator = arguments?["showSpeedIndicator"] as! Bool
    navigationCameraType = arguments?["navigationCameraType"] as! String
    speedThreshold = arguments?["speedThreshold"] as! Int
    routeProfile = arguments?["routeProfile"] as! String
    language = arguments?["language"] as! String
    showAlternativeRoutes = arguments?["showAlternativeRoutes"] as! Bool
    allowUTurnsAtWaypoints = arguments?["allowUTurnsAtWaypoints"] as! Bool
    mapStyleUrlDay = arguments?["mapStyleUrlDay"] as? String
    mapStyleUrlNight = arguments?["mapStyleUrlNight"] as? String
    measurementUnits = arguments?["measurementUnits"] as! String
    routeCasingColor = arguments?["routeCasingColor"] as! String
    routeDefaultColor = arguments?["routeDefaultColor"] as! String
    restrictedRoadColor = arguments?["restrictedRoadColor"] as! String
    routeLineTraveledColor = arguments?["routeLineTraveledColor"] as! String
    routeLineTraveledCasingColor = arguments?["routeLineTraveledCasingColor"] as! String
    routeClosureColor = arguments?["routeClosureColor"] as! String
    routeLowCongestionColor = arguments?["routeLowCongestionColor"] as! String
    routeModerateCongestionColor = arguments?["routeModerateCongestionColor"] as! String
    routeHeavyCongestionColor = arguments?["routeHeavyCongestionColor"] as! String
    routeSevereCongestionColor = arguments?["routeSevereCongestionColor"] as! String
    routeUnknownCongestionColor = arguments?["routeUnknownCongestionColor"] as! String

    super.init()

    self.eventChannel.setStreamHandler(self)

    self.methodChannel.setMethodCallHandler { [weak self] (call, result) in

      guard let strongSelf = self else { return }

      let arguments = call.arguments as! NSDictionary

      switch call.method {
      case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
      default:
        result("method is not implemented")
      }
    }

    var mapInitOptions: MapInitOptions?

    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 6 || hour > 8 {  // night mode
      mapInitOptions = MapInitOptions(styleURI: StyleURI(url: URL(string: mapStyleUrlNight!)!))
    } else {
      mapInitOptions = MapInitOptions(styleURI: StyleURI(url: URL(string: mapStyleUrlDay!)!))
    }

    if mapInitOptions != nil {
      let mapView = MapView(frame: frame, mapInitOptions: mapInitOptions!)
      navigationMapView = NavigationMapView(
        frame: frame, navigationCameraType: .mobile, mapView: mapView)
    }
  }

  private func setupMapView() {
    /*language = arguments?["language"] as? String ?? language
      voiceUnits = arguments?["units"] as? String ?? voiceUnits
      simulateRoute = arguments?["simulateRoute"] as? Bool ?? simulateRoute
      isOptimized = arguments?["isOptimized"] as? Bool ?? isOptimized
      allowsUTurnAtWayPoints = arguments?["allowsUTurnAtWayPoints"] as? Bool
      navigationMode = arguments?["mode"] as? String ?? "drivingWithTraffic"
      mapStyleUrlDay = arguments?["mapStyleUrlDay"] as? String
      tilt = arguments?["tilt"] as? Double ?? tilt
      animateBuildRoute = arguments?["animateBuildRoute"] as? Bool ?? animateBuildRoute
      longPressDestinationEnabled =
        arguments?["navigateOnLongClick"] as? Bool ?? navigateOnLongClick

      if mapStyleUrlDay != nil {
        super.navigationMapView.mapView.mapboxMap.style.uri = StyleURI.init(
          url: URL(string: mapStyleUrlDay!)!)
      }

      var currentLocation: CLLocation!

      locationManager.requestWhenInUseAuthorization()

      if CLLocationManager.authorizationStatus() == .authorizedWhenInUse
        || CLLocationManager.authorizationStatus() == .authorizedAlways
      {
        currentLocation = locationManager.location

      }

      let initialLatitude =
        arguments?["initialLatitude"] as? Double ?? currentLocation?.coordinate.latitude
      let initialLongitude =
        arguments?["initialLongitude"] as? Double ?? currentLocation?.coordinate.longitude
      if initialLatitude != nil && initialLongitude != nil {
        super.moveCameraToCoordinates(latitude: initialLatitude!, longitude: initialLongitude!)
      }*/
  }

  /*if longPressDestinationEnabled {
      let gesture = UILongPressGestureRecognizer(
        target: self, action: #selector(handleLongPress(_:)))
      gesture.delegate = self
      self.navigationMapView?.addGestureRecognizer(gesture)
    }
  }*/

  public func onListen(
    withArguments arguments: Any?,
    eventSink: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.eventSink = eventSink
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
