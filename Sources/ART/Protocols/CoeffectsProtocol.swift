// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol to be implemented by objects providing coeffects.
public protocol CoeffectsProtocol: Sendable {
  var `default`: DefaultCoeffectsProtocol { get }
}

/// Protocol implemented by objects providing default coeffects.
public protocol DefaultCoeffectsProtocol: Sendable {
  // Returns the URL of the `NSTemporaryDirectory` directory.
  @Sendable
  func temporaryDirectory() -> URL

  // Returns the URL of the user's document directory.
  @Sendable
  func documentDirectory() -> URL

  // Returns the currently set locale.
  @Sendable
  func currentLocale() -> Locale

  // Returns the current date.
  @Sendable
  func currentDate() -> Date

  // Returns a new `UUID`.
  @Sendable
  func newUUID() -> UUID
}
