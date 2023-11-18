// Copyright © Rouven Strauss. MIT license.

/// Protocol to be implemented by objects providing a description which is easily readable by
/// humans.
public protocol HumanReadable: CustomDebugStringConvertible {
  /// Description easily readable by humans.
  var humanReadableDescription: String { get }
}

public extension HumanReadable {
  var debugDescription: String {
    humanReadableDescription
  }
}
