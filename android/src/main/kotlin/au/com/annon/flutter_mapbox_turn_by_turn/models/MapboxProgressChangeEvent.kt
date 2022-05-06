package au.com.annon.flutter_mapbox_turn_by_turn.models

import com.mapbox.navigation.base.trip.model.RouteProgress

class MapboxProgressChangeEvent(progress: RouteProgress) {
    private val isProgressChangeEvent = true
    private var currentLegDistanceRemaining: Float? = null
    private var currentLegDistanceTraveled: Float? = null
    private var currentStepInstruction: String? = null
    private var distance: Float? = null
    private var distanceTraveled: Float? = null
    private var duration: Double? = null
    private var legIndex: Int? = null

    init {
        currentLegDistanceRemaining = progress.currentLegProgress?.distanceRemaining
        currentLegDistanceTraveled = progress.currentLegProgress?.distanceTraveled
        currentStepInstruction = progress.bannerInstructions?.primary()?.text()
        distance = progress.distanceRemaining
        distanceTraveled = progress.distanceTraveled
        duration = progress.durationRemaining
        legIndex = progress.currentLegProgress?.legIndex
    }
}