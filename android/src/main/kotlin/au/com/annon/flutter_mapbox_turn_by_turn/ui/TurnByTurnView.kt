package au.com.annon.flutter_mapbox_turn_by_turn.ui

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.View
import androidx.lifecycle.LifecycleRegistry
import au.com.annon.flutter_mapbox_turn_by_turn.databinding.TurnByTurnNativeBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView


class TurnByTurnView(
    activity: Activity,
    context: Context,
    binding: TurnByTurnNativeBinding,
    lifecycleRegistry: LifecycleRegistry,
    messenger: BinaryMessenger?,
    creationParams: Map<String?, Any?>?,
    )
    : PlatformView  {
    private var nativeView: TurnByTurnNative = TurnByTurnNative(activity, context, binding, lifecycleRegistry, messenger, creationParams)

    override fun getView(): View {
        return nativeView.binding.root
    }

    init {
        nativeView.initializeFlutterChannelHandlers()
        nativeView.initializeMapbox()

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
        nativeView.onDestroy()
        Log.d("TurnByTurnView", "View disposed")
    }
}
