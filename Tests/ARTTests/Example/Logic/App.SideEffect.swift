// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation

extension App {
  enum SideEffect: SideEffectProtocol {
    case downloadOfData(from: URL)

    var humanReadableDescription: String {
      switch self {
      case let .downloadOfData(url):
        return "download of data from URL \(url)"
      }
    }
  }
}
