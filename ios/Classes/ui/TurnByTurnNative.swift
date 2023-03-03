// swiftlint:disable force_cast
import Flutter
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import UIKit

enum NavigationCameraType: String, Codable {
  case NO_CHANGE = "noChange"
  case OVERVIEW = "overview"
  case FOLLOWING = "following"
}

public class TurnByTurnNative: UIViewController, NavigationMapViewDelegate,
  NavigationViewControllerDelegate, FlutterStreamHandler
{
  @IBOutlet weak var container: UIView!

  var arguments: NSDictionary?

  var eventSink: FlutterEventSink?
  var mapboxTurnByTurnEvents: MapboxTurnByTurnEvents?

  let messenger: FlutterBinaryMessenger
  let methodChannel: FlutterMethodChannel
  let eventChannel: FlutterEventChannel

  var navigationMapView: NavigationMapView?
  var navigationViewController: NavigationViewController?

  var currentRouteIndex = 0 {
    didSet {
      showCurrentRoute()
    }
  }
  var currentRoute: Route? {
    return routes?[currentRouteIndex]
  }

  var routes: [Route]? {
    return routeResponse?.routes
  }

  var routeResponse: RouteResponse? {
    didSet {
      guard currentRoute != nil else {
        navigationMapView!.removeRoutes()
        return
      }
      currentRouteIndex = 0
    }
  }

  func showCurrentRoute() {
    guard let currentRoute = currentRoute else { return }

    var routes = [currentRoute]
    routes.append(
      contentsOf: self.routes!.filter {
        $0 != currentRoute
      })
    navigationMapView!.showcase(routes)
  }

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
    arguments = args as! NSDictionary
    self.messenger = messenger!
    methodChannel =
      FlutterMethodChannel(
        name: "flutter_mapbox_turn_by_turn/map_view/method",
        binaryMessenger: self.messenger
      )
    eventChannel =
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

    super.init(nibName: nil, bundle: nil)
    
    view.frame = frame
    
    eventChannel.setStreamHandler(self)
    methodChannel.setMethodCallHandler { [weak self] (call, result) in

      guard let strongSelf = self else { return }

      let arguments = call.arguments as! NSDictionary

      switch call.method {
      case "startNavigation":
        strongSelf.startNavigation(arguments: arguments)
        break
      case "stopNavigation":
        strongSelf.clearRouteAndStopNavigation()
        break
      case "addOfflineMap":
        strongSelf.addOfflineMap(arguments: arguments)
        break
      case "toggleMuted":
        break
      default:
        result("method is not implemented")
      }
    }

    initializeMapbox()
  }
  
  required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  private func initializeMapbox() {
    var mapInitOptions: MapInitOptions?

    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 6 || hour > 20 {  // night mode
      mapInitOptions = MapInitOptions(styleURI: StyleURI(url: URL(string: mapStyleUrlNight!)!))
    } else {
      mapInitOptions = MapInitOptions(styleURI: StyleURI(url: URL(string: mapStyleUrlDay!)!))
    }

    if mapInitOptions != nil {
      let mapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions!)
      navigationMapView = NavigationMapView(
        frame: view.bounds, navigationCameraType: .mobile, mapView: mapView)
    } else {
      navigationMapView = NavigationMapView(
        frame: view.bounds)
    }

    if navigateOnLongClick ?? false {
      let gesture = UILongPressGestureRecognizer(
        target: self, action: #selector(handleLongPress(_:)))
      navigationMapView!.addGestureRecognizer(gesture)
    }

    let passiveLocationManager = PassiveLocationManager()
    var passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)

    let locationProvider: LocationProvider = passiveLocationProvider
    navigationMapView!.mapView.location.overrideLocationProvider(with: locationProvider)
    passiveLocationProvider.startUpdatingLocation()

    navigationMapView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    navigationMapView!.delegate = self
    navigationMapView!.userLocationStyle = .puck2D()

    let navigationViewportDataSource = NavigationViewportDataSource(
      navigationMapView!.mapView, viewportDataSourceType: .raw)
    navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
    navigationViewportDataSource.followingMobileCamera.pitch = CGFloat(pitch!)
    navigationViewportDataSource.followingMobileCamera.zoom = CGFloat(zoom!)
    navigationMapView!.navigationCamera.viewportDataSource = navigationViewportDataSource

    view.addSubview(navigationMapView!)
    navigationMapView!.removeArrow()
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.eventSink = eventSink
    mapboxTurnByTurnEvents = MapboxTurnByTurnEvents(eventSink: self.eventSink)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    mapboxTurnByTurnEvents = nil
    return nil
  }
  
  private func startNavigation(arguments: NSDictionary?) {
    
  }

  func findRoutes(locations: [CLLocationCoordinate2D], waypointNames: [String], navigationCameraType: String) {
    guard let userLocation = navigationMapView!.mapView.location.latestLocation else { return }

    let userWaypoint = Waypoint(
      coordinate: CLLocationCoordinate2D(
        latitude: userLocation.coordinate.latitude,
        longitude: userLocation.coordinate.longitude),
      name: "")

    var waypoints: [Waypoint] = [userWaypoint]
    
    for index in 0..<locations.count {
      let waypoint = Waypoint(
        coordinate: locations[index],
        name: waypointNames[index]
        )
      waypoints.append(waypoint)
    }

    var mode: ProfileIdentifier?

    switch routeProfile {
    case "cycling":
      mode = .cycling
      break
    case "driving":
      mode = .automobile
      break
    case "walking":
      mode = .walking
      break
    default:
      mode = .automobileAvoidingTraffic
    }

    let navigationRouteOptions = NavigationRouteOptions(
      waypoints: waypoints, profileIdentifier: mode
    )
    navigationRouteOptions.allowsUTurnAtWaypoint = allowUTurnsAtWaypoints
    navigationRouteOptions.distanceMeasurementSystem =
    measurementUnits == "imperial" ? MeasurementSystem.imperial : MeasurementSystem.metric
    navigationRouteOptions.locale = Locale(identifier: language)

    Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
      switch result {
      case .failure(let error):
        print(error.localizedDescription)
      case .success(let response):
        guard let self = self else { return }

        self.routeResponse = response
        if let routes = self.routes,
          let currentRoute = self.currentRoute
        {
          self.setRouteAndStartNavigation(routes: routes, currentRoute: currentRoute, navigationCameraType: navigationCameraType)
        }
      }
    }
  }
  
  private func setRouteAndStartNavigation(routes: [Route], currentRoute: Route, navigationCameraType: String) {
    guard let routeResponse = routeResponse else {
      mapboxTurnByTurnEvents?.sendEvent(eventType: MapboxEventType.routeBuildNoRoutesFound)
      return
    }
    
    mapboxTurnByTurnEvents?.sendEvent(eventType: MapboxEventType.routeBuilt)
    
    self.navigationMapView!.show(routes)
    self.navigationMapView!.showWaypoints(on: currentRoute)
    
    switch(navigationCameraType) {
    case NavigationCameraType.FOLLOWING.rawValue:
      self.navigationMapView?.navigationCamera.follow()
      break
    case NavigationCameraType.OVERVIEW.rawValue:
      self.navigationMapView?.navigationCamera.moveToOverview()
      break
    default:
      break
    }
    
    let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
    let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                    customRoutingProvider: NavigationSettings.shared.directions,
                                                    credentials: NavigationSettings.shared.directions.credentials,
                                                    simulating: .never)
    let navigationOptions = NavigationOptions(navigationService: navigationService)
    navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                            navigationOptions: navigationOptions)
    
    navigationViewController!.delegate = self
    addChild(navigationViewController!)
    container.addSubview(navigationViewController!.view)
    navigationViewController!.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        navigationViewController!.view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
        navigationViewController!.view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
        navigationViewController!.view.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
        navigationViewController!.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0)
    ])
    self.didMove(toParent: self)
  }
  
  private func clearRouteAndStopNavigation() {
    if routeResponse == nil
    {
        return
    }

    routeResponse = nil
    mapboxTurnByTurnEvents?.sendEvent(eventType: MapboxEventType.navigationCancelled)
  }
  
  private func addOfflineMap(arguments: NSDictionary?) {
    
  }
  
  // Delegate called when user long presses on the map
  @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .ended else { return }
    let location = navigationMapView!.mapView.mapboxMap.coordinate(
      for: gesture.location(in: navigationMapView!.mapView))

    findRoutes(locations: [location], waypointNames: [""], navigationCameraType: NavigationCameraType.NO_CHANGE.rawValue)
  }
  
  // Delegate method called when the user selects a route
  public func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
    self.currentRouteIndex = self.routes?.firstIndex(of: route) ?? 0
  }
  
  // Delecgate called when navigation is cancelled
  public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
    navigationController?.popViewController(animated: true)
  }
}
