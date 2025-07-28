// Convenience initializer allowing callers to omit `customSessionId`.

extension UserInput {
  public init(text: String) {
    self.init(customSessionId: nil, text: text)
  }
}
