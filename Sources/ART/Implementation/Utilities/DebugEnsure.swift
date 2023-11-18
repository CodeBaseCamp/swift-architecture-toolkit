// Copyright © Rouven Strauss. MIT license.

/// Ensures the correctness of the given `condition` by raising an assertion with a message computed
/// using the given `messageClosure` if the given `conditionClosure` evaluates to `false`.
///
/// - important Has an effect only when compiled in debug mode.
@inline(__always) public func debugEnsure(_ conditionClosure: @autoclosure () -> Bool,
                                          _ messageClosure: @autoclosure () -> String) {
  #if DEBUG
    ensure(conditionClosure(), messageClosure())
  #endif
}
