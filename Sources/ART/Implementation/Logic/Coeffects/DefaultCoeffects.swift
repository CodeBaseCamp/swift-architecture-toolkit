// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object constituting the default coeffects.
public class DefaultCoeffects: DefaultCoeffectsProtocol {
  // File System functionality.

  private let temporaryDirectoryClosure: () -> URL

  private let documentDirectoryClosure: () -> URL

  private let localeClosure: () -> Locale

  private let dateClosure: () -> Date

  private let uuidClosure: () -> UUID

  /// Initializes with the given values.
  public init(
    temporaryDirectory: @escaping () -> URL = { URL(fileURLWithPath: NSTemporaryDirectory()) },
    documentDirectoryClosure: @escaping () -> URL = {
      let url = try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: false)
      return requiredLet(url, "Document directory must exist")
    },
    localeClosure: @escaping () -> Locale = { Locale.current },

    dateClosure: @escaping () -> Date = { Date() },
    uuidClosure: @escaping () -> UUID = { UUID() }
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
