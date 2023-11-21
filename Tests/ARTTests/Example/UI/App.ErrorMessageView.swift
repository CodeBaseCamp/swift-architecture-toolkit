// Copyright © Rouven Strauss. MIT license.

import ART

import SwiftUI

extension App {
  struct ErrorMessageView: StaticModelView {
    enum Event: Hashable {
      case buttonPress
    }

    struct Model: Equatable {
      var errorDescription: String
    }

    let context: Context<Coeffects>

    var body: some View {
      Text(self.model.errorDescription)

      ARTButton(.buttonPress) {
        Text("OK")
      }
    }
  }
}
