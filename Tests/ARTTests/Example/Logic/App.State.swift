// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation

extension App {
  struct ArbitraryDownloadableResource: Codable, Equatable, Sendable {}

  struct State: StateProtocol {
    var downloadedData: ArbitraryDownloadableResource?

    var errorMessage: String?

    static func instance(from data: Data) throws -> Self {
      return try JSONDecoder().decode(Self.self, from: data)
    }

    func data() throws -> Data {
      return try JSONEncoder().encode(self)
    }
  }
}
