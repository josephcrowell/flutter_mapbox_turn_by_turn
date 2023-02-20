import CoreLocation
import Flutter
import UIKit

class TurnByTurnView: TurnByTurnNative, FlutterPlatformView {
  let frame: CGRect
  let viewId: Int64

  let messenger: FlutterBinaryMessenger
  let methodChannel: FlutterMethodChannel
  let eventChannel: FlutterEventChannel

  var navigationMapView: TurnByTurnView!
  var arguments: NSDictionary?

  var routeResponse: RouteResponse?
  var selectedRouteIndex = 0
  var routeOptions: NavigationRouteOptions?
  var navigationService: NavigationService!

  var mapInitialized = false
  var locationManager = CLLocationManager()

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger?
  ) {
    self.frame = frame
    self.viewId = viewId
    guard self.arguments = args as? NSDictionary? else {
      fatalError(
        "args is always an instance of \(NSDictionary?) here because that is the type passed by flutter for arguments…"
      )
    }

    super.messenger = messenger
    super.methodChannel =
      FlutterMethodChannel(
        name: "flutter_mapbox_turn_by_turn/map_view/method",
        binaryMessenger: messenger
      )
    super.eventChannel =
      FlutterEventChannel(
        name: "flutter_mapbox_turn_by_turn/map_view/events",
        binaryMessenger: messenger
      )

    super.init()

    self.eventChannel.setStreamHandler(self)

    self.channel.setMethodCallHandler { [weak self] (call, result) in

      guard let strongSelf = self else { return }

      guard let arguments = call.arguments as? NSDictionary else {
        fatalError(
          "call.arguments is always an instance of \(NSDictionary?) here because that is the type passed by flutter for arguments…"
        )
      }

      switch call.method {
      case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
      case "buildRoute":
        strongSelf.buildRoute(arguments: arguments, flutterResult: result)
      case "clearRoute":
        strongSelf.clearRoute(arguments: arguments, result: result)
      case "getDistanceRemaining":
        result(strongSelf._distanceRemaining)
      case "getDurationRemaining":
        result(strongSelf._durationRemaining)
      case "finishNavigation":
        strongSelf.endNavigation(result: result)
      case "startNavigation":
        strongSelf.startEmbeddedNavigation(arguments: arguments, result: result)
      case "reCenter":
        // This is used to recenter the map after user action during navigation
        strongSelf.navigationMapView.navigationCamera.follow()
      default:
        result("method is not implemented")
      }
    }
  }

  func view() -> UIView {
    if mapInitialized {
      return navigationMapView
    }

    setupMapView()

    return navigationMapView
  }

  private func setupMapView() {
    navigationMapView = TurnByTurnView(frame: frame)
    navigationMapView.delegate = self

    if self.arguments != nil {
      _language = arguments?["language"] as? String ?? _language
      _voiceUnits = arguments?["units"] as? String ?? _voiceUnits
      _simulateRoute = arguments?["simulateRoute"] as? Bool ?? _simulateRoute
      _isOptimized = arguments?["isOptimized"] as? Bool ?? _isOptimized
      _allowsUTurnAtWayPoints = arguments?["allowsUTurnAtWayPoints"] as? Bool
      _navigationMode = arguments?["mode"] as? String ?? "drivingWithTraffic"
      _mapStyleUrlDay = arguments?["mapStyleUrlDay"] as? String
      _zoom = arguments?["zoom"] as? Double ?? _zoom
      _bearing = arguments?["bearing"] as? Double ?? _bearing
      _tilt = arguments?["tilt"] as? Double ?? _tilt
      _animateBuildRoute = arguments?["animateBuildRoute"] as? Bool ?? _animateBuildRoute
      _longPressDestinationEnabled =
        arguments?["longPressDestinationEnabled"] as? Bool ?? _longPressDestinationEnabled

      if _mapStyleUrlDay != nil {
        navigationMapView.mapView.mapboxMap.style.uri = StyleURI.init(
          url: URL(string: _mapStyleUrlDay!)!)
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
        moveCameraToCoordinates(latitude: initialLatitude!, longitude: initialLongitude!)
      }

    }

    if _longPressDestinationEnabled {
      let gesture = UILongPressGestureRecognizer(
        target: self, action: #selector(handleLongPress(_:)))
      gesture.delegate = self
      navigationMapView?.addGestureRecognizer(gesture)
    }

  }

  func clearRoute(arguments: NSDictionary?, result: @escaping FlutterResult) {
    if routeResponse == nil {
      return
    }

    setupMapView()
    self.view().setNeedsDisplay()

    routeResponse = nil
    sendEvent(eventType: MapboxEventType.navigation_cancelled)
  }

  func buildRoute(arguments: NSDictionary?, flutterResult: @escaping FlutterResult) {
    isEmbeddedNavigation = true
    sendEvent(eventType: MapboxEventType.route_building)

    guard let oWayPoints = arguments?["wayPoints"] as? NSDictionary else { return }

    var locations = [Location]()

    for item in oWayPoints as NSDictionary {
      guard let point = item.value as? NSDictionary else {
        fatalError(
          "item.value is always an instance of \(NSDictionary?) here because that is the type passed by flutter for arguments…"
        )
      }
      guard let oName = point["Name"] as? String else { return }
      guard let oLatitude = point["Latitude"] as? Double else { return }
      guard let oLongitude = point["Longitude"] as? Double else { return }
      let order = point["Order"] as? Int
      let location = Location(name: oName, latitude: oLatitude, longitude: oLongitude, order: order)
      locations.append(location)
    }

    if !_isOptimized {
      // waypoints must be in the right order
      locations.sort(by: { $0.order ?? 0 < $1.order ?? 0 })
    }

    for loc in locations {
      let location = Waypoint(
        coordinate: CLLocationCoordinate2D(latitude: loc.latitude!, longitude: loc.longitude!),
        coordinateAccuracy: -1, name: loc.name)
      _wayPoints.append(location)
    }

    _language = arguments?["language"] as? String ?? _language
    _voiceUnits = arguments?["units"] as? String ?? _voiceUnits
    _simulateRoute = arguments?["simulateRoute"] as? Bool ?? _simulateRoute
    _isOptimized = arguments?["isOptimized"] as? Bool ?? _isOptimized
    _allowsUTurnAtWayPoints = arguments?["allowsUTurnAtWayPoints"] as? Bool
    _navigationMode = arguments?["mode"] as? String ?? "drivingWithTraffic"
    if _wayPoints.count > 3 && arguments?["mode"] == nil {
      _navigationMode = "driving"
    }
    _mapStyleUrlDay = arguments?["mapStyleUrlDay"] as? String
    _mapStyleUrlNight = arguments?["mapStyleUrlNight"] as? String

    var mode: ProfileIdentifier = .automobileAvoidingTraffic

    if _navigationMode == "cycling" {
      mode = .cycling
    } else if _navigationMode == "driving" {
      mode = .automobile
    } else if _navigationMode == "walking" {
      mode = .walking
    }

    let routeOptions = NavigationRouteOptions(waypoints: _wayPoints, profileIdentifier: mode)

    if _allowsUTurnAtWayPoints != nil {
      routeOptions.allowsUTurnAtWaypoint = _allowsUTurnAtWayPoints!
    }

    routeOptions.distanceMeasurementSystem = _voiceUnits == "imperial" ? .imperial : .metric
    routeOptions.locale = Locale(identifier: _language)
    self.routeOptions = routeOptions

    // Generate the route object and draw it on the map
    _ = Directions.shared.calculate(routeOptions) { [weak self] (session, result) in

      guard case let .success(response) = result, let strongSelf = self else {
        flutterResult(false)
        self?.sendEvent(eventType: MapboxEventType.route_build_failed)
        return
      }
      strongSelf.routeResponse = response
      strongSelf.sendEvent(eventType: MapboxEventType.route_built)
      strongSelf.navigationMapView?.showcase(
        response.routes!, routesPresentationStyle: .all(shouldFit: true), animated: true)
      flutterResult(true)
    }
  }

  func startEmbeddedNavigation(arguments: NSDictionary?, result: @escaping FlutterResult) {
    guard let response = self.routeResponse else { return }
    let navLocationManager =
      self._simulateRoute
      ? SimulatedLocationManager(route: response.routes!.first!) : NavigationLocationManager()
    navigationService = MapboxNavigationService(
      routeResponse: response,
      routeIndex: selectedRouteIndex,
      routeOptions: routeOptions!,
      routingProvider: MapboxRoutingProvider(.hybrid),
      credentials: NavigationSettings.shared.directions.credentials,
      locationSource: navLocationManager,
      simulating: self._simulateRoute ? .always : .onPoorGPS)
    navigationService.delegate = self

    var dayStyle = CustomDayStyle()
    if _mapStyleUrlDay != nil {
      dayStyle = CustomDayStyle(url: _mapStyleUrlDay)
    }
    let nightStyle = CustomNightStyle()
    if _mapStyleUrlNight != nil {
      nightStyle.mapStyleURL = URL(string: _mapStyleUrlNight!)!
    }
    let navigationOptions = NavigationOptions(
      styles: [dayStyle, nightStyle], navigationService: navigationService)
    _navigationViewController = NavigationViewController(
      for: response, routeIndex: selectedRouteIndex, routeOptions: routeOptions!,
      navigationOptions: navigationOptions)
    _navigationViewController!.delegate = self

    guard
      let flutterViewController =
        UIApplication.shared.delegate?.window?!.rootViewController as? FlutterViewController
    else {
      fatalError(
        "flutterViewController is always an instance of \(FlutterViewController) here…"
      )
    }
    flutterViewController.addChild(_navigationViewController!)

    let container = self.view()
    container.addSubview(_navigationViewController!.view)
    _navigationViewController!.view.translatesAutoresizingMaskIntoConstraints = false
    constraintsWithPaddingBetween(
      holderView: container, topView: _navigationViewController!.view, padding: 0.0)
    flutterViewController.didMove(toParent: flutterViewController)
    result(true)

  }

  func constraintsWithPaddingBetween(holderView: UIView, topView: UIView, padding: CGFloat) {
    guard holderView.subviews.contains(topView) else {
      return
    }
    topView.translatesAutoresizingMaskIntoConstraints = false
    let pinTop = NSLayoutConstraint(
      item: topView, attribute: .top, relatedBy: .equal,
      toItem: holderView, attribute: .top, multiplier: 1.0, constant: padding)
    let pinBottom = NSLayoutConstraint(
      item: topView, attribute: .bottom, relatedBy: .equal,
      toItem: holderView, attribute: .bottom, multiplier: 1.0, constant: padding)
    let pinLeft = NSLayoutConstraint(
      item: topView, attribute: .left, relatedBy: .equal,
      toItem: holderView, attribute: .left, multiplier: 1.0, constant: padding)
    let pinRight = NSLayoutConstraint(
      item: topView, attribute: .right, relatedBy: .equal,
      toItem: holderView, attribute: .right, multiplier: 1.0, constant: padding)
    holderView.addConstraints([pinTop, pinBottom, pinLeft, pinRight])
  }

  func moveCameraToCoordinates(latitude: Double, longitude: Double) {
    let navigationViewportDataSource = NavigationViewportDataSource(
      navigationMapView.mapView, viewportDataSourceType: .raw)
    navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
    navigationViewportDataSource.followingMobileCamera.center = CLLocationCoordinate2D(
      latitude: latitude, longitude: longitude)
    navigationViewportDataSource.followingMobileCamera.zoom = _zoom
    navigationViewportDataSource.followingMobileCamera.bearing = _bearing
    navigationViewportDataSource.followingMobileCamera.pitch = 15
    navigationViewportDataSource.followingMobileCamera.padding = .zero
    navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
  }

  func moveCameraToCenter() {
    var duration = 5.0
    if !_animateBuildRoute {
      duration = 0.0
    }

    let navigationViewportDataSource = NavigationViewportDataSource(
      navigationMapView.mapView, viewportDataSourceType: .raw)
    navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
    navigationViewportDataSource.followingMobileCamera.zoom = 13.0
    navigationViewportDataSource.followingMobileCamera.pitch = 15
    navigationViewportDataSource.followingMobileCamera.padding = .zero
    //navigationViewportDataSource.followingMobileCamera.center = mapView?.centerCoordinate
    navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource

    // Create a camera that rotates around the same center point, rotating 180°.
    // `fromDistance:` is meters above mean sea level that an eye would have to be in order to see what the map view is showing.
    //let camera = NavigationCamera( Camera(lookingAtCenter: mapView.centerCoordinate, altitude: 2500, pitch: 15, heading: 180)

    // Animate the camera movement over 5 seconds.
    //navigationMapView.mapView.mapboxMap.setCamera(to: CameraOptions(center: navigationMapView.mapView.ma, zoom: 13.0))
    //(camera, withDuration: duration, animationTimingFunction: CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
  }

}

extension TurnByTurnView: NavigationServiceDelegate {

  public func navigationService(
    _ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation,
    rawLocation: CLLocation
  ) {
    _lastKnownLocation = location
    _distanceRemaining = progress.distanceRemaining
    _durationRemaining = progress.durationRemaining
    sendEvent(eventType: MapboxEventType.navigation_running)
    //_currentLegDescription =  progress.currentLeg.description
    if _eventSink != nil {
      let jsonEncoder = JSONEncoder()

      let progressEvent = MapBoxRouteProgressEvent(progress: progress)
      // swiftlint:disable:next force_try
      let progressEventJsonData = try! jsonEncoder.encode(progressEvent)
      let progressEventJson = String(data: progressEventJsonData, encoding: String.Encoding.ascii)

      _eventSink!(progressEventJson)

      if progress.isFinalLeg && progress.currentLegProgress.userHasArrivedAtWaypoint {
        _eventSink = nil
      }
    }
  }
}

extension TurnByTurnView: TurnByTurnViewDelegate {

  //    public func mapView(_ mapView: TurnByTurnView, didFinishLoading style: Style) {
  //        _mapInitialized = true
  //        sendEvent(eventType: MapboxEventType.map_ready)
  //    }

  public func navigationMapView(_ mapView: TurnByTurnView, didSelect route: Route) {
    self.selectedRouteIndex = self.routeResponse!.routes?.firstIndex(of: route) ?? 0
  }

  public func mapViewDidFinishLoadingMap(_ mapView: TurnByTurnView) {
    // Wait for the map to load before initiating the first camera movement.
    moveCameraToCenter()
  }

}

extension TurnByTurnView: UIGestureRecognizerDelegate {

  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    return true
  }

  @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .ended else { return }
    let location = navigationMapView.mapView.mapboxMap.coordinate(
      for: gesture.location(in: navigationMapView.mapView))
    requestRoute(destination: location)
  }

  func requestRoute(destination: CLLocationCoordinate2D) {
    sendEvent(eventType: MapboxEventType.route_building)

    guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }
    let location = CLLocation(
      latitude: userLocation.coordinate.latitude,
      longitude: userLocation.coordinate.longitude)
    let userWaypoint = Waypoint(
      location: location, heading: userLocation.heading, name: "Current Location")
    let destinationWaypoint = Waypoint(coordinate: destination)

    let routeOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])

    Directions.shared.calculate(routeOptions) { [weak self] (session, result) in

      if let strongSelf = self {

        switch result {
        case .failure(let error):
          print(error.localizedDescription)
          strongSelf.sendEvent(eventType: MapboxEventType.route_build_failed)
        case .success(let response):
          guard let routes = response.routes, let route = response.routes?.first else {
            strongSelf.sendEvent(eventType: MapboxEventType.route_build_failed)
            return
          }
          strongSelf.sendEvent(eventType: MapboxEventType.route_built)
          strongSelf.routeOptions = routeOptions
          strongSelf._routes = routes
          strongSelf.navigationMapView.show(routes)
          strongSelf.navigationMapView.showWaypoints(on: route)
        }
      }
    }
  }
}
