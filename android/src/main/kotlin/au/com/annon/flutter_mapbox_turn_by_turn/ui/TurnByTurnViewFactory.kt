package au.com.annon.flutter_mapbox_turn_by_turn.ui

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.lifecycle.LifecycleRegistry
import au.com.annon.flutter_mapbox_turn_by_turn.databinding.TurnByTurnNativeBinding
import io.flutter.plugin.common.*
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

@Suppress("UNCHECKED_CAST")
class TurnByTurnViewFactory(
        private val messenger: BinaryMessenger,
        private val activity: Activity,
        private val binding: TurnByTurnNativeBinding,
        private val lifecycleRegistry: LifecycleRegistry
    )
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        Log.d("TurnByTurnViewFactory", "Creating TurnByTurnViewFactory")
        val creationParams = args as Map<String?, Any?>?
        return TurnByTurnView(
            activity,
            context!!,
            binding,
            lifecycleRegistry,
            messenger,
            creationParams
        )
    }
}
