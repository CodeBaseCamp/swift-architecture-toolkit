// Copyright © Rouven Strauss. MIT license.

/// Ensures the correctness of the given `condition` by raising an assertion with a message computed
/// using the given `messageClosure` if the given `conditionClosure` evaluates to `false`.
///
/// - important Has an effect only when compiled in debug mode.
@inlinable public func debugEnsure(
  _ conditionClosure: @autoclosure () -> Bool,
  _ messageClosure: @autoclosure () -> String
) {
  #if DEBUG
    ensure(conditionClosure(), messageClosure())
  #endif
}

/// Causes a fatal error if and only if run in debug mode.
@inlinable public func debugCrash(
  _ messageClosure: @autoclosure () -> String
) {
  #if DEBUG
    fatalError(messageClosure())
  #endif
}
