// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation

extension App {
  struct MainViewModel: ViewModel {
    var id: UUID

    enum DataAvailabilityState: Equatable {
      case noData
      case availableData
      case downloadError(String)
    }

    let dataAvailabilityState: DataAvailabilityState

    static func makeInstance(from state: App.State?) -> Self {
      let dataAvailabilityState: DataAvailabilityState
      if state?.downloadedData != nil {
        dataAvailabilityState = .availableData
      } else if let errorMessage = state?.errorMessage {
        dataAvailabilityState = .downloadError(errorMessage)
      } else {
        dataAvailabilityState = .noData
      }

      return .init(id: UUID(), dataAvailabilityState: dataAvailabilityState)
    }
  }
}
