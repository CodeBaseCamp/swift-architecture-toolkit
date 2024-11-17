// Copyright © Rouven Strauss. MIT license.

/// Protocol to be implemented by objects maintaining observable state.
public protocol ModelProtocol: Actor {
  /// The observable state maintained by this instance.
  associatedtype State: Codable, Equatable, Sendable

  /// Adds the given `observer` to the receiver. The `observer` is immediately informed about the
  /// current value of the property the `observer` is observing. Following this immediate update,
  /// the `observer` is informed about every change of the value of the property the `observer` is
  /// observing.
  ///
  /// - important: The given `observer` is held weakly by the receiver.
  func add(_ observer: ModelObserver<State>) async
}

public extension ModelProtocol {
  /// Convenience method for adding `PropertyPathObserver`. See the `add` method instead.
  func add<T>(_ observer: PropertyPathObserver<State, T>) async {
    await self.add(observer.modelObserver)
  }
}
