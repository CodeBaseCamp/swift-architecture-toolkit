// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object representing a potential change from a value of a type `T` to another value of the same
/// type.
public struct PotentialChange<T: Equatable> {
  /// Value before change.
  private(set) var previous: T

  /// Value after change.
  private(set) var current: T

  /// Indication whether this instance actually represents a change.
  public let isActualChange: Bool

  /// Initializes with the given `previous` and `current` values.
  public init(_ previous: T, _ current: T) {
    self.previous = previous
    self.current = current
    self.isActualChange = previous != current
  }
}
