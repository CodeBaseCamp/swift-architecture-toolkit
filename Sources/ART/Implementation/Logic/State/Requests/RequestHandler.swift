// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol implemented by objects allowing for the handling of `Request`s.
public protocol RequestHandler {
  associatedtype Request: RequestProtocol
  associatedtype Coeffects

  /// Handles the given `requests` using the given `coeffects`.
  func handleInSingleTransaction(_ requests: [Request], using coeffects: Coeffects)
}

public extension RequestHandler {
  /// Handles the given `request` using the given `coeffects`.
  func handle(_ request: Request, using coeffects: Coeffects) {
    self.handleInSingleTransaction(request, using: coeffects)
  }

  /// Handles the given `requests` using the given `coeffects`.
  func handleInSingleTransaction(_ requests: Request ..., using coeffects: Coeffects) {
    self.handleInSingleTransaction(requests, using: coeffects)
  }
}
