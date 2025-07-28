// Convenience initializer allowing callers to omit `customSessionId`.
// Keeps existing generated initializer untouched.

extension AssistantInput {
  public init(text: String) {
    self.init(customSessionId: nil, text: text)
  }
}
