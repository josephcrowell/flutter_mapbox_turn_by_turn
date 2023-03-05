import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation

class CustomNightStyle: NightStyle {

  required init() {
    super.init()
    initStyle()
  }

  init(url: String?) {
    super.init()
    initStyle()
    if url != nil {
      mapStyleURL = URL(string: url!) ?? URL(string: StyleURI.navigationNight.rawValue)!
      previewMapStyleURL = mapStyleURL
    }
  }

  func initStyle() {
    // Use a custom map style.
    mapStyleURL = URL(string: StyleURI.navigationNight.rawValue)!
    previewMapStyleURL = mapStyleURL

    // Specify that the style should be used during the night.
    styleType = .night
  }

  override func apply() {
    super.apply()
    // Begin styling the UI
    //BottomBannerView.appearance().backgroundColor = .orange
  }
}
