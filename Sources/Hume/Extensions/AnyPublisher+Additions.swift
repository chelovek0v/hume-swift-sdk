import Combine
import Foundation

extension Publisher where Output: Equatable {
  /// Waits for a specific value to be published
  /// - Parameters:
  ///   - value: The value to wait for
  ///   - timeout: Optional timeout duration in seconds
  /// - Returns: The matching value if found
  /// - Throws: TimeoutError if the timeout is reached, or the original publisher's Failure
  @discardableResult
  func waitFor(
    _ value: Output,
    timeout: TimeInterval? = nil
  ) async throws -> Output {
    if let timeout {
      return try await waitForWithTimeout(value, timeout: timeout)
    } else {
      return try await waitForWithoutTimeout(value)
    }
  }

  private func waitForWithoutTimeout(_ value: Output) async throws -> Output {
    try await withCheckedThrowingContinuation { continuation in
      var cancellable: AnyCancellable?
      var foundValue = false

      cancellable =
        self
        .first(where: { $0 == value })
        .sink(
          receiveCompletion: { completion in
            switch completion {
            case .finished:
              // Only throw if we haven't found a value
              if !foundValue {
                continuation.resume(throwing: WaitError.valueNotFound)
              }
            case .failure(let error):
              continuation.resume(throwing: error)
            }
            cancellable?.cancel()
          },
          receiveValue: { value in
            foundValue = true
            continuation.resume(returning: value)
          }
        )
    }
  }

  private func waitForWithTimeout(_ value: Output, timeout: TimeInterval) async throws -> Output {
    try await withThrowingTaskGroup(of: Output.self) { group in
      // Add the value waiting task
      group.addTask {
        try await self.waitForWithoutTimeout(value)
      }

      // Add the timeout task
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        throw WaitError.timeout
      }

      // Wait for first completion
      do {
        let result = try await group.next()

        // Cancel other tasks
        group.cancelAll()

        guard let result else { throw WaitError.valueNotFound }
        return result
      } catch {
        group.cancelAll()
        throw error
      }
    }
  }
}

enum WaitError: Error {
  case timeout
  case valueNotFound
}

// MARK: - Convenience extension for async sequences
extension Publisher where Output: Equatable {
  /// Creates an AsyncSequence that emits elements matching the specified value
  /// - Parameter value: The value to match
  /// - Returns: An AsyncSequence of matching values
  func matching(_ value: Output) -> AsyncThrowingStream<Output, Error> {
    AsyncThrowingStream { continuation in
      let cancellable =
        self
        .filter { $0 == value }
        .sink(
          receiveCompletion: { completion in
            switch completion {
            case .finished:
              continuation.finish()
            case .failure(let error):
              continuation.finish(throwing: error)
            }
          },
          receiveValue: { value in
            continuation.yield(value)
          }
        )

      continuation.onTermination = { _ in
        cancellable.cancel()
      }
    }
  }
}
