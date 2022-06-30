package au.com.annon.flutter_mapbox_turn_by_turn

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import au.com.annon.flutter_mapbox_turn_by_turn.ui.TurnByTurnViewFactory
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformViewRegistry

/** FlutterMapboxTurnByTurnPlugin */
class FlutterMapboxTurnByTurnPlugin
  : FlutterPlugin, PluginRegistry.RequestPermissionsResultListener, ActivityAware, MethodCallHandler {
  private var activity: Activity? = null
  private lateinit var methodChannel : MethodChannel
  private lateinit var context: Context
  private var platformViewRegistry: PlatformViewRegistry? = null
  private var binaryMessenger: BinaryMessenger? = null

  companion object {
    private var LOCATION_REQUEST_CODE: Int = 367
    private var pendingPermissionResult: Result? = null
    private const val VIEW_NAME = "MapView"
  }

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d("FlutterMapboxTurnByTurnPlugin","Engine attached")
    binaryMessenger = binding.binaryMessenger
    platformViewRegistry = binding.platformViewRegistry
    methodChannel = MethodChannel(binaryMessenger!!, "flutter_mapbox_turn_by_turn/method")
    methodChannel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d("FlutterMapboxTurnByTurnPlugin","Engine detached")
    activity = null
    methodChannel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    Log.d("FlutterMapboxTurnByTurnPlugin","Activity attached")
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)

    if(platformViewRegistry != null && binaryMessenger != null && activity != null) {
      Log.d("FlutterMapboxTurnByTurnPlugin","Registering view factory")
      platformViewRegistry?.registerViewFactory(VIEW_NAME, TurnByTurnViewFactory(binaryMessenger!!, activity!!))
      context = binding.activity.baseContext
    }
  }

  override fun onDetachedFromActivity() {
    Log.d("FlutterMapboxTurnByTurnPlugin","Activity detached")
    activity!!.finish()
    activity = null
    pendingPermissionResult = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.d("FlutterMapboxTurnByTurnPlugin","Activity detached for config changes")
    activity = null
    pendingPermissionResult = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    Log.d("FlutterMapboxTurnByTurnPlugin","Activity reattached for config changes")
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "hasPermission" -> {
        hasPermission(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }


  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {

    if (requestCode == LOCATION_REQUEST_CODE) {
      if (pendingPermissionResult != null) {
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          pendingPermissionResult!!.success(true)
        } else {
          pendingPermissionResult!!.error("-2", "Permission denied", null)
        }
        pendingPermissionResult = null
        return true
      }
    }

    return false
  }

  private fun hasPermission(result: Result) {
    if (!isPermissionGranted()) {
      pendingPermissionResult = result
      askForPermission()
    } else {
      result.success(true)
    }
  }

  private fun isPermissionGranted(): Boolean {
    val result: Int = ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
    return result == PackageManager.PERMISSION_GRANTED
  }

  private fun askForPermission() {
    ActivityCompat.requestPermissions(
      activity!!, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
      LOCATION_REQUEST_CODE
    )
  }
}
