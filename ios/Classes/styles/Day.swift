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
    TopBannerView.appearance(for: UITraitCollection(userInterfaceIdiom: .phone)).backgroundColor = UIColor.init(hex: "#1A000000")
    BottomBannerView.appearance(for: UITraitCollection(userInterfaceIdiom: .phone)).backgroundColor = UIColor.init(hex: "#1A000000")
    
    // Begin styling the tablet UI
    TopBannerView.appearance(for: UITraitCollection(userInterfaceIdiom: .pad)).backgroundColor = UIColor.init(hex: "#1A000000")
    BottomBannerView.appearance(for: UITraitCollection(userInterfaceIdiom: .pad)).backgroundColor = UIColor.init(hex: "#1A000000")
  }
}
