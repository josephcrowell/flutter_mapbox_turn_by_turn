package au.com.annon.flutter_mapbox_turn_by_turn.ui

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.View
import androidx.annotation.NonNull
import androidx.lifecycle.LifecycleRegistry
import au.com.annon.flutter_mapbox_turn_by_turn.databinding.TurnByTurnNativeBinding
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView


class TurnByTurnView(
    activity: Activity,
    context: Context,
    private val binding: TurnByTurnNativeBinding,
    private val factory: TurnByTurnViewFactory,
    lifecycleRegistry: LifecycleRegistry,
    private var messenger: BinaryMessenger?,
    creationParams: Map<String?, Any?>?,
    )
    : PlatformView, TurnByTurnNative(activity, context, binding, lifecycleRegistry, creationParams) {

    override fun getView(): View {
        return binding.root
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.d("TurnByTurnView", "Configuring Flutter engine")
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("MapView", factory)
    }

    override fun cleanUpFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        Log.d("TurnByTurnView", "Cleaning up Flutter engine")
        flutterEngine.platformViewsController.detachFromView()
    }

    init {
        initializeFlutterChannelHandlers()
        initializeMapbox()

        Log.d("TurnByTurnView", "View initialised")
    }

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)
        Log.d("TurnByTurnView", "View attached")
    }

    override fun onFlutterViewDetached() {
        super.onFlutterViewDetached()
        Log.d("TurnByTurnView", "View detached")
    }

    override fun dispose() {
        if(observersRegistered) {
            unregisterObservers()
        }
        methodChannel = null
        eventSink!!.endOfStream()
        eventSink = null
        eventChannel = null
        messenger = null

        super.onDestroy()
        Log.d("TurnByTurnView", "View disposed")
    }

    override fun initializeFlutterChannelHandlers() {
        methodChannel = MethodChannel(messenger!!, "flutter_mapbox_turn_by_turn/map_view/method")
        eventChannel = EventChannel(messenger, "flutter_mapbox_turn_by_turn/map_view/events")
        super.initializeFlutterChannelHandlers()
    }
}
