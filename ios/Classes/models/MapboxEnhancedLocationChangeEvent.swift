import Foundation

public class MapboxEnhancedLocationChangeEvent: Codable {
  let isEnhancedLocationChangeEvent: Bool
  let latitude: Double?
  let longitude: Double?

  init(latitude: Double?, longitude: Double?) {
    self.isEnhancedLocationChangeEvent = true
    self.latitude = latitude
    self.longitude = longitude
  }
}
