import Foundation
import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class CustomDayStyle: DayStyle {

  required init() {
    super.init()
    initStyle()
  }

  init(url: String?) {
    super.init()
    initStyle()
    if url != nil {
      mapStyleURL = URL(string: url!) ?? URL(string: StyleURI.navigationDay.rawValue)!
      previewMapStyleURL = mapStyleURL
    }
  }

  func initStyle() {
    // Use a custom map style.
    mapStyleURL = URL(string: StyleURI.navigationDay.rawValue)!
    previewMapStyleURL = mapStyleURL

    // Specify that the style should be used during the day.
    styleType = .day
  }

  override func apply() {
    super.apply()
    
    // Begin styling the phone UI
    let traitCollection = UIScreen.main.traitCollection
    TopBannerView.appearance(
      for: traitCollection
    ).backgroundColor = UIColor.init(hex: "#1A0000FF")
    BottomBannerView.appearance(
      for: traitCollection
    ).backgroundColor = UIColor.init(hex: "#1AFFFFFF")
  }
}
