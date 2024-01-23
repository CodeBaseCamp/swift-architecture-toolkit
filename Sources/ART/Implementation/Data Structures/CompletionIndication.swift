// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Indication of completion.
public enum CompletionIndication<Error: ErrorProtocol>: Equatable, Sendable {
  case success
  case failure(Error)
}

public extension CompletionIndication {
  var isSuccess: Bool {
    return self == .success
  }

  var isFailure: Bool {
    return !self.isSuccess
  }

  var error: Error? {
    guard case let .failure(value) = self else { return nil }
    return value
  }

  func map<NewError: ErrorProtocol>(
    _ closure: (Error) -> NewError
  ) -> CompletionIndication<NewError> {
    switch self {
    case .success:
      return .success
    case let .failure(error):
      return .failure(closure(error))
    }
  }
}

extension CompletionIndication: CustomDebugStringConvertible
  where Error: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .success:
      return "success"
    case let .failure(failure):
      return "failure: \(failure.debugDescription)"
    }
  }
}

extension CompletionIndication: HumanReadable {
  public var humanReadableDescription: String {
    switch self {
    case .success:
      return "success"
    case let .failure(failure):
      return "failure: \(failure.humanReadableDescription)"
    }
  }
}
