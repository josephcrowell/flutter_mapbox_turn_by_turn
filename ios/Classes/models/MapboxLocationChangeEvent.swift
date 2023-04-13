import Foundation

public class MapboxLocationChangeEvent: Codable {
  let isLocationChangeEvent: Bool
  let latitude: Double?
  let longitude: Double?

  init(latitude: Double?, longitude: Double?) {
    self.isLocationChangeEvent = true
    self.latitude = latitude
    self.longitude = longitude
  }
}
