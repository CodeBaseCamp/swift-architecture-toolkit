// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Representation of an update of a property with a new value.
public struct PropertyUpdate<T: Equatable>: @unchecked Sendable {
  /// Key path to the property to update.
  public let keyPath: PartialKeyPath<T>

  /// Value to update the property with.
  public let value: any Sendable

  /// Closure to apply for updating.
  private let updated: (T) -> (T)

  private let equals: (any Sendable) -> Bool

  private init<S: Equatable & Sendable>(keyPath: WritableKeyPath<T, S>, value: S) {
    self.keyPath = keyPath
    self.value = value
    self.updated = {
      return make($0) { entityToUpdate in
        entityToUpdate[keyPath: keyPath] = value
      }
    }
    self.equals = { $0 as? S == value }
  }

  /// Returns a new instance with the given `keyPath` and `value`.
  public static func instance<S: Equatable & Sendable>(_ keyPath: WritableKeyPath<T, S>, _ value: S) -> Self {
    return Self(keyPath: keyPath, value: value)
  }

  /// Returns the value resulting from applying the update represented by the receiver to a copy of
  /// the given `value`.
  public func updatedValue(_ value: T) -> T {
    return updated(value)
  }
}

extension PropertyUpdate: Equatable {
  public static func == (lhs: PropertyUpdate<T>, rhs: PropertyUpdate<T>) -> Bool {
    return lhs.keyPath == rhs.keyPath && lhs.equals(rhs.value)
  }
}

public struct ValueConverter<T: Equatable> {
  private let keyPath: PartialKeyPath<T>

  private let update: (Any) -> PropertyUpdate<T>

  private let projectedValue: (T) -> Any

  private init<S, V>(
    keyPath: WritableKeyPath<T, S>,
    update: @escaping (Any) -> PropertyUpdate<T>,
    projectedValue: @escaping (T) -> V
  ) {
    self.keyPath = keyPath
    self.update = update
    self.projectedValue = projectedValue
  }

  private init<S: Equatable & Sendable>(keyPath: WritableKeyPath<T, S>) {
    self.init(
      keyPath: keyPath,
      update: { .instance(keyPath, $0 as! S) },
      projectedValue: { $0[keyPath: keyPath] }
    )
  }

  public static func unconverted<S: Equatable & Sendable>(_ keyPath: WritableKeyPath<T, S>) -> Self {
    return Self(keyPath: keyPath)
  }

  public func update(for value: Any) -> PropertyUpdate<T> {
    return self.update(value)
  }

  public func value<V>(_ value: T) -> V {
    self.projectedValue(value) as! V
  }
}
