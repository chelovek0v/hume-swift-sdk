import Foundation

// MARK: - WebSocketError Extensions

extension WebSocketError {
  public init(
    code: String,
    customSessionId: String?,
    message: String,
    slug: String,
    type: String
  ) {
    self.code = code
    self.customSessionId = customSessionId
    self.message = message
    self.requestId = nil
    self.slug = slug
    self.type = type
  }
}

// MARK: - WebSocketErrorType Enum

public enum WebSocketErrorType: String {
  case chatGroupNotFound = "E0708"
  case chatResumeFailed = "E0710"

  static func from(_ error: WebSocketError) -> WebSocketErrorType? {
    WebSocketErrorType(rawValue: error.code)
  }

  public var message: String {
    switch self {
    case .chatGroupNotFound:
      return "Could not retrieve previous chat history. Please start a new chat"
    case .chatResumeFailed:
      return "Could not resume previous chat. Please start a new chat"
    }
  }
}
