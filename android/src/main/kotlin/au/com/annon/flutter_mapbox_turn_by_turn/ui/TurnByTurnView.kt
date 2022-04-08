package au.com.annon.flutter_mapbox_turn_by_turn.ui

import android.view.View
import android.content.Context

import au.com.annon.flutter_mapbox_turn_by_turn.databinding.TurnByTurnActivityBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView


internal class TurnByTurnView(
        context: Context,
        binding: TurnByTurnActivityBinding,
        messenger: BinaryMessenger,
        id: Int,
        creationParams: Map<String?, Any?>?,
    )
    : PlatformView, TurnByTurnActivity(context, binding, messenger) {
    private val id: Int = id

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)
        initializeActivity()
    }

    override fun getView(): View {
        return binding.root
    }

    override fun dispose() {
        onStopActivity()
    }
}
