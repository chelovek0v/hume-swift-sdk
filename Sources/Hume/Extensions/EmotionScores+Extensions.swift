// This file contains extensions to generated types
import Foundation

public struct ExpressionMeasurement {
  public let name: String
  public let value: Double

  public init(_ name: String, _ value: Double) {
    self.name = name
    self.value = value
  }
}

extension EmotionScores {
  public var topThree: [ExpressionMeasurement] {
    return
      self
      .sorted { $0.value >= $1.value }
      .prefix(3)
      .map(ExpressionMeasurement.init)
  }
}
