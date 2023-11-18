// Copyright © Rouven Strauss. MIT license.

import ART

enum TestError {
  enum FileSystemError {
    case creationOfFile(path: String)
    case removalOfItem(path: String)
  }

  case inFileSystemScope(FileSystemError)
  case ignoredError
}

extension TestError: ErrorProtocol {
  public var humanReadableDescription: String {
    switch self {
    case let .inFileSystemScope(error):
      return "in file system scope: \(error.humanReadableDescription)"
    case .ignoredError:
      return "ignored error"
    }
  }
}

extension TestError.FileSystemError: ErrorProtocol {
  public var humanReadableDescription: String {
    switch self {
    case let .creationOfFile(path):
      return "creation of file at path \"\(path)\""
    case let .removalOfItem(path):
      return "removal of item at path \"\(path)\""
    }
  }
}
