package au.com.annon.flutter_mapbox_turn_by_turn

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull

import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.api.directions.v5.models.DirectionsRoute
import com.mapbox.geojson.Point

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformViewRegistry
import java.util.*

import au.com.annon.flutter_mapbox_turn_by_turn.activity.TurnByTurnActivity

/** FlutterMapboxTurnByTurnPlugin */
class FlutterMapboxTurnByTurnPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  var activity: android.app.Activity? = null
  private lateinit var channel : MethodChannel
  private lateinit var result: Result

  //private List<LatLng> waypoints

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_mapbox_turn_by_turn/method");
    channel.setMethodCallHandler(this);
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    this.result = result;
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
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity;
  }

  override fun onDetachedFromActivity() {
    activity = null;
  }
}
