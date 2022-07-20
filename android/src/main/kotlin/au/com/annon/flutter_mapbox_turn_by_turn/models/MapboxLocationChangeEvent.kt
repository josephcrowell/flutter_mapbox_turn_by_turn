package au.com.annon.flutter_mapbox_turn_by_turn.models

import android.location.Location

class MapboxLocationChangeEvent(location: Location) {
    val isLocationChangeEvent = true
    var latitude: Double? = null
    var longitude: Double? = null

    init {
        latitude = location.latitude
        longitude = location.longitude
    }
}