import Foundation

extension AudioOutput {
  /// Attempts to decode the base64 encoded `data` attributed into
  /// a `Data` type that can be played.
  public var asBase64EncodedData: Data? {
    Data(base64Encoded: data)
  }
} 