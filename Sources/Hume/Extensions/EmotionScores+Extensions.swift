import Foundation

public struct ExpressionMeasurement {
  public let name: String
  public let value: Double

  package init(_ name: String, _ value: Double) {
    self.name = name
    self.value = value
  }
}

extension EmotionScores {
  /// Converts the EmotionScores struct to a dictionary format
  public var asDictionary: [String: Double] {
    return [
      "admiration": admiration,
      "adoration": adoration,
      "aestheticAppreciation": aestheticAppreciation,
      "amusement": amusement,
      "anger": anger,
      "anxiety": anxiety,
      "awe": awe,
      "awkwardness": awkwardness,
      "boredom": boredom,
      "calmness": calmness,
      "concentration": concentration,
      "confusion": confusion,
      "contemplation": contemplation,
      "contempt": contempt,
      "contentment": contentment,
      "craving": craving,
      "desire": desire,
      "determination": determination,
      "disappointment": disappointment,
      "disgust": disgust,
      "distress": distress,
      "doubt": doubt,
      "ecstasy": ecstasy,
      "embarrassment": embarrassment,
      "empathicPain": empathicPain,
      "entrancement": entrancement,
      "envy": envy,
      "excitement": excitement,
      "fear": fear,
      "guilt": guilt,
      "horror": horror,
      "interest": interest,
      "joy": joy,
      "love": love,
      "nostalgia": nostalgia,
      "pain": pain,
      "pride": pride,
      "realization": realization,
      "relief": relief,
      "romance": romance,
      "sadness": sadness,
      "satisfaction": satisfaction,
      "shame": shame,
      "surpriseNegative": surpriseNegative,
      "surprisePositive": surprisePositive,
      "sympathy": sympathy,
      "tiredness": tiredness,
      "triumph": triumph
    ]
  }

  /// Returns the top three emotions with the highest scores
  public var topThree: [ExpressionMeasurement] {
    return asDictionary
      .sorted { $0.value >= $1.value }
      .prefix(3)
      .map(ExpressionMeasurement.init)
  }
} 