package au.com.annon.flutter_mapbox_turn_by_turn.ui

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.location.Location
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import au.com.annon.flutter_mapbox_turn_by_turn.R
import au.com.annon.flutter_mapbox_turn_by_turn.databinding.TurnByTurnActivityBinding
import au.com.annon.flutter_mapbox_turn_by_turn.models.MapboxEventType
import au.com.annon.flutter_mapbox_turn_by_turn.models.MapboxLocationChangeEvent
import au.com.annon.flutter_mapbox_turn_by_turn.models.MapboxProgressChangeEvent
import au.com.annon.flutter_mapbox_turn_by_turn.models.MapboxTurnByTurnEvents
import au.com.annon.flutter_mapbox_turn_by_turn.utilities.PluginUtilities
import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.api.directions.v5.models.DirectionsRoute
import com.mapbox.api.directions.v5.models.RouteOptions
import com.mapbox.bindgen.Expected
import com.mapbox.geojson.Point
import com.mapbox.maps.EdgeInsets
import com.mapbox.maps.MapView
import com.mapbox.maps.MapboxMap
import com.mapbox.maps.Style
import com.mapbox.maps.plugin.LocationPuck2D
import com.mapbox.maps.plugin.animation.camera
import com.mapbox.maps.plugin.gestures.gestures
import com.mapbox.maps.plugin.locationcomponent.location
import com.mapbox.maps.plugin.scalebar.scalebar
import com.mapbox.navigation.base.TimeFormat
import com.mapbox.navigation.base.extensions.applyDefaultNavigationOptions
import com.mapbox.navigation.base.extensions.applyLanguageAndVoiceUnitOptions
import com.mapbox.navigation.base.formatter.DistanceFormatterOptions
import com.mapbox.navigation.base.formatter.UnitType
import com.mapbox.navigation.base.options.NavigationOptions
import com.mapbox.navigation.base.route.*
import com.mapbox.navigation.base.trip.model.RouteLegProgress
import com.mapbox.navigation.base.trip.model.RouteProgress
import com.mapbox.navigation.core.MapboxNavigation
import com.mapbox.navigation.core.MapboxNavigationProvider
import com.mapbox.navigation.core.arrival.ArrivalObserver
import com.mapbox.navigation.core.directions.session.RoutesObserver
import com.mapbox.navigation.core.formatter.MapboxDistanceFormatter
import com.mapbox.navigation.core.trip.session.LocationMatcherResult
import com.mapbox.navigation.core.trip.session.LocationObserver
import com.mapbox.navigation.core.trip.session.RouteProgressObserver
import com.mapbox.navigation.core.trip.session.VoiceInstructionsObserver
import com.mapbox.navigation.ui.base.util.MapboxNavigationConsumer
import com.mapbox.navigation.ui.maneuver.api.MapboxManeuverApi
import com.mapbox.navigation.ui.maneuver.view.MapboxManeuverView
import com.mapbox.navigation.ui.maps.camera.NavigationCamera
import com.mapbox.navigation.ui.maps.camera.data.MapboxNavigationViewportDataSource
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
import com.mapbox.navigation.ui.voice.api.MapboxSpeechApi
import com.mapbox.navigation.ui.voice.api.MapboxVoiceInstructionsPlayer
import com.mapbox.navigation.ui.voice.model.SpeechAnnouncement
import com.mapbox.navigation.ui.voice.model.SpeechError
import com.mapbox.navigation.ui.voice.model.SpeechValue
import com.mapbox.navigation.ui.voice.model.SpeechVolume
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*


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

open class TurnByTurnActivity : FlutterActivity, SensorEventListener, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    constructor(
        mContext: Context,
        mBinding: TurnByTurnActivityBinding,
        creationParams: Map<String?, Any?>?,
    ) {
        super.attachBaseContext(mContext)
        binding = mBinding

        zoom = creationParams?.get("zoom") as? Double
        pitch = creationParams?.get("pitch") as? Double
        disableGesturesWhenNavigating = creationParams?.get("disableGesturesWhenNavigating") as? Boolean
        navigateOnLongClick = creationParams?.get("navigateOnLongClick") as? Boolean
        showStopButton = creationParams?.get("showStopButton") as? Boolean
        showSpeedIndicator = creationParams?.get("showSpeedIndicator") as Boolean
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

    open var methodChannel: MethodChannel? = null
    open var eventChannel: EventChannel? = null

    private val darkThreshold = 1.0f
    private var lightValue = 1.1f
    private var distanceRemaining: Float? = null
    private var durationRemaining: Double? = null
    private var navigationStarted: Boolean = false

    // flutter creation parameters
    private val zoom: Double?
    private val pitch: Double?
    private val disableGesturesWhenNavigating: Boolean?
    private val navigateOnLongClick: Boolean?
    private val showStopButton: Boolean?
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

    companion object {
        private lateinit var binding: TurnByTurnActivityBinding
        private const val BUTTON_ANIMATION_DURATION = 1500L
        var eventSink:EventChannel.EventSink? = null

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
    private lateinit var mapboxMap: MapboxMap

    /**
     * Mapbox Navigation entry point. There should only be one instance of this object for the app.
     * You can use [MapboxNavigationProvider] to help create and obtain that instance.
     */
    private lateinit var mapboxNavigation: MapboxNavigation

    /**
     * Used to execute camera transitions based on the data generated by the [viewportDataSource].
     * This includes transitions from route overview to route following and continuously updating the camera as the location changes.
     */
    private lateinit var navigationCamera: NavigationCamera

    /**
     * Produces the camera frames based on the location and routing data for the [navigationCamera] to execute.
     */
    private lateinit var viewportDataSource: MapboxNavigationViewportDataSource

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
                voiceInstructionsPlayer.volume(SpeechVolume(0f))
            } else {
                binding.soundButton.unmuteAndExtend(BUTTON_ANIMATION_DURATION)
                voiceInstructionsPlayer.volume(SpeechVolume(1f))
            }
        }


    /**
     * Extracts message that should be communicated to the driver about the upcoming maneuver.
     * When possible, downloads a synthesized audio file that can be played back to the driver.
     */
    private lateinit var speechApi: MapboxSpeechApi

    /**
     * Plays the synthesized audio files with upcoming maneuver instructions
     * or uses an on-device Text-To-Speech engine to communicate the message to the driver.
     */
    private lateinit var voiceInstructionsPlayer: MapboxVoiceInstructionsPlayer

    /**
     * Observes when a new voice instruction should be played.
     */
    private val voiceInstructionsObserver = VoiceInstructionsObserver { voiceInstructions ->
        speechApi.generate(voiceInstructions, speechCallback)
    }

    /**
     * Based on whether the synthesized audio file is available, the callback plays the file
     * or uses the fall back which is played back using the on-device Text-To-Speech engine.
     */
    private val speechCallback =
        MapboxNavigationConsumer<Expected<SpeechError, SpeechValue>> { expected ->
            expected.fold(
                { error ->
                    // play the instruction via fallback text-to-speech engine
                    voiceInstructionsPlayer.play(
                        error.fallback,
                        voiceInstructionsPlayerCallback
                    )
                },
                { value ->
                    // play the sound file from the external generator
                    voiceInstructionsPlayer.play(
                        value.announcement,
                        voiceInstructionsPlayerCallback
                    )
                }
            )
        }

    /**
     * When a synthesized audio file was downloaded, this callback cleans up the disk after it was played.
     */
    private val voiceInstructionsPlayerCallback =
        MapboxNavigationConsumer<SpeechAnnouncement> { value ->
            // remove already consumed file to free-up space
            speechApi.clean(value)
        }

    /**
     * [NavigationLocationProvider] is a utility class that helps to provide location updates generated by the Navigation SDK
     * to the Maps SDK in order to update the user location indicator on the map.
     */
    private val navigationLocationProvider = NavigationLocationProvider()

    /**
     * Gets notified with location updates.
     *
     * Exposes raw updates coming directly from the location services
     * and the updates enhanced by the Navigation SDK (cleaned up and matched to the road).
     */
    private val locationObserver = object : LocationObserver {
        var firstLocationUpdateReceived = false

        override fun onNewRawLocation(rawLocation: Location) {
            // not handled
        }

        override fun onNewLocationMatcherResult(locationMatcherResult: LocationMatcherResult) {
            val enhancedLocation = locationMatcherResult.enhancedLocation
            // update location puck's position on the map
            navigationLocationProvider.changePosition(
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
                        runOnUiThread {
                            "$speed\nkph".also { binding.speedView.text = it }
                            if (speed > mSpeedLimit) {
                                binding.speedView.background = ContextCompat.getDrawable(
                                    context,
                                    R.drawable.speed_limit_speeding
                                )
                            } else {
                                binding.speedView.background = ContextCompat.getDrawable(
                                    context,
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
                        runOnUiThread {
                            "$speed\nmph".also { binding.speedView.text = it }
                            if (speed > mSpeedLimit) {
                                binding.speedView.background = ContextCompat.getDrawable(
                                    context,
                                    R.drawable.speed_limit_speeding
                                )
                            } else {
                                binding.speedView.background = ContextCompat.getDrawable(
                                    context,
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
                        runOnUiThread {
                            "$speed\nkph".also { binding.speedView.text = it }
                            binding.speedView.background = ContextCompat.getDrawable(
                                context,
                                R.drawable.speed_limit_normal
                            )
                        }
                    } else {
                        // We should be showing imperial speed
                        val speed = (enhancedLocation.speed * 3.6 / 1.609).toInt()

                        // We should be showing metric speed
                        runOnUiThread {
                            "$speed\nmph".also { binding.speedView.text = it }
                            binding.speedView.background = ContextCompat.getDrawable(
                                context,
                                R.drawable.speed_limit_normal
                            )
                        }
                    }
                }
            }

            // update camera position to account for new location
            viewportDataSource.onLocationChanged(enhancedLocation)
            viewportDataSource.evaluate()
            MapboxTurnByTurnEvents.sendEvent(MapboxLocationChangeEvent(enhancedLocation))

            // if this is the first location update the activity has received,
            // it's best to immediately move the camera to the current user location
            if (!firstLocationUpdateReceived) {
                firstLocationUpdateReceived = true
                navigationCamera.requestNavigationCameraToOverview(
                    stateTransitionOptions = NavigationCameraTransitionOptions.Builder()
                        .maxDuration(0) // instant transition
                        .build()
                )
            }
        }
    }

    /**
     * Gets notified with progress along the currently active route.
     */
    private val routeProgressObserver = RouteProgressObserver { routeProgress ->
        // update the camera position to account for the progressed fragment of the route
        viewportDataSource.onRouteProgressChanged(routeProgress)
        viewportDataSource.evaluate()

        // draw the upcoming maneuver arrow on the map
        val style = mapboxMap.getStyle()
        if (style != null) {
            val maneuverArrowResult = routeArrowApi.addUpcomingManeuverArrow(routeProgress)
            routeArrowView.renderManeuverUpdate(style, maneuverArrowResult)
        }

        // update top banner with maneuver instructions
        val maneuvers = maneuverApi.getManeuvers(routeProgress)
        maneuvers.fold(
            { error ->
                Toast.makeText(
                    context,
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
                MapboxTurnByTurnEvents.sendEvent(progressEvent)

            } catch (e: java.lang.Exception) {

            }
        }

        // update bottom trip progress summary
        binding.tripProgressView.render(
            tripProgressApi.getTripProgress(routeProgress)
        )
    }

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
                mapboxMap.getStyle()?.apply {
                    routeLineView.renderRouteDrawData(this, value)
                }
            }

            // update the camera position to account for the new route
            viewportDataSource.onRouteChanged(
                routeUpdateResult.navigationRoutes.toDirectionsRoutes().first().toNavigationRoute())
            viewportDataSource.evaluate()

            MapboxTurnByTurnEvents.sendEvent(MapboxEventType.REROUTE_ALONG, routeUpdateResult.reason)
        } else {
            // remove the route line and route arrow from the map
            val style = mapboxMap.getStyle()
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
            viewportDataSource.clearRouteData()
            viewportDataSource.evaluate()
        }
    }

    private val arrivalObserver = object: ArrivalObserver {

        override fun onWaypointArrival(routeProgress: RouteProgress) {
            MapboxTurnByTurnEvents.sendEvent(MapboxEventType.WAYPOINT_ARRIVAL)
        }

        override fun onNextRouteLegStart(routeLegProgress: RouteLegProgress) {
            MapboxTurnByTurnEvents.sendEvent(MapboxEventType.NEXT_ROUTE_LEG_START)
        }

        override fun onFinalDestinationArrival(routeProgress: RouteProgress) {
            MapboxTurnByTurnEvents.sendEvent(MapboxEventType.FINAL_DESTINATION_ARRIVAL)
        }
    }

    override fun onAccuracyChanged(p0: Sensor?, p1: Int) {}

    override fun onSensorChanged(p0: SensorEvent?) {
        // Sensor change value
        val value = p0!!.values[0]
        if (p0.sensor.type == Sensor.TYPE_LIGHT) {
            lightValue = value
        }
    }

    open fun getBinding(): TurnByTurnActivityBinding {
        return binding
    }

    open fun initializeFlutterChannelHandlers() {
        methodChannel?.setMethodCallHandler(this)
        eventChannel?.setStreamHandler(this)
    }

    open fun initializeActivity() {
        Log.d("TurnByTurnActivity","Activity initializing")

        accessToken = PluginUtilities.getResourceFromContext(context, "mapbox_access_token")
        binding.mapView.scalebar.enabled = false

        mapboxMap = binding.mapView.getMapboxMap()

        var unitType: UnitType = UnitType.METRIC
        if(measurementUnits == DirectionsCriteria.IMPERIAL) {
            unitType = UnitType.IMPERIAL
        }

        val distanceFormatterOptions = DistanceFormatterOptions.Builder(context)
            .unitType(unitType)
            .build()

        // initialize Mapbox Navigation
        mapboxNavigation = if (MapboxNavigationProvider.isCreated()) {
            MapboxNavigationProvider.retrieve()
        } else {
            MapboxNavigationProvider.create(
                NavigationOptions.Builder(context)
                    .accessToken(accessToken)
                    .distanceFormatterOptions(distanceFormatterOptions)
                    .build()
            )
        }

        // initialize Navigation Camera
        viewportDataSource = MapboxNavigationViewportDataSource(mapboxMap)
        navigationCamera = NavigationCamera(
            mapboxMap,
            binding.mapView.camera,
            viewportDataSource,
        )
        // set the animations lifecycle listener to ensure the NavigationCamera stops
        // automatically following the user location when the map is interacted with
        binding.mapView.camera.addCameraAnimationsLifecycleListener(
            NavigationBasicGesturesHandler(navigationCamera)
        )
        navigationCamera.registerNavigationCameraStateChangeObserver(
            navigationCameraStateChangedObserver
        )

        // set the padding values depending on screen orientation and visible view layout
        if (context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            viewportDataSource.overviewPadding = landscapeOverviewPadding
        } else {
            viewportDataSource.overviewPadding = overviewPadding
        }
        if (context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            viewportDataSource.followingPadding = landscapeFollowingPadding
        } else {
            viewportDataSource.followingPadding = followingPadding
        }

        if(zoom != null) {
            viewportDataSource.followingZoomPropertyOverride(zoom)
        }

        if(pitch != null) {
            viewportDataSource.followingPitchPropertyOverride(pitch)
        }

        // initialize maneuver api that feeds the data to the top banner maneuver view
        maneuverApi = MapboxManeuverApi(
            MapboxDistanceFormatter(distanceFormatterOptions)
        )

        // initialize bottom progress view
        tripProgressApi = MapboxTripProgressApi(
            TripProgressUpdateFormatter.Builder(context)
                .distanceRemainingFormatter(
                    DistanceRemainingFormatter(distanceFormatterOptions)
                )
                .timeRemainingFormatter(
                    TimeRemainingFormatter(context)
                )
                .percentRouteTraveledFormatter(
                    PercentDistanceTraveledFormatter()
                )
                .estimatedTimeToArrivalFormatter(
                    EstimatedTimeToArrivalFormatter(context, TimeFormat.NONE_SPECIFIED)
                )
                .build()
        )

        // initialize voice instructions api and the voice instruction player
        speechApi = MapboxSpeechApi(
            context,
            accessToken,
            language
        )
        voiceInstructionsPlayer = MapboxVoiceInstructionsPlayer(
            context,
            accessToken,
            language
        )

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

        val mapboxRouteLineOptions = MapboxRouteLineOptions.Builder(context)
            .withRouteLineResources(routeLineResources)
            .withRouteLineBelowLayerId("road-label")
            .build()
        routeLineApi = MapboxRouteLineApi(mapboxRouteLineOptions)
        routeLineView = MapboxRouteLineView(mapboxRouteLineOptions)

        // initialize maneuver arrow view to draw arrows on the map
        val routeArrowOptions = RouteArrowOptions.Builder(context)
            .build()
        routeArrowView = MapboxRouteArrowView(routeArrowOptions)

        val styleUri: String = if(lightValue <= darkThreshold) {
            mapStyleUrlNight ?: Style.MAPBOX_STREETS
        } else {
            mapStyleUrlDay ?: Style.MAPBOX_STREETS
        }

        // load map style
        mapboxMap.loadStyleUri(
            styleUri
        ) {
            // add long click listener that search for a route to the clicked destination
            if (navigateOnLongClick == true) {
                binding.mapView.gestures.addOnMapLongClickListener { point ->
                    findRoutes(listOf(point),listOf(""))
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
            navigationCamera.requestNavigationCameraToFollowing()
            binding.routeOverview.showTextAndExtend(BUTTON_ANIMATION_DURATION)
        }
        binding.routeOverview.setOnClickListener {
            navigationCamera.requestNavigationCameraToOverview()
            binding.recenter.showTextAndExtend(BUTTON_ANIMATION_DURATION)
        }
        binding.soundButton.setOnClickListener {
            // mute/unmute voice instructions
            isVoiceInstructionsMuted = !isVoiceInstructionsMuted
        }

        // set initial sounds button state
        binding.soundButton.unmute()

        // initialize the location puck
        binding.mapView.location.apply {
            setLocationProvider(navigationLocationProvider)

            locationPuck = LocationPuck2D(
                bearingImage = ContextCompat.getDrawable(
                    context,
                    R.drawable.mapbox_navigation_puck_icon
                )
            )
            enabled = true
        }

        // register observers and check routes
        startActivity()

        // start the trip session to being receiving location updates in free drive
        // and later when a route is set also receiving route progress updates
        mapboxNavigation.startTripSession()

        methodChannel?.invokeMethod("initializeEventNotifier", null)
        Log.d("TurnByTurnActivity","Activity initialized")
    }

    private fun startActivity() {
        // register event listeners
        mapboxNavigation.registerRoutesObserver(routesObserver)
        mapboxNavigation.registerRouteProgressObserver(routeProgressObserver)
        mapboxNavigation.registerLocationObserver(locationObserver)
        mapboxNavigation.registerVoiceInstructionsObserver(voiceInstructionsObserver)
        mapboxNavigation.registerArrivalObserver(arrivalObserver)

        Log.d("TurnByTurnActivity","Activity started")
    }

    fun detachActivity() {
        if(navigationStarted) {
            clearRouteAndStopNavigation()
        }

        // unregister event listeners to prevent leaks or unnecessary resource consumption
        mapboxNavigation.unregisterRoutesObserver(routesObserver)
        mapboxNavigation.unregisterRouteProgressObserver(routeProgressObserver)
        mapboxNavigation.unregisterLocationObserver(locationObserver)
        mapboxNavigation.unregisterVoiceInstructionsObserver(voiceInstructionsObserver)
        mapboxNavigation.unregisterArrivalObserver(arrivalObserver)
        navigationCamera.unregisterNavigationCameraStateChangeObserver(navigationCameraStateChangedObserver)

        Log.d("TurnByTurnActivity","Activity detached")
    }

    @SuppressLint("Lifecycle")
    fun destroy() {
        MapboxNavigationProvider.destroy()
        maneuverApi.cancel()
        routeLineApi.cancel()
        routeLineView.cancel()
        speechApi.cancel()
        voiceInstructionsPlayer.shutdown()

        Log.d("TurnByTurnActivity","Activity destroyed")
    }

    //Flutter stream listener delegate methods
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
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
            else -> result.notImplemented()
        }
    }

    private fun startNavigation(@NonNull call: MethodCall) {
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

        if(waypointList.isNotEmpty() && waypointNamesList.isNotEmpty()) run {
            findRoutes(waypointList, waypointNamesList)
        }
    }

    private fun findRoutes(waypoints: List<Point>, waypointNames: List<String>) {
        if (!PluginUtilities.isNetworkAvailable(context)) {
            MapboxTurnByTurnEvents.sendEvent(MapboxEventType.ROUTE_BUILD_FAILED, "No Internet Connection")
            return
        }

        MapboxTurnByTurnEvents.sendEvent(MapboxEventType.ROUTE_BUILDING)

        val originLocation = navigationLocationProvider.lastLocation
        val originPoint = originLocation?.let {
            Point.fromLngLat(it.longitude, it.latitude)
        } ?: return

        val combinedWaypoints: List<Point> = listOf(originPoint) + waypoints
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
                .applyLanguageAndVoiceUnitOptions(context)
                .coordinatesList(combinedWaypoints)
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
                    setRouteAndStartNavigation(routes)
                }

                override fun onFailure(
                    reasons: List<RouterFailure>,
                    routeOptions: RouteOptions
                ) {
                    var message = "an error occurred while building the route. Errors: "
                    for (reason in reasons){
                        message += reason.message
                    }
                    MapboxTurnByTurnEvents.sendEvent(MapboxEventType.ROUTE_BUILD_FAILED, message)
                }

                override fun onCanceled(routeOptions: RouteOptions, routerOrigin: RouterOrigin) {
                    MapboxTurnByTurnEvents.sendEvent(MapboxEventType.ROUTE_BUILD_CANCELLED)
                }
            }
        )
    }

    private fun setRouteAndStartNavigation(routes: List<NavigationRoute>) {
        if (routes.isEmpty()){
            MapboxTurnByTurnEvents.sendEvent(MapboxEventType.ROUTE_BUILD_NO_ROUTES_FOUND)
            return
        }

        // Don't let the screen turn off while navigating
        binding.mapView.keepScreenOn = true

        if(disableGesturesWhenNavigating == true) {
            binding.mapView.gestures.doubleTapToZoomInEnabled = false
            binding.mapView.gestures.quickZoomEnabled = false
            binding.mapView.gestures.quickZoomEnabled = false
            binding.mapView.gestures.pinchToZoomEnabled = false
            binding.mapView.gestures.pitchEnabled = false
            binding.mapView.gestures.rotateEnabled = false
            binding.mapView.gestures.scrollEnabled = false
        }

        MapboxTurnByTurnEvents.sendEvent(MapboxEventType.ROUTE_BUILT)

        // set routes, where the first route in the list is the primary route that
        // will be used for active guidance
        mapboxNavigation.setNavigationRoutes(routes)

        // show UI elements
        binding.soundButton.visibility = View.VISIBLE
        binding.tripProgressCard.visibility = View.VISIBLE

        // move the camera to following when new route is available
        navigationCamera.requestNavigationCameraToFollowing()
        navigationStarted = true
        MapboxTurnByTurnEvents.sendEvent(MapboxEventType.NAVIGATION_RUNNING)
    }

    private fun clearRouteAndStopNavigation() {
        navigationStarted = false
        // clear
        mapboxNavigation.setNavigationRoutes(listOf<DirectionsRoute>().toNavigationRoutes())

        // hide UI elements
        binding.soundButton.visibility = View.GONE
        binding.maneuverView.visibility = View.GONE
        binding.tripProgressCard.visibility = View.GONE

        if(disableGesturesWhenNavigating == true) {
            binding.mapView.gestures.doubleTapToZoomInEnabled = true
            binding.mapView.gestures.quickZoomEnabled = true
            binding.mapView.gestures.quickZoomEnabled = true
            binding.mapView.gestures.pinchToZoomEnabled = true
            binding.mapView.gestures.pitchEnabled = true
            binding.mapView.gestures.rotateEnabled = true
            binding.mapView.gestures.scrollEnabled = true
        }

        navigationCamera.requestNavigationCameraToOverview()

        // enable the screen to turn off again when navigation stops
        binding.mapView.keepScreenOn = false
        MapboxTurnByTurnEvents.sendEvent(MapboxEventType.NAVIGATION_CANCELLED)
    }
}
