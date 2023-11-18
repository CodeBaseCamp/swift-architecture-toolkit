// Copyright © Rouven Strauss. MIT license.

/// Protocol to be implemented by value objects serving as immmutable, equatable representations of
/// requests for handling an event or command, potentially changing a particular part of a state.
///
/// - note By default, a request is assumed to change the state. Value objects conforming to this
///        protocol but not necessarily changing the state should override the `mustResultInChange`
///        method accordingly.
public protocol RequestProtocol: Equatable, HumanReadable {
  /// Returns `true` if the receiver must result in a change of the state, otherwise `false`. `true`
  /// by default.
  ///
  /// Example for a request which is allowed to not result in a state change: if the request
  /// consists of a value which should be set after a touch event and the relevant part of the state
  /// already equals that value, the receiver should return `true` to avoid a fatal error.
  func mustResultInChange() -> Bool
}

public extension RequestProtocol {
  func mustResultInChange() -> Bool {
    return true
  }
}

public extension Array where Element: RequestProtocol {
  func mustResultInChange() -> Bool {
    return self.reduce(false) { $0 || $1.mustResultInChange() }
  }

  var humanReadableDescription: String {
    return self.reduce("") {
      $0 + """
      \($1.humanReadableDescription)
      """
    }
  }
}
