// Copyright © Rouven Strauss. MIT license.

/// Ensures the correctness of the given `condition` by raising an assertion with a message computed
/// using the given `messageClosure` if the given `conditionClosure` evaluates to `false`.
@inlinable
public func ensure(_ conditionClosure: @autoclosure () -> Bool, _ messageClosure: @autoclosure () -> String) {
  guard conditionClosure() else {
    fatalError(messageClosure())
  }
}

/// Ensures the non-emptiness of the given `collection` by raising an assertion if the given `collection` is empty.
@inlinable
public func ensureNonEmptiness(of collection: some Collection) {
  guard !collection.isEmpty else {
    fatalError("Collection \(collection) must be non-empty")
  }
}
