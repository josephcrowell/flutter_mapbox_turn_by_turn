package au.com.annon.flutter_mapbox_turn_by_turn.ui

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.location.Location
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.ViewTreeLifecycleOwner
import au.com.annon.flutter_mapbox_turn_by_turn.R
import au.com.annon.flutter_mapbox_turn_by_turn.databinding.TurnByTurnNativeBinding
import au.com.annon.flutter_mapbox_turn_by_turn.models.*
import au.com.annon.flutter_mapbox_turn_by_turn.utilities.PluginUtilities
import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.api.directions.v5.models.RouteOptions
import com.mapbox.bindgen.Expected
import com.mapbox.bindgen.Value
import com.mapbox.common.*
import com.mapbox.geojson.Geometry
import com.mapbox.geojson.Point
import com.mapbox.geojson.Polygon
import com.mapbox.maps.*
import com.mapbox.maps.plugin.LocationPuck2D
import com.mapbox.maps.plugin.animation.camera
import com.mapbox.maps.plugin.compass.compass
import com.mapbox.maps.plugin.gestures.gestures
import com.mapbox.maps.plugin.locationcomponent.location
import com.mapbox.maps.plugin.scalebar.scalebar
import com.mapbox.navigation.base.TimeFormat
import com.mapbox.navigation.base.extensions.applyDefaultNavigationOptions
import com.mapbox.navigation.base.extensions.applyLanguageAndVoiceUnitOptions
import com.mapbox.navigation.base.formatter.DistanceFormatterOptions
import com.mapbox.navigation.base.formatter.UnitType
import com.mapbox.navigation.base.options.NavigationOptions
import com.mapbox.navigation.base.options.RoutingTilesOptions
import com.mapbox.navigation.base.route.*
import com.mapbox.navigation.base.trip.model.RouteLegProgress
import com.mapbox.navigation.base.trip.model.RouteProgress
import com.mapbox.navigation.core.MapboxNavigation
import com.mapbox.navigation.core.arrival.ArrivalObserver
import com.mapbox.navigation.core.directions.session.RoutesObserver
import com.mapbox.navigation.core.formatter.MapboxDistanceFormatter
import com.mapbox.navigation.core.lifecycle.MapboxNavigationApp
import com.mapbox.navigation.core.lifecycle.requireMapboxNavigation
import com.mapbox.navigation.core.trip.session.LocationMatcherResult
import com.mapbox.navigation.core.trip.session.LocationObserver
import com.mapbox.navigation.core.trip.session.RouteProgressObserver
import com.mapbox.navigation.core.trip.session.VoiceInstructionsObserver
import com.mapbox.navigation.ui.maneuver.api.MapboxManeuverApi
import com.mapbox.navigation.ui.maneuver.view.MapboxManeuverView
import com.mapbox.navigation.ui.maps.camera.NavigationCamera
import com.mapbox.navigation.ui.maps.camera.data.MapboxNavigationViewportDataSource
import com.mapbox.navigation.ui.maps.camera.data.ViewportDataSourceUpdateObserver
import com.mapbox.navigation.ui.maps.camera.lifecycle.NavigationBasicGesturesHandler
import com.mapbox.navigation.ui.maps.camera.state.NavigationCameraState
import com.mapbox.navigation.ui.maps.camera.state.NavigationCameraStateChangedObserver
import com.mapbox.navigation.ui.maps.camera.transition.NavigationCameraTransitionOptions
import com.mapbox.navigation.ui.maps.location.NavigationLocationProvider
import com.mapbox.navigation.ui.maps.route.arrow.api.MapboxRouteArrowApi
import com.mapbox.navigation.ui.maps.route.arrow.api.MapboxRouteArrowView
import com.mapbox.navigation.ui.maps.route.arrow.model.RouteArrowOptions
import com.mapbox.navigation.ui.maps.route.line.api.MapboxRouteLineApi
import com.mapbox.navigation.ui.maps.route.line.api.MapboxRouteLineView
import com.mapbox.navigation.ui.maps.route.line.model.*
import com.mapbox.navigation.ui.tripprogress.api.MapboxTripProgressApi
import com.mapbox.navigation.ui.tripprogress.model.*
import com.mapbox.navigation.ui.tripprogress.view.MapboxTripProgressView
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.roundToInt


/**
 * Before running the plugin make sure you have put your access_token in the correct place
 * inside [app/src/main/res/values/mapbox_access_token.xml]. If not present then add this file
 * at the location mentioned above and add the following content to it
 *
 * <?xml version="1.0" encoding="utf-8"?>
 * <resources xmlns:tools="http://schemas.android.com/tools">
 *     <string name="mapbox_access_token"><PUT_YOUR_ACCESS_TOKEN_HERE></string>
 * </resources>
 *
 * How to use this plugin:
 * - The guidance will start to the selected destination starting at the device's real location.
 * - At any point in time you can finish guidance or select a new destination.
 * - You can use buttons to mute/unmute voice instructions, recenter the camera, or show the route overview.
 */

class NavigationCameraType {
    companion object {
        const val NOCHANGE: String = "noChange"
        const val OVERVIEW: String = "overview"
        const val FOLLOWING: String = "following"
    }
}

open class TurnByTurnNative(
    private val pluginActivity: Activity,
    private val pluginContext: Context,
    val binding: TurnByTurnNativeBinding,
    private val lifecycleRegistry: LifecycleRegistry,
    private var messenger: BinaryMessenger?,
    creationParams: Map<String?, Any?>?
) : FlutterFragment(),
    SensorEventListener,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    var eventSink: EventChannel.EventSink? = null

    private var mapboxTurnByTurnEvents: MapboxTurnByTurnEvents? = null

    var methodChannel: MethodChannel? = null
    var eventChannel: EventChannel? = null

    private val darkThreshold = 1.0f
    private var lightValue = 1.1f
    private var distanceRemaining: Float? = null
    private var durationRemaining: Double? = null
    private var navigationStarted: Boolean = false
    var observersRegistered: Boolean = false

    // flutter creation parameters
    private val zoom: Double?
    private val pitch: Double?
    private var disableGesturesWhenFollowing: Boolean? = null
    private val navigateOnLongClick: Boolean?
    private val muted: Boolean?
    private val showMuteButton: Boolean?
    private val showStopButton: Boolean?
    private val navigationCameraType: String?
    private val routeProfile: String
    private val language: String
    private val showAlternativeRoutes: Boolean
    private val allowUTurnsAtWaypoints: Boolean
    private val mapStyleUrlDay: String?
    private val mapStyleUrlNight: String?
    private val routeCasingColor: String
    private val routeDefaultColor: String
    private val restrictedRoadColor: String
    private val routeLineTraveledColor: String
    private val routeLineTraveledCasingColor: String
    private val routeClosureColor: String
    private val routeLowCongestionColor: String
    private val routeModerateCongestionColor: String
    private val routeHeavyCongestionColor: String
    private val routeSevereCongestionColor: String
    private val routeUnknownCongestionColor: String

    init {
        Log.d("TurnByTurnNative", "Constructor called")

        methodChannel = MethodChannel(messenger!!, "flutter_mapbox_turn_by_turn/map_view/method")
        eventChannel = EventChannel(messenger, "flutter_mapbox_turn_by_turn/map_view/events")

        zoom = creationParams?.get("zoom") as? Double
        pitch = creationParams?.get("pitch") as? Double
        disableGesturesWhenFollowing = creationParams?.get("disableGesturesWhenFollowing") as? Boolean
        navigateOnLongClick = creationParams?.get("navigateOnLongClick") as? Boolean
        muted = creationParams?.get("muted") as? Boolean
        showMuteButton = creationParams?.get("showMuteButton") as? Boolean
        showStopButton = creationParams?.get("showStopButton") as? Boolean
        showSpeedIndicator = creationParams?.get("showSpeedIndicator") as Boolean
        navigationCameraType = creationParams["navigationCameraType"] as String
        routeProfile = creationParams["routeProfile"] as String
        language = creationParams["language"] as String
        measurementUnits = creationParams["measurementUnits"] as String
        speedThreshold = creationParams["speedThreshold"] as Int
        showAlternativeRoutes = creationParams["showAlternativeRoutes"] as Boolean
        allowUTurnsAtWaypoints = creationParams["allowUTurnsAtWaypoints"] as Boolean
        mapStyleUrlDay = creationParams["mapStyleUrlDay"] as? String
        mapStyleUrlNight = creationParams["mapStyleUrlNight"] as? String
        routeCasingColor = creationParams["routeCasingColor"] as String
        routeDefaultColor = creationParams["routeDefaultColor"] as String
        restrictedRoadColor = creationParams["restrictedRoadColor"] as String
        routeLineTraveledColor = creationParams["routeLineTraveledColor"] as String
        routeLineTraveledCasingColor = creationParams["routeLineTraveledCasingColor"] as String
        routeClosureColor = creationParams["routeClosureColor"] as String
        routeLowCongestionColor = creationParams["routeLowCongestionColor"] as String
        routeModerateCongestionColor = creationParams["routeModerateCongestionColor"] as String
        routeHeavyCongestionColor = creationParams["routeHeavyCongestionColor"] as String
        routeSevereCongestionColor = creationParams["routeSevereCongestionColor"] as String
        routeUnknownCongestionColor = creationParams["routeUnknownCongestionColor"] as String
    }

    companion object {
        private const val BUTTON_ANIMATION_DURATION = 1500L

        private var measurementUnits: String = "metric"
        private var speedThreshold: Int = 5
        private var showSpeedIndicator: Boolean = true
    }

    /**
     * Mapbox Maps access token.
     */
    private lateinit var accessToken: String

    /**
     * Mapbox Maps entry point obtained from the [MapView].
     * You need to get a new reference to this object whenever the [MapView] is recreated.
     */
    private var mapboxMap: MapboxMap? = null

    private val mapboxNavigation: MapboxNavigation by requireMapboxNavigation()

    /**
     * Used to execute camera transitions based on the data generated by the [viewportDataSource].
     * This includes transitions from route overview to route following and continuously updating the camera as the location changes.
     */
    private var navigationCamera: NavigationCamera? = null

    /**
     * Produces the camera frames based on the location and routing data for the [navigationCamera] to execute.
     */
    private var viewportDataSource: MapboxNavigationViewportDataSource? = null

    /**
     * Mapbox offline manager. There should only be one instance of this object for the app.
     * The Offline Manager API provides a configuration interface and entrypoint for offline map functionality.
     * It is used to manage style packs and to produce tileset descriptors that can be used with a tile store.
     */
    private lateinit var offlineManager: OfflineManager

    /*
     * Below are generated camera padding values to ensure that the route fits well on screen while
     * other elements are overlaid on top of the map (including instruction view, buttons, etc.)
     */
    private val pixelDensity = Resources.getSystem().displayMetrics.density
    private val overviewPadding: EdgeInsets by lazy {
        EdgeInsets(
            140.0 * pixelDensity,
            40.0 * pixelDensity,
            120.0 * pixelDensity,
            40.0 * pixelDensity
        )
    }
    private val landscapeOverviewPadding: EdgeInsets by lazy {
        EdgeInsets(
            30.0 * pixelDensity,
            380.0 * pixelDensity,
            110.0 * pixelDensity,
            20.0 * pixelDensity
        )
    }
    private val followingPadding: EdgeInsets by lazy {
        EdgeInsets(
            180.0 * pixelDensity,
            40.0 * pixelDensity,
            150.0 * pixelDensity,
            40.0 * pixelDensity
        )
    }
    private val landscapeFollowingPadding: EdgeInsets by lazy {
        EdgeInsets(
            30.0 * pixelDensity,
            380.0 * pixelDensity,
            110.0 * pixelDensity,
            40.0 * pixelDensity
        )
    }

    /**
     * Generates updates for the [MapboxManeuverView] to display the upcoming maneuver instructions
     * and remaining distance to the maneuver point.
     */
    private lateinit var maneuverApi: MapboxManeuverApi

    /**
     * Generates updates for the [MapboxTripProgressView] that include remaining time and distance to the destination.
     */
    private lateinit var tripProgressApi: MapboxTripProgressApi

    /**
     * Generates updates for the [routeLineView] with the geometries and properties of the routes that should be drawn on the map.
     */
    private lateinit var routeLineApi: MapboxRouteLineApi

    /**
     * Draws route lines on the map based on the data from the [routeLineApi]
     */
    private lateinit var routeLineView: MapboxRouteLineView

    /**
     * Generates updates for the [routeArrowView] with the geometries and properties of maneuver arrows that should be drawn on the map.
     */
    private val routeArrowApi: MapboxRouteArrowApi = MapboxRouteArrowApi()

    /**
     * Draws maneuver arrows on the map based on the data [routeArrowApi].
     */
    private lateinit var routeArrowView: MapboxRouteArrowView

    /**
     * Stores and updates the state of whether the voice instructions should be played as they come or muted.
     */
    private var isVoiceInstructionsMuted = false
        set(value) {
            field = value
            if (value) {
                binding.soundButton.muteAndExtend(BUTTON_ANIMATION_DURATION)
            } else {
                binding.soundButton.unmuteAndExtend(BUTTON_ANIMATION_DURATION)
            }
        }

    /**
     * Observes when a new voice instruction should be played.
     */
    private val voiceInstructionsObserver = VoiceInstructionsObserver { voiceInstructions ->
        // if voice instructions are muted, don't waste bandwidth and processing power playing back silent instructions
        if(!isVoiceInstructionsMuted) {
            methodChannel?.invokeMethod("playVoiceInstruction", voiceInstructions.announcement())
        }
    }

    /**
     * [NavigationLocationProvider] is a utility class that helps to provide location updates generated by the Navigation SDK
     * to the Maps SDK in order to update the user location indicator on the map.
     */
    private var navigationLocationProvider: NavigationLocationProvider? = NavigationLocationProvider()

    /**
     * Gets notified with location updates.
     *
     * Exposes raw updates coming directly from the location services
     * and the updates enhanced by the Navigation SDK (cleaned up and matched to the road).
     */
    private val locationObserver = object : LocationObserver {
        var firstLocationUpdateReceived = false

        override fun onNewRawLocation(rawLocation: Location) {
            mapboxTurnByTurnEvents?.sendEvent(MapboxLocationChangeEvent(rawLocation))
        }

        override fun onNewLocationMatcherResult(locationMatcherResult: LocationMatcherResult) {
            val enhancedLocation = locationMatcherResult.enhancedLocation
            // update location puck's position on the map
            navigationLocationProvider!!.changePosition(
                location = enhancedLocation,
                keyPoints = locationMatcherResult.keyPoints,
            )

            if(showSpeedIndicator) {
                var speedLimit = locationMatcherResult.speedLimit?.speedKmph
                if(speedLimit != null) {
                    if(measurementUnits == DirectionsCriteria.METRIC) {
                        // speed in Kph
                        val speed = (enhancedLocation.speed * 3.6).toInt()
                        val mSpeedLimit = speedLimit + speedThreshold

                        // We should be showing metric speed
                        pluginActivity.runOnUiThread {
                            "$speed\nkph".also { binding.speedView.text = it }
                            if (speed > mSpeedLimit) {
                                binding.speedView.background = ContextCompat.getDrawable(
                                    pluginContext,
                                    R.drawable.speed_limit_speeding
                                )
                            } else {
                                binding.speedView.background = ContextCompat.getDrawable(
                                    pluginContext,
                                    R.drawable.speed_limit_normal
                                )
                            }
                        }
                    } else {
                        // We should be showing imperial speed
                        val speed = (enhancedLocation.speed * 3.6 / 1.609).toInt()
                        speedLimit = (speedLimit.toFloat() / 1.609).toInt()
                        val mSpeedLimit = speedLimit + speedThreshold

                        // We should be showing metric speed
                        pluginActivity.runOnUiThread {
                            "$speed\nmph".also { binding.speedView.text = it }
                            if (speed > mSpeedLimit) {
                                binding.speedView.background = ContextCompat.getDrawable(
                                    pluginContext,
                                    R.drawable.speed_limit_speeding
                                )
                            } else {
                                binding.speedView.background = ContextCompat.getDrawable(
                                    pluginContext,
                                    R.drawable.speed_limit_normal
                                )
                            }
                        }
                    }
                } else {
                    if(measurementUnits == DirectionsCriteria.METRIC) {
                        // speed in Kph
                        val speed = (enhancedLocation.speed * 3.6).toInt()

                        // We should be showing metric speed
                        pluginActivity.runOnUiThread {
                            "$speed\nkph".also { binding.speedView.text = it }
                            binding.speedView.background = ContextCompat.getDrawable(
                                pluginContext,
                                R.drawable.speed_limit_normal
                            )
                        }
                    } else {
                        // We should be showing imperial speed
                        val speed = (enhancedLocation.speed * 3.6 / 1.609).toInt()

                        // We should be showing metric speed
                        pluginActivity.runOnUiThread {
                            "$speed\nmph".also { binding.speedView.text = it }
                            binding.speedView.background = ContextCompat.getDrawable(
                                pluginContext,
                                R.drawable.speed_limit_normal
                            )
                        }
                    }
                }
            }

            // update camera position to account for new location
            viewportDataSource!!.onLocationChanged(enhancedLocation)
            viewportDataSource!!.evaluate()
            mapboxTurnByTurnEvents?.sendEvent(MapboxEnhancedLocationChangeEvent(enhancedLocation))

            // if this is the first location update the activity has received,
            // it's best to immediately move the camera to the current user location
            if (!firstLocationUpdateReceived) {
                firstLocationUpdateReceived = true
                navigationCamera!!.requestNavigationCameraToOverview(
                    stateTransitionOptions = NavigationCameraTransitionOptions.Builder()
                        .maxDuration(0) // instant transition
                        .build()
                )
                if(disableGesturesWhenFollowing == true) {
                    toggleGestures(true)
                }
            }
        }
    }

    /**
     * Gets notified with progress along the currently active route.
     */
    private val routeProgressObserver = RouteProgressObserver { routeProgress ->
        // update the camera position to account for the progressed fragment of the route
        viewportDataSource!!.onRouteProgressChanged(routeProgress)
        viewportDataSource!!.evaluate()

        // draw the upcoming maneuver arrow on the map
        val style = mapboxMap!!.getStyle()
        if (style != null) {
            val maneuverArrowResult = routeArrowApi.addUpcomingManeuverArrow(routeProgress)
            routeArrowView.renderManeuverUpdate(style, maneuverArrowResult)
        }

        // update top banner with maneuver instructions
        val maneuvers = maneuverApi.getManeuvers(routeProgress)
        maneuvers.fold(
            { error ->
                Toast.makeText(
                    pluginContext,
                    error.errorMessage,
                    Toast.LENGTH_SHORT
                ).show()
            },
            {
                binding.maneuverView.visibility = View.VISIBLE
                binding.maneuverView.renderManeuvers(maneuvers)
            }
        )

        if(navigationStarted) {
            try {
                distanceRemaining = routeProgress.distanceRemaining
                durationRemaining = routeProgress.durationRemaining

                val progressEvent = MapboxProgressChangeEvent(routeProgress)
                mapboxTurnByTurnEvents?.sendEvent(progressEvent)

            } catch (_: java.lang.Exception) {

            }
        }

        // update bottom trip progress summary
        binding.tripProgressView.render(
            tripProgressApi.getTripProgress(routeProgress)
        )
    }

    private var navigationBasicGesturesHandler: NavigationBasicGesturesHandler? = null

    private val navigationCameraStateChangedObserver = NavigationCameraStateChangedObserver { navigationCameraState ->
        // shows/hide the recenter button depending on the camera state
        when (navigationCameraState) {
            NavigationCameraState.TRANSITION_TO_FOLLOWING,
            NavigationCameraState.FOLLOWING -> binding.recenter.visibility = View.GONE
            NavigationCameraState.TRANSITION_TO_OVERVIEW,
            NavigationCameraState.OVERVIEW,
            NavigationCameraState.IDLE -> binding.recenter.visibility = View.VISIBLE
        }
    }

    /**
     * Gets notified whenever the tracked routes change.
     *
     * A change can mean:
     * - routes get changed with [MapboxNavigation.setRoutes]
     * - routes annotations get refreshed (for example, congestion annotation that indicate the live traffic along the route)
     * - driver got off route and a reroute was executed
     */
    private val routesObserver = RoutesObserver { routeUpdateResult ->
        if (routeUpdateResult.navigationRoutes.toDirectionsRoutes().isNotEmpty()) {
            // generate route geometries asynchronously and render them
            val routeLines = routeUpdateResult.navigationRoutes.toDirectionsRoutes()
                .map { RouteLine(it, null) }

            routeLineApi.setNavigationRouteLines(
                routeLines
                    .toNavigationRouteLines()
            ) { value ->
                mapboxMap!!.getStyle()?.apply {
                    routeLineView.renderRouteDrawData(this, value)
                }
            }

            // update the camera position to account for the new route
            viewportDataSource!!.onRouteChanged(
                routeUpdateResult.navigationRoutes.first())
            viewportDataSource!!.evaluate()

            mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.REROUTE_ALONG, routeUpdateResult.reason)
        } else {
            // remove the route line and route arrow from the map
            val style = mapboxMap!!.getStyle()
            if (style != null) {
                routeLineApi.clearRouteLine { value ->
                    routeLineView.renderClearRouteLineValue(
                        style,
                        value
                    )
                }
                routeArrowView.render(style, routeArrowApi.clearArrows())
            }

            // remove the route reference from camera position evaluations
            viewportDataSource!!.clearRouteData()
            viewportDataSource!!.evaluate()
        }
    }

    private val arrivalObserver = object: ArrivalObserver {

        override fun onWaypointArrival(routeProgress: RouteProgress) {
            mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.WAYPOINT_ARRIVAL)
        }

        override fun onNextRouteLegStart(routeLegProgress: RouteLegProgress) {
            mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.NEXT_ROUTE_LEG_START)
        }

        override fun onFinalDestinationArrival(routeProgress: RouteProgress) {
            mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.FINAL_DESTINATION_ARRIVAL)
        }
    }

    private val tileStoreObserver = object : TileStoreObserver {
        override fun onRegionLoadProgress(id: String, progress: TileRegionLoadProgress) {
            val percent =
                (progress.completedResourceCount.toDouble() / progress.requiredResourceCount.toDouble() * 100).roundToInt()
            mapboxTurnByTurnEvents?.sendJsonEvent(
                MapboxEventType.TILE_REGION_PROGRESS,
                "{" +
                        "\"id\":\"${id}\"," +
                        "\"percent\":\"${percent}\"" +
                        "}"
            )
        }

        override fun onRegionLoadFinished(id: String, region: Expected<TileRegionError, TileRegion>) {
            if(region.isValue) {
                mapboxTurnByTurnEvents?.sendJsonEvent(
                    MapboxEventType.TILE_REGION_FINISHED,
                    "{\"id\":\"${id}\"}"
                )
            } else {
                region.error?.let {
                    mapboxTurnByTurnEvents?.sendJsonEvent(
                        MapboxEventType.TILE_REGION_ERROR,
                    "{" +
                            "\"id\":\"${id}\"," +
                            "\"error\":\"${it.message}\"" +
                            "}" )
                }
            }
        }

        override fun onRegionRemoved(id: String) {
            mapboxTurnByTurnEvents?.sendJsonEvent(
                MapboxEventType.TILE_REGION_REMOVED,
                "{\"id\":\"${id}\"}"
            )
        }

        override fun onRegionGeometryChanged(id: String, geometry: Geometry) {
            mapboxTurnByTurnEvents?.sendJsonEvent(MapboxEventType.TILE_REGION_GEOMETRY_CHANGED,
                "{\"id\":\"${id}\"}"
            )
        }

        override fun onRegionMetadataChanged(id: String, value: Value) {
            mapboxTurnByTurnEvents?.sendJsonEvent(MapboxEventType.TILE_REGION_METADATA_CHANGED,
                "{\"id\":\"${id}\"}"
            )
        }
    }

    private val viewportDataSourceUpdateObserver = ViewportDataSourceUpdateObserver {}

    override fun onAccuracyChanged(p0: Sensor?, p1: Int) {}

    override fun onSensorChanged(p0: SensorEvent?) {
        // Sensor change value
        val value = p0!!.values[0]
        if (p0.sensor.type == Sensor.TYPE_LIGHT) {
            lightValue = value
        }
    }

    open fun initializeFlutterChannelHandlers() {
        methodChannel?.setMethodCallHandler(this)
        eventChannel?.setStreamHandler(this)
    }

    override fun onCreate(savedInstanceState: Bundle? ) {
        Log.d("TurnByTurnNative","Activity created")
        super.onCreate(savedInstanceState)


        lifecycleRegistry.currentState = Lifecycle.State.CREATED
    }

    fun initializeMapbox() {
        Log.d("TurnByTurnNative","Mapbox initializing")
        super.onStart()

        accessToken = PluginUtilities.getResourceFromContext(pluginContext, "mapbox_access_token")

        mapboxMap = binding.mapView.getMapboxMap()

        mapboxMap!!.getResourceOptions().tileStore?.apply {
            setOption(
                TileStoreOptions.MAPBOX_ACCESS_TOKEN,
                TileDataDomain.MAPS,
                Value(accessToken)
            )
            setOption(
                TileStoreOptions.MAPBOX_ACCESS_TOKEN,
                TileDataDomain.NAVIGATION,
                Value(accessToken)
            )
            setOption(
                TileStoreOptions.DISK_QUOTA,
                Value(10737418240)
            )
        }

        mapboxMap!!.getResourceOptions().tileStoreUsageMode.apply {
            TileStoreUsageMode.READ_AND_UPDATE
        }

        var unitType: UnitType = UnitType.METRIC
        if(measurementUnits == DirectionsCriteria.IMPERIAL) {
            unitType = UnitType.IMPERIAL
        }

        val distanceFormatterOptions = DistanceFormatterOptions.Builder(pluginContext)
            .unitType(unitType)
            .build()

        val routingTilesOptions = RoutingTilesOptions.Builder()
            .tileStore(mapboxMap!!.getResourceOptions().tileStore)
            .build()

        // initialize Mapbox Navigation
        MapboxNavigationApp.setup(
            NavigationOptions.Builder(pluginContext)
                .accessToken(accessToken)
                .routingTilesOptions(routingTilesOptions)
                .distanceFormatterOptions(distanceFormatterOptions)
                .build()
        )

        offlineManager = OfflineManager(mapboxMap!!.getResourceOptions())

        binding.mapView.scalebar.enabled = false
        binding.mapView.compass.enabled = false

        // initialize Navigation Camera
        viewportDataSource = MapboxNavigationViewportDataSource(mapboxMap!!)
        viewportDataSource!!.registerUpdateObserver(viewportDataSourceUpdateObserver)
        navigationCamera = NavigationCamera(
            mapboxMap!!,
            binding.mapView.camera,
            viewportDataSource!!,
        )
        // set the camera to initial following/overview state
        when(navigationCameraType) {
            NavigationCameraType.FOLLOWING -> {
                navigationCamera!!.requestNavigationCameraToFollowing()
                if(disableGesturesWhenFollowing == true) {
                    toggleGestures(false)
                }
            }
            NavigationCameraType.OVERVIEW -> {
                navigationCamera!!.requestNavigationCameraToOverview()
                if(disableGesturesWhenFollowing == true) {
                    toggleGestures(true)
                }
            }
            NavigationCameraType.NOCHANGE -> {}
        }
        // set the animations lifecycle listener to ensure the NavigationCamera stops
        // automatically following the user location when the map is interacted with
        navigationBasicGesturesHandler = NavigationBasicGesturesHandler(navigationCamera!!)
        binding.mapView.camera.addCameraAnimationsLifecycleListener(
            navigationBasicGesturesHandler!!
        )
        navigationCamera!!.registerNavigationCameraStateChangeObserver(
            navigationCameraStateChangedObserver
        )

        // set the padding values depending on screen orientation and visible view layout
        if (pluginContext.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            viewportDataSource!!.overviewPadding = landscapeOverviewPadding
            viewportDataSource!!.followingPadding = landscapeFollowingPadding
        } else {
            viewportDataSource!!.overviewPadding = overviewPadding
            viewportDataSource!!.followingPadding = followingPadding
        }

        if(zoom != null) {
            viewportDataSource!!.followingZoomPropertyOverride(zoom)
        }

        if(pitch != null) {
            viewportDataSource!!.followingPitchPropertyOverride(pitch)
        }

        // initialize maneuver api that feeds the data to the top banner maneuver view
        maneuverApi = MapboxManeuverApi(
            MapboxDistanceFormatter(distanceFormatterOptions)
        )

        // initialize bottom progress view
        tripProgressApi = MapboxTripProgressApi(
            TripProgressUpdateFormatter.Builder(pluginContext)
                .distanceRemainingFormatter(
                    DistanceRemainingFormatter(distanceFormatterOptions)
                )
                .timeRemainingFormatter(
                    TimeRemainingFormatter(pluginContext)
                )
                .percentRouteTraveledFormatter(
                    PercentDistanceTraveledFormatter()
                )
                .estimatedTimeToArrivalFormatter(
                    EstimatedTimeToArrivalFormatter(pluginContext, TimeFormat.NONE_SPECIFIED)
                )
                .build()
        )

        // Fix trip progress view being different color from it's container
        binding.tripProgressView.setBackgroundColor(Color.TRANSPARENT)

        // initialize route line, the withRouteLineBelowLayerId is specified to place
        // the route line below road labels layer on the map
        // the value of this option will depend on the style that you are using
        // and under which layer the route line should be placed on the map layers stack
        val customColorResources = RouteLineColorResources.Builder()
            .routeCasingColor(Color.parseColor(routeCasingColor))
            .routeDefaultColor(Color.parseColor(routeDefaultColor))
            .restrictedRoadColor(Color.parseColor(restrictedRoadColor))
            .routeLineTraveledColor(Color.parseColor(routeLineTraveledColor))
            .routeLineTraveledCasingColor(Color.parseColor(routeLineTraveledCasingColor))
            .routeClosureColor(Color.parseColor(routeClosureColor))
            .routeLowCongestionColor(Color.parseColor(routeLowCongestionColor))
            .routeModerateCongestionColor(Color.parseColor(routeModerateCongestionColor))
            .routeHeavyCongestionColor(Color.parseColor(routeHeavyCongestionColor))
            .routeSevereCongestionColor(Color.parseColor(routeSevereCongestionColor))
            .routeUnknownCongestionColor(Color.parseColor(routeUnknownCongestionColor))
            .build()

        val routeLineResources = RouteLineResources.Builder()
            .routeLineColorResources(customColorResources)
            .build()

        val mapboxRouteLineOptions = MapboxRouteLineOptions.Builder(pluginContext)
            .withRouteLineResources(routeLineResources)
            .withRouteLineBelowLayerId("road-label")
            .build()
        routeLineApi = MapboxRouteLineApi(mapboxRouteLineOptions)
        routeLineView = MapboxRouteLineView(mapboxRouteLineOptions)

        // initialize maneuver arrow view to draw arrows on the map
        val routeArrowOptions = RouteArrowOptions.Builder(pluginContext)
            .build()
        routeArrowView = MapboxRouteArrowView(routeArrowOptions)

        val styleUri: String = if(lightValue <= darkThreshold) {
            mapStyleUrlNight ?: Style.MAPBOX_STREETS
        } else {
            mapStyleUrlDay ?: Style.MAPBOX_STREETS
        }

        // load map style
        mapboxMap!!.loadStyleUri(
            styleUri
        ) {
            // add long click listener that search for a route to the clicked destination
            if (navigateOnLongClick == true) {
                binding.mapView.gestures.addOnMapLongClickListener { point ->
                    findRoutes(listOf(point),listOf(""), NavigationCameraType.NOCHANGE)
                    true
                }
            }
        }

        // initialize view interactions
        if(showStopButton == true) {
            binding.stop.visibility = View.VISIBLE
            binding.stop.setOnClickListener {
                clearRouteAndStopNavigation()
            }
        }

        binding.recenter.setOnClickListener {
            navigationCamera!!.requestNavigationCameraToFollowing()
            binding.routeOverview.showTextAndExtend(BUTTON_ANIMATION_DURATION)
            if(disableGesturesWhenFollowing == true) {
                toggleGestures(false)
            }
            mapboxTurnByTurnEvents?.sendJsonEvent(
                MapboxEventType.NAVIGATION_CAMERA_CHANGED,
                "{" +
                    "\"state\":\"${NavigationCameraType.FOLLOWING}\"" +
                "}"
            )
        }
        binding.routeOverview.setOnClickListener {
            navigationCamera!!.requestNavigationCameraToOverview()
            binding.recenter.showTextAndExtend(BUTTON_ANIMATION_DURATION)
            if(disableGesturesWhenFollowing == true) {
                toggleGestures(true)
            }
            mapboxTurnByTurnEvents?.sendJsonEvent(
                MapboxEventType.NAVIGATION_CAMERA_CHANGED,
                "{" +
                    "\"state\":\"${NavigationCameraType.OVERVIEW}\"" +
                "}"
            )
        }

        binding.soundButton.setOnClickListener {
            toggleMuted()
        }

        // set initial sound button state
        if(muted == true) {
            isVoiceInstructionsMuted = true

            binding.soundButton.mute()
        } else {
            isVoiceInstructionsMuted = false

            binding.soundButton.unmute()
        }

        // initialize the location puck
        binding.mapView.location.apply {
            locationPuck = LocationPuck2D(
                bearingImage = ContextCompat.getDrawable(
                    pluginContext,
                    R.drawable.mapbox_navigation_puck_icon
                )
            )

            setLocationProvider(navigationLocationProvider!!)

            enabled = true
        }

        // register observers and check routes
        registerObservers()

        // Starts the trip session to receive location updates in free drive
        // and later when a route is set also receive route progress updates
        if (ActivityCompat.checkSelfPermission(
                pluginContext,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(
                pluginContext,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        mapboxNavigation.startTripSession()

        methodChannel?.invokeMethod("onInitializationFinished", null)
        Log.d("TurnByTurnNative","Mapbox initialized")
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
    }

    private fun registerObservers() {
        // register event listeners
        mapboxNavigation.registerRoutesObserver(routesObserver)
        mapboxNavigation.registerRouteProgressObserver(routeProgressObserver)
        mapboxNavigation.registerLocationObserver(locationObserver)
        mapboxNavigation.registerVoiceInstructionsObserver(voiceInstructionsObserver)
        mapboxNavigation.registerArrivalObserver(arrivalObserver)
        mapboxMap!!.getResourceOptions().tileStore?.addObserver(tileStoreObserver)

        observersRegistered = true

        Log.d("TurnByTurnNative","Observers registered")
    }

    fun unregisterObservers() {
        if(navigationStarted) {
            clearRouteAndStopNavigation()
        }

        // unregister event listeners to prevent leaks or unnecessary resource consumption
        mapboxNavigation.stopTripSession()
        mapboxNavigation.unregisterRoutesObserver(routesObserver)
        mapboxNavigation.unregisterRouteProgressObserver(routeProgressObserver)
        mapboxNavigation.unregisterLocationObserver(locationObserver)
        mapboxNavigation.unregisterVoiceInstructionsObserver(voiceInstructionsObserver)
        mapboxNavigation.unregisterArrivalObserver(arrivalObserver)
        mapboxMap!!.getResourceOptions().tileStore?.removeObserver(tileStoreObserver)
        // disable the location puck
        binding.mapView.location.apply {
            enabled = false
        }

        navigationCamera!!.unregisterNavigationCameraStateChangeObserver(navigationCameraStateChangedObserver)
        binding.mapView.camera.removeCameraAnimationsLifecycleListener(navigationBasicGesturesHandler!!)
        viewportDataSource!!.unregisterUpdateObserver(viewportDataSourceUpdateObserver)

        observersRegistered = false

        Log.d("TurnByTurnNative","Observers unregistered")
    }

    //Flutter stream listener delegate methods
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        mapboxTurnByTurnEvents = MapboxTurnByTurnEvents(eventSink!!)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        when (methodCall.method) {
            "startNavigation" -> {
                startNavigation(methodCall)
            }
            "stopNavigation" -> {
                clearRouteAndStopNavigation()
            }
            "addOfflineMap" -> {
                addOfflineMap(methodCall)
            }
            "toggleMuted" -> {
                toggleMuted()
            }
            else -> result.notImplemented()
        }
    }

    override fun onStop() {
        Log.d("TurnByTurnNative","Activity stopped")
        super.onStop()
    }

    override fun onLowMemory() {
        Log.d("TurnByTurnNative","Activity low memory")
        super.onLowMemory()
    }

    override fun onDestroy() {
        if(observersRegistered) {
            unregisterObservers()
        }
        methodChannel = null
        eventSink = null
        eventChannel = null
        messenger = null

        maneuverApi.cancel()
        routeLineApi.cancel()
        routeLineView.cancel()

        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        ViewTreeLifecycleOwner.get(binding.root)?.let { MapboxNavigationApp.detach(it) }
        MapboxNavigationApp.disable()

        super.onDestroy()

        Log.d("TurnByTurnNative","Activity destroyed")
    }

    override fun getLifecycle(): Lifecycle {
        return lifecycleRegistry
    }

    // mute/unmute voice instructions
    private fun toggleMuted() {
        isVoiceInstructionsMuted = !isVoiceInstructionsMuted

        // set sound button state
        if(isVoiceInstructionsMuted) {
            binding.soundButton.mute()
        } else {
            binding.soundButton.unmute()
        }

        mapboxTurnByTurnEvents?.sendJsonEvent(
            MapboxEventType.MUTE_CHANGED,
            "{" +
                    "\"muted\":${isVoiceInstructionsMuted}" +
                    "}"
        )
    }

    private fun startNavigation(call: MethodCall) {
        val arguments = call.arguments as? Map<*, *>

        var waypointList: List<Point> = listOf()
        var waypointNamesList: List<String> = listOf()

        val waypointMapList = arguments?.get("waypoints") as HashMap<*, *>
        for (item in waypointMapList)
        {
            val waypoint = item.value as HashMap<*, *>
            val name = waypoint["name"] as String
            val latitude = waypoint["latitude"] as Double
            val longitude = waypoint["longitude"] as Double
            waypointNamesList = waypointNamesList + name
            waypointList = waypointList + Point.fromLngLat(longitude, latitude)
        }

        val cameraType: String = arguments["navigationCameraType"] as String

        if(waypointList.isNotEmpty() && waypointNamesList.isNotEmpty()) run {
            findRoutes(waypointList, waypointNamesList, cameraType)
        }
    }

    private fun findRoutes(locations: List<Point>, waypointNames: List<String>, navigationCameraType: String) {
        mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.ROUTE_BUILDING)

        val originLocation = navigationLocationProvider!!.lastLocation
        val originPoint = originLocation?.let {
            Point.fromLngLat(it.longitude, it.latitude)
        } ?: return

        val combinedCoordinates: List<Point> = listOf(originPoint) + locations
        val combinedWaypointNames: List<String> = listOf("") + waypointNames

        val annotations: List<String> = listOf(DirectionsCriteria.ANNOTATION_MAXSPEED)

        // execute a route request
        // it's recommended to use the
        // applyDefaultNavigationOptions and applyLanguageAndVoiceUnitOptions
        // that make sure the route request is optimized
        // to allow for support of all of the Navigation SDK features
        mapboxNavigation.requestRoutes(
            RouteOptions.builder()
                .annotationsList(annotations)
                .applyDefaultNavigationOptions()
                .applyLanguageAndVoiceUnitOptions(pluginContext)
                .coordinatesList(combinedCoordinates)
                .waypointNamesList(combinedWaypointNames)
                .profile(routeProfile)
                .language(language)
                .voiceUnits(measurementUnits)
                .alternatives(showAlternativeRoutes)
                .continueStraight(!allowUTurnsAtWaypoints)
                .layersList(listOf(mapboxNavigation.getZLevel(), null))
                .build(),
            object : NavigationRouterCallback {
                override fun onRoutesReady(
                    routes: List<NavigationRoute>,
                    routerOrigin: RouterOrigin
                ) {
                    setRouteAndStartNavigation(routes, navigationCameraType)
                }

                override fun onFailure(
                    reasons: List<RouterFailure>,
                    routeOptions: RouteOptions
                ) {
                    var message = "an error occurred while building the route. Errors: "
                    for (reason in reasons){
                        message += reason.message
                    }
                    mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.ROUTE_BUILD_FAILED, message)
                }

                override fun onCanceled(routeOptions: RouteOptions, routerOrigin: RouterOrigin) {
                    mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.ROUTE_BUILD_CANCELLED)
                }
            }
        )
    }

    private fun setRouteAndStartNavigation(routes: List<NavigationRoute>, navigationCameraType: String) {
        if (routes.isEmpty()){
            mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.ROUTE_BUILD_NO_ROUTES_FOUND)
            return
        }

        mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.ROUTE_BUILT)

        // set routes, where the first route in the list is the primary route that
        // will be used for active guidance
        mapboxNavigation.setNavigationRoutes(routes)

        // show UI elements
        if(showMuteButton == true) {
            binding.soundButton.visibility = View.VISIBLE
        }
        binding.tripProgressCard.visibility = View.VISIBLE

        // move the camera to requested state when new route is available
        when(navigationCameraType) {
            NavigationCameraType.FOLLOWING -> {
                navigationCamera!!.requestNavigationCameraToFollowing()
                if(disableGesturesWhenFollowing == true) {
                    toggleGestures(false)
                }
                mapboxTurnByTurnEvents?.sendJsonEvent(
                    MapboxEventType.NAVIGATION_CAMERA_CHANGED,
                    "{" +
                            "\"state\":\"${NavigationCameraType.FOLLOWING}\"" +
                            "}"
                )
            }
            NavigationCameraType.OVERVIEW -> {
                navigationCamera!!.requestNavigationCameraToOverview()
                if(disableGesturesWhenFollowing == true) {
                    toggleGestures(true)
                }
                mapboxTurnByTurnEvents?.sendJsonEvent(
                    MapboxEventType.NAVIGATION_CAMERA_CHANGED,
                    "{" +
                            "\"state\":\"${NavigationCameraType.OVERVIEW}\"" +
                            "}"
                )
            }
            NavigationCameraType.NOCHANGE -> {}
        }
        navigationStarted = true
        mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.NAVIGATION_RUNNING)
    }

    private fun clearRouteAndStopNavigation() {
        navigationStarted = false
        // clear
        mapboxNavigation.setNavigationRoutes(listOf())

        // hide UI elements
        binding.soundButton.visibility = View.GONE
        binding.maneuverView.visibility = View.GONE
        binding.tripProgressCard.visibility = View.GONE

        navigationCamera!!.requestNavigationCameraToOverview()
        if(disableGesturesWhenFollowing == true) {
            toggleGestures(true)
        }

        mapboxTurnByTurnEvents?.sendEvent(MapboxEventType.NAVIGATION_CANCELLED)
    }

    private fun addOfflineMap(call: MethodCall) {
        val arguments = call.arguments as? Map<*, *>
        val radiusEarth = 6371.0

        val mapStyleUrl = arguments?.get("mapStyleUrl") as String
        val minZoom = arguments["minZoom"] as Int
        val maxZoom = arguments["maxZoom"] as Int
        val areaId = arguments["areaId"] as String
        val centerLatitude = arguments["centerLatitude"] as Double
        val centerLongitude = arguments["centerLongitude"] as Double
        val distance = arguments["distance"] as Double

        // Calculate the distance to a square corner which contains a circle radius
        val cornerDistance = hypot(distance, distance)
        val deltaLatitude = Math.toDegrees(cornerDistance / radiusEarth)
        val deltaLongitude = Math.toDegrees(cornerDistance / radiusEarth / cos(Math.toRadians(centerLatitude)))

        val areaCoordinates = listOf(
            listOf(
                Point.fromLngLat(centerLatitude + deltaLatitude, centerLongitude - deltaLongitude),
                Point.fromLngLat(centerLatitude + deltaLatitude, centerLongitude + deltaLongitude),
                Point.fromLngLat(centerLatitude - deltaLatitude, centerLongitude + deltaLongitude),
                Point.fromLngLat(centerLatitude - deltaLatitude, centerLongitude - deltaLongitude),
                Point.fromLngLat(centerLatitude + deltaLatitude, centerLongitude - deltaLongitude),
            )
        )

        val area = Polygon.fromLngLats(areaCoordinates)

        val stylePackLoadOptions = StylePackLoadOptions.Builder()
            .glyphsRasterizationMode(GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY)
            .build()

        val mapsTilesetDescriptor = offlineManager.createTilesetDescriptor(
            TilesetDescriptorOptions.Builder()
                .styleURI(mapStyleUrl)
                .minZoom(minZoom.toByte())
                .maxZoom(maxZoom.toByte())
                .build()
        )

        val navTilesetDescriptor = mapboxNavigation.tilesetDescriptorFactory.getLatest()

        val tileRegionLoadOptions = TileRegionLoadOptions.Builder()
            .geometry(area)
            .descriptors(listOf(mapsTilesetDescriptor, navTilesetDescriptor))
            .build()

        offlineManager.loadStylePack(
            mapStyleUrl,
            // Build Style pack load options
            stylePackLoadOptions,
            { progress ->
                val percent =
                    (progress.completedResourceCount.toDouble() / progress.requiredResourceCount.toDouble() * 100).roundToInt()
                mapboxTurnByTurnEvents?.sendJsonEvent(
                    MapboxEventType.STYLE_PACK_PROGRESS,
                    "{" +
                            "\"percent\":\"${percent}\"" +
                            "}"
                )
            },
            { expected ->
                if (expected.isValue) {
                    expected.value?.let { _ ->
                        mapboxTurnByTurnEvents?.sendEvent(
                            MapboxEventType.STYLE_PACK_FINISHED
                        )
                    }
                }
                expected.error?.let {
                    mapboxTurnByTurnEvents?.sendJsonEvent(
                        MapboxEventType.STYLE_PACK_ERROR,
                        "{" +
                                "\"error\":\"${it.message}\"" +
                                "}" )
                }
            }
        )

        mapboxMap!!.getResourceOptions().tileStore?.loadTileRegion(
            areaId,
            tileRegionLoadOptions
        )
    }

    private fun toggleGestures(enabled: Boolean) {
        binding.mapView.gestures.doubleTapToZoomInEnabled = enabled
        binding.mapView.gestures.quickZoomEnabled = enabled
        binding.mapView.gestures.quickZoomEnabled = enabled
        binding.mapView.gestures.pinchToZoomEnabled = enabled
        binding.mapView.gestures.pitchEnabled = enabled
        binding.mapView.gestures.rotateEnabled = enabled
        binding.mapView.gestures.scrollEnabled = enabled
    }
}
