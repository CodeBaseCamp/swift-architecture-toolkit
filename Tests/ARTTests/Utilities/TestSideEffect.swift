// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation

enum TestSideEffect: SideEffectProtocol {
  enum FileSystemSideEffect: SideEffectProtocol {
    case creationOfFile(atPath: String, with: Data)
    case movingOfItem(fromPath: String, toPath: String)
    case removalOfItem(atPath: String)
  }

  case inFileSystemScope(FileSystemSideEffect)
}

extension TestSideEffect {
  var humanReadableDescription: String {
    switch self {
    case let .inFileSystemScope(sideEffect):
      return "in file system scope: \(sideEffect.humanReadableDescription)"
    }
  }
}

extension TestSideEffect.FileSystemSideEffect {
  var humanReadableDescription: String {
    switch self {
    case let .creationOfFile(path, _):
      return "creation of file at path \"\(path)\""
    case let .movingOfItem(sourcePath, targetPath):
      return "moving of file from path \"\(sourcePath)\" to \"\(targetPath)\""
    case let .removalOfItem(path):
      return "removal of file at path \"\(path)\""
    }
  }
}
