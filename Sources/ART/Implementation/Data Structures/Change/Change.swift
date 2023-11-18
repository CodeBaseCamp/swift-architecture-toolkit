// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object representing a change from a value of a type `T` to another value of the same type.
public struct Change<T: Equatable>: Equatable {
  /// Value before change.
  public private(set) var previous: T

  /// Value after change.
  public private(set) var current: T

  /// Initializes with the given `previous` and `current` values.
  ///
  /// - important The given `previous` and `current` values must not be equal.
  public init(_ previous: T, _ current: T) {
    ensure(previous != current, "Previous \(previous) must not equal current \(current)")

    self.previous = previous
    self.current = current
  }

  private init(_ previous: T, _ current: T, performComparison: Bool) {
    if performComparison {
      ensure(previous != current, "Previous \(previous) must not equal current \(current)")
    }

    self.previous = previous
    self.current = current
  }

  /// Returns an instance with the values from the given `potentialChange` if the given
  /// `potentialChange` is an actual change. Otherwise, returns `nil`.
  public static func safeInstance(from potentialChange: PotentialChange<T>) -> Self? {
    return potentialChange.isActualChange ?
      Self(potentialChange.previous, potentialChange.current, performComparison: false) : nil
  }

  /// Returns an instance with the given `previous` and `current` values if they differ from each
  /// other. Otherwise, returns `nil`.
  public static func safeInstance(_ previous: T, _ current: T) -> Self? {
    previous != current ? Change(previous, current) : nil
  }

  /// Returns `true` if the `previous` and `current` values of the receiver differ at the given
  /// `keyPath`. Otherwise, returns `false`.
  public func hasChange<V: Equatable>(at keyPath: KeyPath<T, V>) -> Bool {
    return previous[keyPath: keyPath] != current[keyPath: keyPath]
  }

  /// Returns `true` if the `previous` value of the receiver at the given `keyPath` equals the
  /// given `allegedPreviousValue` and the `current` value equals the given `allegedCurrentValue`.
  /// Otherwise, returns `false`.
  ///
  /// - important The given `allegedPreviousValue` and `allegedCurrentValue` must not be equal.
  public func hasChange<V: Equatable>(
    at keyPath: KeyPath<T, V>,
    from allegedPreviousValue: V,
    to allegedCurrentValue: V
  ) -> Bool {
    ensure(allegedPreviousValue != allegedCurrentValue, "Equal values: \(allegedCurrentValue)")

    return previous[keyPath: keyPath] == allegedPreviousValue &&
      current[keyPath: keyPath] == allegedCurrentValue
  }

  /// Returns a new potential change for the values of the receiver at the given `keyPath`.
  public func potentialChange<V: Equatable>(for keyPath: KeyPath<T, V>) -> PotentialChange<V> {
    return PotentialChange(previous[keyPath: keyPath], current[keyPath: keyPath])
  }

  /// Returns a new change for the values of the receiver at the given `keyPath` if they differ.
  /// Otherwise, returns `nil`.
  public func change<V: Equatable>(for keyPath: KeyPath<T, V>) -> Change<V>? {
    return Change<V>.safeInstance(from: self.potentialChange(for: keyPath))
  }
}

extension Change: Codable where T: Codable {}

public extension Change {
  /// Executes the given `closure` if the receiver constitutes a change of the given `keyPath`.
  func executeIfChange<V: Equatable>(
    of keyPath: KeyPath<T, V>,
    _ closure: (Change<V>) -> Void
  ) {
    let previousValue = previous[keyPath: keyPath]
    let currentValue = current[keyPath: keyPath]

    guard previousValue != currentValue else {
      return
    }

    closure(.init(previousValue, currentValue))
  }
}
