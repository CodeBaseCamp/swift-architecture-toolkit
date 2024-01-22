// Copyright © Rouven Strauss. MIT license.

import ART

extension App {
  enum Request: RequestProtocol {
    case completionOfDataDownload(Result<ArbitraryDownloadableResource, AppError>)
    case dismissalOfErrorMessage

    var humanReadableDescription: String {
      switch self {
      case .completionOfDataDownload:
        return "completion of data download"
      case .dismissalOfErrorMessage:
        return "dismissal of error message"
      }
    }
  }
}
