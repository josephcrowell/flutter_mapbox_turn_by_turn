package au.com.annon.flutter_mapbox_turn_by_turn.models

import android.location.Location

class MapboxLocationChangeEvent(location: Location) {
    private var latitude: Double? = null
    private var longitude: Double? = null

    init {
        latitude = location.latitude
        longitude = location.longitude
    }
}