import Flutter
import UIKit

class TurnByTurnView: TurnByTurnNative, FlutterPlatformView {
    private var _view: UIView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()

        super.messenger = messenger
        super.methodChannel =
            FlutterMethodChannel(
                name: "flutter_mapbox_turn_by_turn/map_view/method",
                binaryMessenger: messenger
            )
        super.eventChannel =
            FlutterEventChannel(
                name: "flutter_mapbox_turn_by_turn/map_view/events",
                binaryMessenger: messenger
            )

        super.init()

        // iOS views can be created here
        createNativeView(view: _view)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view view: UIView) {
        _view.backgroundColor = UIColor.blue
        let nativeLabel = UILabel()
        nativeLabel.text = "Native text from iOS"
        nativeLabel.textColor = UIColor.white
        nativeLabel.textAlignment = .center
        nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
        view.addSubview(nativeLabel)
    }
}
