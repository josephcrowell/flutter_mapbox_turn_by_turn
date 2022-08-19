package au.com.annon.flutter_mapbox_turn_by_turn.models

import android.os.Handler
import android.os.Looper
import android.util.Log
import au.com.annon.flutter_mapbox_turn_by_turn.ui.TurnByTurnActivity
import com.google.gson.Gson

enum class MapboxEventType(val value: String) {
    PROGRESS_CHANGE("progressChange"),
    LOCATION_CHANGE("locationChange"),
    MAP_READY("mapReady"),
    ROUTE_BUILDING("routeBuilding"),
    ROUTE_BUILT("routeBuilt"),
    ROUTE_BUILD_FAILED("routeBuildFailed"),
    ROUTE_BUILD_CANCELLED("routeBuildCancelled"),
    ROUTE_BUILD_NO_ROUTES_FOUND("routeBuildNoRoutesFound"),
    USER_OFF_ROUTE("userOffRoute"),
    MILESTONE_EVENT("milestoneEvent"),
    NAVIGATION_RUNNING("navigationRunning"),
    NAVIGATION_CANCELLED("navigationCancelled"),
    NAVIGATION_FINISHED("navigationFinished"),
    FASTER_ROUTE_FOUND("fasterRouteFound"),
    SPEECH_ANNOUNCEMENT("speechAnnouncement"),
    BANNER_INSTRUCTION("bannerInstruction"),
    WAYPOINT_ARRIVAL("waypointArrival"),
    NEXT_ROUTE_LEG_START("nextRouteLegStart"),
    FINAL_DESTINATION_ARRIVAL("finalDestinationArrival"),
    FAILED_TO_REROUTE("failedToReroute"),
    REROUTE_ALONG("rerouteAlong"),
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
            Log.i("sendEvent(MapboxProgressChangeEvent)", "Event data: $dataString")
            handler.post { TurnByTurnActivity.eventSink?.success(jsonString) }
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
            handler.post { TurnByTurnActivity.eventSink?.success(jsonString) }
        }

        fun sendEvent(event: MapboxEventType, data: String = "") {
            val jsonString = "{" +
                        "  \"eventType\": \"${event.value}\"," +
                        "  \"data\": \"${data}\"" +
                        "}"
            handler.post { TurnByTurnActivity.eventSink?.success(jsonString) }
        }

        fun sendJsonEvent(event: MapboxEventType, data: String = "") {
            var dataString = "\"\""

            if(data.isNotEmpty()) {
                dataString = data
            }

            val jsonString = "{" +
                    "  \"eventType\": \"${event.value}\"," +
                    "  \"data\": ${dataString}" +
                    "}"
            handler.post { TurnByTurnActivity.eventSink?.success(jsonString) }
        }
    }
}
