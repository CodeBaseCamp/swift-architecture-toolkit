// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Value object representing a value with well-defined default value.
public struct ValueWithDefault<T: Codable & Equatable>: Codable, Equatable, HumanReadable {
  /// Value.
  public var value: T

  /// Default value.
  public let defaultValue: T

  private init(_ value: T, defaultValue: T) {
    self.value = value
    self.defaultValue = defaultValue
  }

  public init(_ value: T) {
    self.init(value, defaultValue: value)
  }

  /// Copy of this instance, with the given `value` instead of the current `value`.
  public func copy(with value: T) -> Self {
    Self(value, defaultValue: defaultValue)
  }

  /// Copy of this instance with its `value` reset to its `defaultValue`.
  public var reset: Self {
    Self(defaultValue)
  }

  public var humanReadableDescription: String {
    "\(value), default: \(defaultValue)"
  }
}

extension ValueWithDefault: Hashable where T: Hashable {}
