package au.com.annon.flutter_mapbox_turn_by_turn

import androidx.annotation.NonNull
import androidx.LatLng

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterMapboxTurnByTurnPlugin */
class FlutterMapboxTurnByTurnPlugin: FlutterPlugin, MethodCallHandler {
  var activity: android.app.Activity? = null;
  private lateinit var channel : MethodChannel;

  private List<LatLng> waypoints;

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_mapbox_turn_by_turn/method");
    channel.setMethodCallHandler(this);
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}");
    } else if (call.method == "startNavigation") {

    } else {
      result.notImplemented();
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null);
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity;
    binding.addActivityResultListener(this);
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity;
    binding.addActivityResultListener(this);
  }

  override fun onDetachedFromActivity() {
    act = null;
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    return false;
  }
}
