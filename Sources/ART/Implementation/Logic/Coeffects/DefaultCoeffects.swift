// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object constituting the default coeffects.
final public class DefaultCoeffects: DefaultCoeffectsProtocol {
  // File System functionality.

  private let temporaryDirectoryClosure: @Sendable () -> URL

  private let documentDirectoryClosure: @Sendable () -> URL

  private let localeClosure: @Sendable () -> Locale

  private let dateClosure: @Sendable () -> Date

  private let uuidClosure: @Sendable () -> UUID

  /// Initializes with the given values.
  public init(
    temporaryDirectory: @escaping @Sendable () -> URL = { URL(fileURLWithPath: NSTemporaryDirectory()) },
    documentDirectoryClosure: @escaping @Sendable () -> URL = {
      let url = try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: false)
      return requiredLet(url, "Document directory must exist")
    },
    localeClosure: @escaping @Sendable () -> Locale = { Locale.current },

    dateClosure: @escaping @Sendable () -> Date = { Date() },
    uuidClosure: @escaping @Sendable () -> UUID = { UUID() }
  ) {
    self.temporaryDirectoryClosure = temporaryDirectory
    self.documentDirectoryClosure = documentDirectoryClosure
    self.localeClosure = localeClosure
    self.dateClosure = dateClosure
    self.uuidClosure = uuidClosure
  }

  // MARK: DefaultCoeffectsProtocol

  public func temporaryDirectory() -> URL {
    self.temporaryDirectoryClosure()
  }

  public func documentDirectory() -> URL {
    self.documentDirectoryClosure()
  }

  public func currentLocale() -> Locale {
    self.localeClosure()
  }

  public func currentDate() -> Date {
    self.dateClosure()
  }

  public func newUUID() -> UUID {
    self.uuidClosure()
  }
}
