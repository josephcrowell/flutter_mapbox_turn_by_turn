import Flutter
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import UIKit

public class TurnByTurnNative: NSObject, FlutterStreamHandler {
  var navigationViewController: NavigationViewController? = nil
  var eventSink: FlutterEventSink? = nil

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
  var simulateRoute = false
  var allowsUTurnAtWayPoints: Bool?
  var isOptimized = false
  var language = "en"
  var voiceUnits = "imperial"
  var mapStyleUrlDay: String?
  var mapStyleUrlNight: String?
  var zoom: Double = 13.0
  var tilt: Double = 0.0
  var bearing: Double = 0.0
  var animateBuildRoute = true
  var longPressDestinationEnabled = true
  var shouldReRoute = true
  var navigationDirections: Directions?

  func startNavigation(arguments: NSDictionary?, result: @escaping FlutterResult) {
    waypoints.removeAll()

    guard let oWayPoints = arguments?["wayPoints"] as? NSDictionary else { return }

    var locations = [Location]()

    for item in oWayPoints as NSDictionary {
      let point = item.value as? NSDictionary
      guard let oName = point["Name"] as? String else { return }
      guard let oLatitude = point["Latitude"] as? Double else { return }
      guard let oLongitude = point["Longitude"] as? Double else { return }
      let order = point["Order"] as? Int
      let location = Location(name: oName, latitude: oLatitude, longitude: oLongitude, order: order)
      locations.append(location)
    }

    if !isOptimized {
      // waypoints must be in the right order
      locations.sort(by: { $0.order ?? 0 < $1.order ?? 0 })
    }

    for loc in locations {
      let location = Waypoint(
        coordinate: CLLocationCoordinate2D(latitude: loc.latitude!, longitude: loc.longitude!),
        name: loc.name)
      waypoints.append(location)
    }

    language = arguments?["language"] as? String ?? language
    voiceUnits = arguments?["units"] as? String ?? voiceUnits
    simulateRoute = arguments?["simulateRoute"] as? Bool ?? simulateRoute
    isOptimized = arguments?["isOptimized"] as? Bool ?? isOptimized
    allowsUTurnAtWayPoints = arguments?["allowsUTurnAtWayPoints"] as? Bool
    navigationMode = arguments?["mode"] as? String ?? "drivingWithTraffic"

    if waypoints.count > 3 && arguments?["mode"] == nil {
      navigationMode = "driving"
    }
    mapStyleUrlDay = arguments?["mapStyleUrlDay"] as? String
    mapStyleUrlNight = arguments?["mapStyleUrlNight"] as? String
    if waypoints.count > 0 {
      if isMultipleUniqueRoutes {
        startNavigationWithWayPoints(
          wayPoints: [waypoints.remove(at: 0), waypoints.remove(at: 0)], flutterResult: result)
      } else {
        startNavigationWithWayPoints(wayPoints: waypoints, flutterResult: result)
      }

    }
  }

  func startNavigationWithWayPoints(wayPoints: [Waypoint], flutterResult: @escaping FlutterResult) {
    let simulationMode: SimulationMode = simulateRoute ? .always : .never

    var mode: ProfileIdentifier = .automobileAvoidingTraffic

    if navigationMode == "cycling" {
      mode = .cycling
    } else if navigationMode == "driving" {
      mode = .automobile
    } else if navigationMode == "walking" {
      mode = .walking
    }

    let options = NavigationRouteOptions(waypoints: wayPoints, profileIdentifier: mode)

    if allowsUTurnAtWayPoints != nil {
      options.allowsUTurnAtWaypoint = allowsUTurnAtWayPoints!
    }

    options.distanceMeasurementSystem = voiceUnits == "imperial" ? .imperial : .metric
    options.locale = Locale(identifier: language)

    Directions.shared.calculate(options) { [weak self] (_, result) in
      guard let strongSelf = self else { return }
      strongSelf.options = options
      switch result {
      case .failure(let error):
        strongSelf.sendEvent(eventType: MapBoxEventType.route_build_failed)
        flutterResult("An error occurred while calculating the route \(error.localizedDescription)")
      case .success(let response):
        guard let routes = response.routes else { return }
        //TODO: if more than one route found, give user option to select one: DOES NOT WORK
        if routes.count > 1 && strongSelf.allowRouteSelection {
          // show map to select a specific route
          strongSelf.routes = routes
          let routeOptionsView = RouteOptionsViewController(routes: routes, options: options)

          let flutterViewController =
            UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
          flutterViewController.present(routeOptionsView, animated: true, completion: nil)
        } else {
          let navigationService = MapboxNavigationService(
            routeResponse: response, routeIndex: 0, routeOptions: options,
            simulating: simulationMode)
          var dayStyle = CustomDayStyle()
          if strongSelf.mapStyleUrlDay != nil {
            dayStyle = CustomDayStyle(url: strongSelf.mapStyleUrlDay)
          }
          let nightStyle = CustomNightStyle()
          if strongSelf.mapStyleUrlNight != nil {
            nightStyle.mapStyleURL = URL(string: strongSelf.mapStyleUrlNight!)!
          }
          let navigationOptions = NavigationOptions(
            styles: [dayStyle, nightStyle], navigationService: navigationService)
          strongSelf.startNavigation(
            routeResponse: response, options: options, navOptions: navigationOptions)
        }
      }
    }

  }

  func startNavigation(
    routeResponse: RouteResponse, options: NavigationRouteOptions, navOptions: NavigationOptions
  ) {
    isEmbeddedNavigation = false
    if self.navigationViewController == nil {
      self.navigationViewController = NavigationViewController(
        for: routeResponse, routeIndex: 0, routeOptions: options, navigationOptions: navOptions)
      self.navigationViewController!.modalPresentationStyle = .fullScreen
      self.navigationViewController!.delegate = self
      self.navigationViewController!.navigationMapView!.localizeLabels()
    }
    let flutterViewController =
      UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
    flutterViewController.present(self.navigationViewController!, animated: true, completion: nil)
  }

  func continueNavigationWithWayPoints(wayPoints: [Waypoint]) {
    options?.waypoints = wayPoints
    Directions.shared.calculate(options!) { [weak self] (_, result) in
      guard let strongSelf = self else { return }
      switch result {
      case .failure(let error):
        strongSelf.sendEvent(
          eventType: MapBoxEventType.route_build_failed, data: error.localizedDescription)
      case .success(let response):
        strongSelf.sendEvent(eventType: MapBoxEventType.route_built)
        guard let routes = response.routes else { return }
        //TODO: if more than one route found, give user option to select one: DOES NOT WORK
        if routes.count > 1 && strongSelf.allowRouteSelection {
          //TODO: show map to select a specific route

        } else {
          strongSelf.navigationViewController?.navigationService.start()
        }
      }
    }

  }

  func endNavigation(result: FlutterResult?) {
    sendEvent(eventType: MapBoxEventType.navigation_finished)
    if self.navigationViewController != nil {
      self.navigationViewController?.navigationService.endNavigation(feedback: nil)
      if isEmbeddedNavigation {
        self.navigationViewController?.view.removeFromSuperview()
        self.navigationViewController = nil
      } else {
        self.navigationViewController?.dismiss(
          animated: true,
          completion: {
            self.navigationViewController = nil
            if result != nil {
              result!(true)
            }
          })
      }
    }

  }

  func getLastKnownLocation() -> Waypoint {
    return Waypoint(
      coordinate: CLLocationCoordinate2D(
        latitude: lastKnownLocation!.coordinate.latitude,
        longitude: lastKnownLocation!.coordinate.longitude))
  }

  func sendEvent(eventType: MapboxEventType, data: String = "") {
    let routeEvent = MapBoxRouteEvent(eventType: eventType, data: data)

    let jsonEncoder = JSONEncoder()
    guard let jsonData = try? jsonEncoder.encode(routeEvent) else {
      fatalError(
        "jsonEncoder.encode(routeEvent) is always an instance of \(String)"
          + " here because that is what jsonEncoder will create"
      )
    }
    let eventJson = String(data: jsonData, encoding: String.Encoding.utf8)
    if eventSink != nil {
      eventSink!(eventJson)
    }

  }

  func downloadOfflineRoute(arguments: NSDictionary?, flutterResult: @escaping FlutterResult) {
    /*
        // Create a directions client and store it as a property on the view controller.
        self.navigationDirections = NavigationDirections(credentials: Directions.shared.credentials)

        // Fetch available routing tile versions.
        _ = self.navigationDirections!.fetchAvailableOfflineVersions { (versions, error) in
            guard let version = versions?.first else { return }

            let coordinateBounds = CoordinateBounds(southWest: CLLocationCoordinate2DMake(0, 0), northEast: CLLocationCoordinate2DMake(1, 1))

            // Download tiles using the most recent version.
            _ = self.navigationDirections!.downloadTiles(in: coordinateBounds, version: version) { (url, response, error) in
                guard let url = url else {
                    flutterResult(false)
                    preconditionFailure("Unable to locate temporary file.")
                }

                guard let outputDirectoryURL = Bundle.mapboxCoreNavigation.suggestedTileURL(version: version) else {
                    flutterResult(false)
                    preconditionFailure("No suggested tile URL.")
                }
                try? FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)

                // Unpack downloaded routing tiles.
                NavigationDirections.unpackTilePack(at: url, outputDirectoryURL: outputDirectoryURL, progressHandler: { (totalBytes, bytesRemaining) in
                    // Show unpacking progress.
                }, completionHandler: { (result, error) in
                    // Configure the offline router with the output directory where the tiles have been unpacked.
                    self.navigationDirections!.configureRouter(tilesURL: outputDirectoryURL) { (numberOfTiles) in
                        // Completed, dismiss UI
                        flutterResult(true)
                    }
                })
            }
        }
         */
  }

  // MARK: EventListener Delegates
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

extension TurnByTurnViewFactory: NavigationViewControllerDelegate {
  // MARK: NavigationViewController Delegates
  public func navigationViewController(
    _ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress,
    with location: CLLocation, rawLocation: CLLocation
  ) {
    lastKnownLocation = location
    distanceRemaining = progress.distanceRemaining
    durationRemaining = progress.durationRemaining
    sendEvent(eventType: MapBoxEventType.navigation_running)
    if eventSink != nil {
      let jsonEncoder = JSONEncoder()

      let progressEvent = MapBoxRouteProgressEvent(progress: progress)
      guard let progressEventJsonData = try? jsonEncoder.encode(progressEvent) else {
        fatalError(
          "jsonEncoder.encode(routeEvent) is always an instance of \(String)"
            + " here because that is what jsonEncoder will create"
        )
      }
      let progressEventJson = String(data: progressEventJsonData, encoding: String.Encoding.ascii)

      eventSink!(progressEventJson)

      if progress.isFinalLeg && progress.currentLegProgress.userHasArrivedAtWaypoint {
        eventSink = nil
      }
    }
  }

  public func navigationViewController(
    _ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint
  ) -> Bool {

    sendEvent(eventType: MapBoxEventType.on_arrival, data: "true")
    if !waypoints.isEmpty && isMultipleUniqueRoutes {
      continueNavigationWithWayPoints(wayPoints: [getLastKnownLocation(), waypoints.remove(at: 0)])
      return false
    }

    return true
  }

  public func navigationViewControllerDidDismiss(
    _ navigationViewController: NavigationViewController, byCanceling canceled: Bool
  ) {
    if canceled {
      sendEvent(eventType: MapBoxEventType.navigation_cancelled)
    }
    endNavigation(result: nil)
  }

  public func navigationViewController(
    _ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation
  ) -> Bool {
    return shouldReRoute
  }
}
