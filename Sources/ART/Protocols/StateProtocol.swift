// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol to be implemented by value objects serving as mutable, equatable, persistable
/// representations of the application state.
public protocol StateProtocol: Codable, Equatable, Sendable {
  /// Returns a new instance from the given `data` representation.
  static func instance(from data: Data) throws -> Self

  /// Returns a `Data` representation of this instance.
  func data() throws -> Data
}
