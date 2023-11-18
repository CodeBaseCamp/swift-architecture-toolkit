// Copyright © Rouven Strauss. MIT license.

@inline(__always) public func fatalErrorDueToMissingImplementation() -> Never {
  fatalError("Not implemented")
}
