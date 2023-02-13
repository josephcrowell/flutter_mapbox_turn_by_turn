package au.com.annon.flutter_mapbox_turn_by_turn.models

import android.location.Location

class MapboxEnhancedLocationChangeEvent(location: Location) {
    val isEnhancedLocationChangeEvent = true
    var latitude: Double? = null
    var longitude: Double? = null

    init {
        latitude = location.latitude
        longitude = location.longitude
    }
}
