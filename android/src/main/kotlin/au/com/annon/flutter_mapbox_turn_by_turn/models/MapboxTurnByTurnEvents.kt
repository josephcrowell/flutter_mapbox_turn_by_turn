package au.com.annon.flutter_mapbox_turn_by_turn.models

import android.os.Handler
import android.os.Looper
import android.util.Log
import au.com.annon.flutter_mapbox_turn_by_turn.ui.TurnByTurnNative
import com.google.gson.Gson

enum class MapboxEventType(val value: String) {
    PROGRESS_CHANGE("progressChange"),
    ENHANCED_LOCATION_CHANGE("enhancedLocationChange"),
    LOCATION_CHANGE("locationChange"),
    ROUTE_BUILDING("routeBuilding"),
    ROUTE_BUILT("routeBuilt"),
    ROUTE_BUILD_FAILED("routeBuildFailed"),
    ROUTE_BUILD_CANCELLED("routeBuildCancelled"),
    ROUTE_BUILD_NO_ROUTES_FOUND("routeBuildNoRoutesFound"),
    USER_OFF_ROUTE("userOffRoute"),
    MILESTONE_EVENT("milestoneEvent"),
    MUTE_CHANGED("muteChanged"),
    NAVIGATION_RUNNING("navigationRunning"),
    NAVIGATION_CANCELLED("navigationCancelled"),
    NAVIGATION_CAMERA_CHANGED("navigationCameraChanged"),
    FASTER_ROUTE_FOUND("fasterRouteFound"),
    WAYPOINT_ARRIVAL("waypointArrival"),
    NEXT_ROUTE_LEG_START("nextRouteLegStart"),
    FINAL_DESTINATION_ARRIVAL("finalDestinationArrival"),
    FAILED_TO_REROUTE("failedToReroute"),
    REROUTE_ALONG("rerouteAlong"),
    STYLE_PACK_PROGRESS("stylePackProgress"),
    STYLE_PACK_FINISHED("stylePackFinished"),
    STYLE_PACK_ERROR("stylePackError"),
    TILE_REGION_PROGRESS("tileRegionProgress"),
    TILE_REGION_FINISHED("tileRegionFinished"),
    TILE_REGION_REMOVED("tileRegionRemoved"),
    TILE_REGION_GEOMETRY_CHANGED("tileRegionGeometryChanged"),
    TILE_REGION_METADATA_CHANGED("tileRegionMetadataChanged"),
    TILE_REGION_ERROR("tileRegionError")
}

class MapboxTurnByTurnEvents {
    companion object {
        private val handler: Handler = Handler(Looper.getMainLooper())

        fun sendEvent(event: MapboxProgressChangeEvent) {
            val dataString = Gson().toJson(event)
            val jsonString = "{" +
                    "  \"eventType\": \"${MapboxEventType.PROGRESS_CHANGE.value}\"," +
                    "  \"data\": $dataString" +
                    "}"
            handler.post { TurnByTurnNative.eventSink?.success(jsonString) }
        }

        fun sendEvent(event: MapboxEnhancedLocationChangeEvent) {
            val jsonString = "{" +
                    "  \"eventType\": \"${MapboxEventType.ENHANCED_LOCATION_CHANGE.value}\"," +
                    "  \"data\": {" +
                    "\"isLocationChangeEvent\": ${event.isEnhancedLocationChangeEvent}," +
                    "\"latitude\": ${event.latitude}," +
                    "\"longitude\": ${event.longitude}" +
                    "}" +
                    "}"
            handler.post { TurnByTurnNative.eventSink?.success(jsonString) }
        }

        fun sendEvent(event: MapboxLocationChangeEvent) {
            val jsonString = "{" +
                    "  \"eventType\": \"${MapboxEventType.LOCATION_CHANGE.value}\"," +
                    "  \"data\": {" +
                    "\"isLocationChangeEvent\": ${event.isLocationChangeEvent}," +
                    "\"latitude\": ${event.latitude}," +
                    "\"longitude\": ${event.longitude}" +
                    "}" +
                    "}"
            handler.post { TurnByTurnNative.eventSink?.success(jsonString) }
        }

        fun sendEvent(event: MapboxEventType, data: String = "") {
            val jsonString = "{" +
                        "  \"eventType\": \"${event.value}\"," +
                        "  \"data\": \"${data}\"" +
                        "}"
            handler.post { TurnByTurnNative.eventSink?.success(jsonString) }
        }

        fun sendJsonEvent(event: MapboxEventType, data: String = "") {
            var dataString = "\"\""

            if(data.isNotEmpty()) {
                dataString = data
            }

            val jsonString = "{" +
                    "  \"eventType\": \"${event.value}\"," +
                    "  \"data\": $dataString" +
                    "}"
            handler.post { TurnByTurnNative.eventSink?.success(jsonString) }
        }
    }
}
