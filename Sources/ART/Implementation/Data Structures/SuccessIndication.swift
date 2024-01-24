// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Indication of success or failure.
public enum SuccessIndication: Hashable, Sendable {
  case success
  case failure
}

public extension SuccessIndication {
  var isSuccess: Bool {
    return self == .success
  }

  var isFailure: Bool {
    return !self.isSuccess
  }
}
