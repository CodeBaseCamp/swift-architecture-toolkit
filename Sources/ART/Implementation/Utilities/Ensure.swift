// Copyright © Rouven Strauss. MIT license.

/// Ensures the correctness of the given `condition` by raising an assertion with a message computed
/// using the given `messageClosure` if the given `conditionClosure` evaluates to `false`.
@inline(__always) public func ensure(_ conditionClosure: @autoclosure () -> Bool,
                                     _ messageClosure: @autoclosure () -> String) {
  guard conditionClosure() else {
    fatalError(messageClosure())
  }
}
