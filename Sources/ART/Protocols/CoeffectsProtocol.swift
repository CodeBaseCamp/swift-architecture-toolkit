// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol to be implemented by objects providing coeffects.
public protocol CoeffectsProtocol: Sendable {
  var `default`: DefaultCoeffectsProtocol { get }
}

/// Protocol implemented by objects providing default coeffects.
public protocol DefaultCoeffectsProtocol {
  // Returns the URL of the `NSTemporaryDirectory` directory.
  func temporaryDirectory() -> URL

  // Returns the URL of the user's document directory.
  func documentDirectory() -> URL

  // Returns the currently set locale.
  func currentLocale() -> Locale

  // Returns the current date.
  func currentDate() -> Date

  // Returns a new `UUID`.
  func newUUID() -> UUID
}
