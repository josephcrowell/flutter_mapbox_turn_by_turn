// swiftlint:disable force_cast
import Flutter
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import UIKit
import os.log

extension OSLog {
  private static var subsystem = Bundle.main.bundleIdentifier!

  /// Logs the view cycles like viewDidLoad.
  static let TurnByTurnNative = OSLog(subsystem: subsystem, category: "TurnByTurnNative")
}

enum NavigationCameraType: String, Codable {
  case noChange
  case overview
  case following
}

var defaultBorderWidth: CGFloat {
  2 / UIScreen.main.scale
}

let overviewIcon = UIImage(
  named: "overview",
  in: .mapboxNavigation,
  compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)

let muteIcon = UIImage(
  named: "volume_up",
  in: .mapboxNavigation,
  compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)

let unmuteIcon = UIImage(
  named: "volume_off",
  in: .mapboxNavigation,
  compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)

let followIcon = UIImage(
  named: "start",
  in: .mapboxNavigation,
  compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)

let overviewButton: FloatingButton = {
  let floatingButton = FloatingButton.rounded(image: overviewIcon)
  floatingButton.borderWidth = defaultBorderWidth

  return floatingButton
}()

let muteButton: FloatingButton = {
  let floatingButton = FloatingButton.rounded(image: muteIcon)
  floatingButton.borderWidth = defaultBorderWidth

  return floatingButton
}()

let followButton: FloatingButton = {
  let floatingButton = FloatingButton.rounded(image: followIcon)
  floatingButton.borderWidth = defaultBorderWidth

  return floatingButton
}()

var mapboxTurnByTurnEvents: MapboxTurnByTurnEvents?
var isVoiceInstructionsMuted: Bool = false
var isInFreeDrive: Bool = true

class FlutterVoiceController: MapboxSpeechSynthesizer {
  let methodChannel: FlutterMethodChannel

  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel

    super.init()
  }

  override func speak(
    _ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil
  ) {
    if !isVoiceInstructionsMuted {
      methodChannel.invokeMethod("playVoiceInstruction", arguments: instruction.text)
    }
  }
}

public class TurnByTurnNative: UIViewController, FlutterStreamHandler {
  var arguments: NSDictionary?

  var eventSink: FlutterEventSink?

  let messenger: FlutterBinaryMessenger
  let methodChannel: FlutterMethodChannel
  let eventChannel: FlutterEventChannel
  
  let bearingThrottle = Throttle(minimumDelay: 5)

  var navigationView: NavigationView?
  var navigationMapView: NavigationMapView?
  var navigationViewController: NavigationViewController?
  var passiveLocationManager: PassiveLocationManager?
  var passiveLocationProvider: PassiveLocationProvider?
  var navigationViewportDataSource: NavigationViewportDataSource?

  var latestLocation: CLLocation?
  var latestBearing: CLLocationDirection?

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
        self.navigationMapView!.removeRoutes()
        self.navigationMapView!.removeWaypoints()
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
    self.navigationMapView!.showcase(routes)
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
  private var navigationCameraType: NavigationCameraType?
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
    os_log("Initializing Mapbox", log: OSLog.TurnByTurnNative, type: .debug)
    arguments = (args as! NSDictionary)
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
    let initNavigationCameraType = (arguments?["navigationCameraType"] as! String)
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
    
    switch initNavigationCameraType {
    case NavigationCameraType.following.rawValue:
      navigationCameraType = .following
    default:
      navigationCameraType = .overview
    }

    super.init(nibName: nil, bundle: nil)

    isVoiceInstructionsMuted = muted ?? false

    view.frame = frame

    eventChannel.setStreamHandler(self)
    methodChannel.setMethodCallHandler { [weak self] (call, result) in

      guard let strongSelf = self else { return }

      let arguments = call.arguments as! NSDictionary

      switch call.method {
      case "startNavigation":
        strongSelf.startNavigation(arguments: arguments)
      case "stopNavigation":
        if strongSelf.navigationViewController != nil {
          strongSelf.navigationViewControllerDidDismiss(
            strongSelf.navigationViewController!, byCanceling: true)
        }
      case "addOfflineMap":
        strongSelf.addOfflineMap(arguments: arguments)
      case "toggleMuted":
        break
      default:
        result("method is not implemented")
      }
    }
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

    navigationMapView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    navigationMapView!.userLocationStyle = .courseView()

    navigationView = NavigationView(frame: view.bounds, navigationMapView: navigationMapView!)
    navigationView!.translatesAutoresizingMaskIntoConstraints = false

    navigationViewportDataSource = NavigationViewportDataSource(
      navigationMapView!.mapView,
      viewportDataSourceType: .passive
    )
    navigationMapView!.navigationCamera.viewportDataSource =
      navigationViewportDataSource!

    navigationMapView!.delegate = self

    if navigateOnLongClick ?? false {
      let gesture = UILongPressGestureRecognizer(
        target: self, action: #selector(handleLongPress(_:)))
      view.addGestureRecognizer(gesture)
    }

    overviewButton.addTarget(self, action: #selector(tappedOverview(sender:)), for: .touchUpInside)
    muteButton.addTarget(self, action: #selector(tappedMute(sender:)), for: .touchUpInside)
    followButton.addTarget(self, action: #selector(tappedFollow(sender:)), for: .touchUpInside)

    if isVoiceInstructionsMuted {
      muteButton.setImage(unmuteIcon, for: .normal)
    } else {
      muteButton.setImage(muteIcon, for: .normal)
    }

    initializeMapbox()

    methodChannel.invokeMethod("onInitializationFinished", arguments: nil)
    os_log("Mapbox initialized", log: OSLog.TurnByTurnNative, type: .debug)
  }

  required init?(coder: NSCoder) {
    fatalError("init?(coder:) has not been implemented")
  }

  private func initializeMapbox() {
    if passiveLocationManager == nil {
      passiveLocationManager = PassiveLocationManager()
      if passiveLocationProvider == nil {
        passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager!)
      }
    }

    navigationMapView!.mapView.location.overrideLocationProvider(
      with: passiveLocationProvider!
    )

    passiveLocationProvider!.startUpdatingHeading()
    passiveLocationProvider!.startUpdatingLocation()
    passiveLocationManager!.startUpdatingLocation()
    passiveLocationManager!.resumeTripSession()

    passiveLocationManager!.delegate = self
    
    navigationMapView!.mapView.location.options.puckBearingSource = .heading
    navigationMapView!.mapView.location.options.puckBearingEnabled = true
    
    isInFreeDrive = true

    view.addSubview(navigationView!)
    NSLayoutConstraint.activate([
      navigationView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      navigationView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      navigationView!.topAnchor.constraint(equalTo: view.topAnchor),
      navigationView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    navigationView!.floatingButtons = [
      overviewButton,
      followButton,
    ]
        
    navigationViewportDataSource!.followingMobileCamera.pitch = pitch!
    navigationViewportDataSource!.followingMobileCamera.zoom = zoom!
    navigationViewportDataSource!.options.followingCameraOptions.centerUpdatesAllowed = true
    navigationViewportDataSource!.options.followingCameraOptions.bearingUpdatesAllowed = false
    navigationViewportDataSource!.options.followingCameraOptions.pitchUpdatesAllowed = false
    navigationViewportDataSource!.options.followingCameraOptions.paddingUpdatesAllowed = true
    navigationViewportDataSource!.options.followingCameraOptions.zoomUpdatesAllowed = false

    switch navigationCameraType {
    case .following:
      self.navigationMapView!.navigationCamera.follow()
    default:
      self.navigationMapView!.navigationCamera.moveToOverview()

      if latestLocation != nil {
        self.navigationMapView!.mapView.camera.ease(
          to: CameraOptions(center: latestLocation!.coordinate, zoom: 16, bearing: 0, pitch: 0),
          duration: 1.3
        )
      }
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.eventSink = eventSink
    mapboxTurnByTurnEvents = MapboxTurnByTurnEvents(eventSink: self.eventSink)
    os_log("FlutterEventSink initialized", log: OSLog.TurnByTurnNative, type: .debug)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    mapboxTurnByTurnEvents = nil
    os_log("FlutterEventSink cleared", log: OSLog.TurnByTurnNative, type: .debug)
    return nil
  }

  private func startNavigation(arguments: NSDictionary?) {
    guard let waypointMapList = arguments?["waypoints"] as? NSDictionary else { return }

    var waypointList = [CLLocationCoordinate2D]()
    var waypointNamesList = [String]()

    for item in waypointMapList as NSDictionary {
      let waypoint = item.value as! NSDictionary
      guard let name = waypoint["name"] as? String else { return }
      guard let latitude = waypoint["latitude"] as? Double else { return }
      guard let longitude = waypoint["longitude"] as? Double else { return }

      waypointNamesList.append(name)
      waypointList.append(
        CLLocationCoordinate2D(latitude: CGFloat(latitude), longitude: CGFloat(longitude)))
    }

    var cameraType: NavigationCameraType
    let initCameraType = arguments?["navigationCameraType"] as! String
    
    switch initCameraType {
    case NavigationCameraType.following.rawValue:
      cameraType = .following
    case NavigationCameraType.overview.rawValue:
      cameraType = .overview
    default:
      cameraType = .noChange
    }
    
    if !waypointList.isEmpty && !waypointNamesList.isEmpty {
      findRoutes(
        locations: waypointList, waypointNames: waypointNamesList, navigationCameraType: cameraType
      )
    }
  }

  func findRoutes(
    locations: [CLLocationCoordinate2D], waypointNames: [String], navigationCameraType: NavigationCameraType
  ) {
    guard let userLocation = latestLocation
    else { return }

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
    case "driving":
      mode = .automobile
    case "walking":
      mode = .walking
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
        mapboxTurnByTurnEvents?.sendEvent(eventType: MapboxEventType.routeBuildFailed)
        os_log("%{public}@", log: OSLog.TurnByTurnNative, type: .error, error.localizedDescription)
      case .success(let response):
        guard let self = self else { return }

        self.routeResponse = response
        if let routes = self.routes,
          let currentRoute = self.currentRoute
        {
          self.setRouteAndStartNavigation(
            routes: routes, currentRoute: currentRoute, navigationCameraType: navigationCameraType)
        }
      }
    }
  }

  private func setRouteAndStartNavigation(
    routes: [Route], currentRoute: Route, navigationCameraType: NavigationCameraType
  ) {
    guard let routeResponse = routeResponse else {
      mapboxTurnByTurnEvents?.sendEvent(eventType: MapboxEventType.routeBuildNoRoutesFound)
      return
    }

    mapboxTurnByTurnEvents?.sendEvent(eventType: MapboxEventType.routeBuilt)

    passiveLocationManager?.pauseTripSession()

    let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
    let navigationService = MapboxNavigationService(
      indexedRouteResponse: indexedRouteResponse,
      customRoutingProvider: NavigationSettings.shared.directions,
      credentials: NavigationSettings.shared.directions.credentials,
      simulating: .never)
    
    isInFreeDrive = false

    var dayStyle = CustomDayStyle()
    if mapStyleUrlDay != nil {
      dayStyle = CustomDayStyle(url: mapStyleUrlDay)
    }
    var nightStyle = CustomNightStyle()
    if mapStyleUrlNight != nil {
      nightStyle = CustomNightStyle(url: mapStyleUrlNight)
    }

    let speechSynthesizer = MultiplexedSpeechSynthesizer([
      FlutterVoiceController(methodChannel: methodChannel),
      SystemSpeechSynthesizer(),
    ])
    let routeVoiceController = RouteVoiceController(
      navigationService: navigationService,
      speechSynthesizer: speechSynthesizer
    )

    let navigationOptions = NavigationOptions(
      styles: [dayStyle, nightStyle],
      navigationService: navigationService,
      voiceController: routeVoiceController
    )

    for subview in self.view.subviews {
      subview.removeFromSuperview()
    }

    if navigationViewController == nil {
      navigationViewController = NavigationViewController(
        for: indexedRouteResponse,
        navigationOptions: navigationOptions)

      navigationViewController!.delegate = self

      addChild(navigationViewController!)
    } else {
      navigationViewController!.navigationService.router.updateRoute(
        with: indexedRouteResponse,
        routeOptions: navigationViewController!.navigationService.routeProgress.routeOptions,
        completion: nil)
    }
    
    navigationMapView!.mapView.location.options.puckBearingSource = .course
    
    navigationViewController!.navigationView.floatingButtons = [
      muteButton,
      overviewButton,
      followButton,
    ]
    
    switch navigationCameraType {
    case .overview:
      navigationViewController!.navigationView.navigationMapView.navigationCamera.moveToOverview()
    default:
      navigationViewController!.navigationView.navigationMapView.navigationCamera.follow()
    }

    self.view.addSubview(navigationViewController!.view)

    // Animate top and bottom banner views presentation.
    let duration = 1.0
    navigationViewController!.navigationView.bottomBannerContainerView.show(duration: duration)
    navigationViewController!.navigationView.topBannerContainerView.show(duration: duration)
  }

  private func addOfflineMap(arguments: NSDictionary?) {

  }

  // Delegate called when user long presses on the map
  @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .ended else { return }

    let location = self.navigationMapView!.mapView.mapboxMap.coordinate(
      for: gesture.location(in: self.navigationMapView!.mapView))

    os_log(
      "Long press gesture recognized. Finding route %{public}@,%{public}@",
      log: OSLog.TurnByTurnView,
      type: .debug,
      location.latitude.description,
      location.longitude.description
    )

    findRoutes(
      locations: [location], waypointNames: [""],
      navigationCameraType: .noChange
    )
  }
  
  @objc func tappedMute(sender: UIButton) {
    isVoiceInstructionsMuted = !isVoiceInstructionsMuted

    if isVoiceInstructionsMuted {
      muteButton.setImage(unmuteIcon, for: .normal)
    } else {
      muteButton.setImage(muteIcon, for: .normal)
    }

    mapboxTurnByTurnEvents?.sendJsonEvent(
      eventType: .muteChanged, data: "{" + "\"muted\":" + String(isVoiceInstructionsMuted) + "}")
  }

  @objc func tappedOverview(sender: UIButton) {
    os_log("Overview tapped", log: OSLog.TurnByTurnNative, type: .debug)
    
    self.navigationMapView!.navigationCamera.moveToOverview()
    self.navigationViewController?.navigationView.navigationMapView.navigationCamera.moveToOverview()
    
    if isInFreeDrive {
      if latestLocation != nil {
        self.navigationMapView!.mapView.camera.ease(
          to: CameraOptions(center: latestLocation!.coordinate, zoom: 16, bearing: 0, pitch: 0),
          duration: 1.3
        )
      }
    } else {
      // placeholder
    }
    
    navigationCameraType = .overview
  }

  @objc func tappedFollow(sender: UIButton) {
    os_log("Follow tapped", log: OSLog.TurnByTurnNative, type: .debug)
    
    self.navigationMapView!.navigationCamera.follow()
    self.navigationViewController?.navigationView.navigationMapView.navigationCamera.follow()
    
    navigationCameraType = .following
  }
}

extension TurnByTurnNative: NavigationMapViewDelegate {
  public func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
    self.currentRouteIndex = self.routes?.firstIndex(of: route) ?? 0
  }
}

extension TurnByTurnNative: NavigationViewControllerDelegate {
  // Delegate called when navigation is cancelled
  public func navigationViewControllerDidDismiss(
    _ navigationViewController: NavigationViewController, byCanceling canceled: Bool
  ) {
    navigationViewController.navigationService.stop()
    let duration = 1.0
    navigationViewController.navigationView.topBannerContainerView.hide(duration: duration)
    navigationViewController.navigationView.bottomBannerContainerView.hide(
      duration: duration,
      animations: {
        navigationViewController.navigationView.wayNameView.alpha = 0.0
        navigationViewController.navigationView.speedLimitView.alpha = 0.0
      },
      completion: { [weak self] _ in
        navigationViewController.dismiss(animated: false) {
          guard let self = self else { return }

          for subview in self.view.subviews {
            subview.removeFromSuperview()
          }

          self.navigationViewController!.navigationService.stop()
          self.navigationMapView!.removeRoutes()
          self.navigationMapView!.removeWaypoints()

          self.routeResponse = nil
          self.currentRouteIndex = 0
          
          self.initializeMapbox()

          os_log("Navigation cancelled", log: OSLog.TurnByTurnNative, type: .debug)
          mapboxTurnByTurnEvents?.sendEvent(eventType: MapboxEventType.navigationCancelled)
        }
      })
  }

  public func navigationViewController(
    _ navigationViewController: NavigationViewController,
    didUpdate progress: RouteProgress,
    with location: CLLocation,
    rawLocation: CLLocation
  ) {
    if navigationCameraType == .following && isInFreeDrive && latestBearing != nil {
      latestLocation = CLLocation(
        coordinate: location.coordinate,
        altitude: location.altitude,
        horizontalAccuracy: location.horizontalAccuracy,
        verticalAccuracy: location.verticalAccuracy,
        course: latestBearing ?? location.course,
        speed: location.speed,
        timestamp: location.timestamp
      )
    } else {
      latestLocation = location
    }

    mapboxTurnByTurnEvents?.sendEvent(
      event: MapboxLocationChangeEvent(
        latitude: rawLocation.coordinate.latitude, longitude: rawLocation.coordinate.longitude))

    mapboxTurnByTurnEvents?.sendEvent(
      event: MapboxEnhancedLocationChangeEvent(
        latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
  }
}

extension TurnByTurnNative: PassiveLocationManagerDelegate {
  public func passiveLocationManagerDidChangeAuthorization(
    _ manager: MapboxCoreNavigation.PassiveLocationManager
  ) {
    // placeholder
  }

  public func passiveLocationManager(
    _ manager: MapboxCoreNavigation.PassiveLocationManager,
    didUpdateLocation location: CLLocation,
    rawLocation: CLLocation
  ) {
    if navigationCameraType == .following && isInFreeDrive && latestBearing != nil {
      latestLocation = CLLocation(
        coordinate: location.coordinate,
        altitude: location.altitude,
        horizontalAccuracy: location.horizontalAccuracy,
        verticalAccuracy: location.verticalAccuracy,
        course: latestBearing ?? location.course,
        speed: location.speed,
        timestamp: location.timestamp
      )
    } else {
      latestLocation = location
    }

    navigationMapView?.moveUserLocation(to: latestLocation!, animated: true)
    // navigationMapView?.mapView.camera.ease(to: CameraOptions(bearing: latestBearing), duration: 1)

    mapboxTurnByTurnEvents?.sendEvent(
      event: MapboxLocationChangeEvent(
        latitude: rawLocation.coordinate.latitude, longitude: rawLocation.coordinate.longitude))

    mapboxTurnByTurnEvents?.sendEvent(
      event: MapboxEnhancedLocationChangeEvent(
        latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
  }

  public func passiveLocationManager(
    _ manager: MapboxCoreNavigation.PassiveLocationManager,
    didUpdateHeading newHeading: CLHeading
  ) {
    if navigationCameraType == .following && isInFreeDrive {
      // self.latestBearing = newHeading.magneticHeading
    }
  }

  public func passiveLocationManager(
    _ manager: MapboxCoreNavigation.PassiveLocationManager,
    didFailWithError error: Error
  ) {
    // placeholder
  }
}
