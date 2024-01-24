// Copyright © Rouven Strauss. MIT license.

import Foundation

public enum SideEffectExecutionError<Error: ErrorProtocol>: ErrorProtocol {
  case customError(Error)
  case sideEffectBulkExecutionError
}

public extension SideEffectExecutionError {
  var humanReadableDescription: String {
    switch self {
    case let .customError(customError):
      return customError.humanReadableDescription
    case .sideEffectBulkExecutionError:
      return "side effect bulk execution error"
    }
  }
}
