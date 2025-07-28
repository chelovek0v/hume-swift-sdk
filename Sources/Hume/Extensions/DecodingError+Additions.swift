import Foundation

extension DecodingError {
  /// A human-readable description of the `DecodingError` including the failed coding keys.
  var prettyDescription: String {
    switch self {
    case .typeMismatch(let type, let context):
      return """
        \tType mismatch for type: \(type)
        \tCoding Path: \(context.prettyCodingPath)
        \tDebug Description: \(context.debugDescription)
        """

    case .valueNotFound(let type, let context):
      return """
        \tValue not found for type: \(type)
        \tCoding Path: \(context.prettyCodingPath)
        \tDebug Description: \(context.debugDescription)
        """

    case .keyNotFound(let key, let context):
      return """
        \tKey not found: \(key.stringValue)
        \tCoding Path: \(context.prettyCodingPath)
        \tDebug Description: \(context.debugDescription)
        """

    case .dataCorrupted(let context):
      return """
        \tData corrupted.
        \tCoding Path: \(context.prettyCodingPath)
        \tDebug Description: \(context.debugDescription)
        """

    @unknown default:
      return "An unknown decoding error occurred."
    }
  }
}

extension DecodingError.Context {
  /// Pretty-prints the coding path as a string.
  fileprivate var prettyCodingPath: String {
    guard !codingPath.isEmpty else { return "None" }
    return codingPath.map { $0.stringValue }.joined(separator: " -> ")
  }
}
