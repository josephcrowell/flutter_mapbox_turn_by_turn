import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation

public class MapboxProgressChangeEvent: Codable {
  let isProgressChangeEvent: Bool
  let currentLegDistanceRemaining: Double
  let currentLegDistanceTraveled: Double
  let currentStepInstruction: String
  let distance: Double
  let distanceTraveled: Double
  let duration: Double
  let legIndex: Int

  init(progress: RouteProgress) {
    isProgressChangeEvent = true
    currentLegDistanceRemaining = progress.currentLegProgress.distanceRemaining
    currentLegDistanceTraveled = progress.currentLegProgress.distanceTraveled
    currentStepInstruction = progress.currentLegProgress.currentStep.description
    distance = progress.distanceRemaining
    distanceTraveled = progress.distanceTraveled
    duration = progress.durationRemaining
    legIndex = progress.legIndex
  }
}
