// Copyright © Rouven Strauss. MIT license.

import ART

import SwiftUI

extension App {
  struct MainView: ModelView {
    enum Event: Hashable {
      case downloadButtonPress
      case errorMessageView(ErrorMessageView.Event)
    }

    typealias Model = MainViewModel

    let context: Context<Coeffects>

    var body: some View {
      switch self.model.dataAvailabilityState {
      case .noData:
        Button("Download data") {
          self.handle(.downloadButtonPress)
        }
      case .availableData:
        Text("Resource downloaded")
      case let .downloadError(errorDescription):
        ErrorMessageView(
          self.context(
            { $0.errorMessageViewModel(errorDescription) },
            Event.errorMessageView
          )
        )
      }
    }
  }
}

private extension App.MainView.Model {
  func errorMessageViewModel(_ errorDescription: String) -> App.ErrorMessageView.Model {
    return .init(errorDescription: "Downloading failed: \(errorDescription)")
  }
}
