// Copyright © Rouven Strauss. MIT license.

import ART

extension App {
  enum AppError: ErrorProtocol {
    case dataDownloadFailure(String)

    var humanReadableDescription: String {
      switch self {
      case let .dataDownloadFailure(description):
        return "data download failure: \(description)"
      }
    }
  }
}
