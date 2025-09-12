package au.com.annon.flutter_mapbox_turn_by_turn.models

class MapboxEnhancedLocationChangeEvent(location: com.mapbox.common.location.Location) {
    val isEnhancedLocationChangeEvent = true
    var latitude: Double? = null
    var longitude: Double? = null

    init {
        latitude = location.latitude
        longitude = location.longitude
    }
}
