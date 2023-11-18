// Copyright © Rouven Strauss. MIT license.

/// Returns the value computed by the given `valueClosure` if it not `nil`, otherwise raises an
/// assertion with a message computed using the given `messageClosure`.
@inline(__always) public func requiredLet<T>(
  _ valueClosure: @autoclosure () throws -> T?,
  _ messageClosure: @autoclosure () -> String = "Must exist"
) rethrows -> T {
  guard let safeValue = try valueClosure() else {
    fatalError(messageClosure())
  }

  return safeValue
}
