// Copyright © Rouven Strauss. MIT license.

import ART

extension App {
  final class Coeffects: CoeffectsProtocol {
    let `default`: DefaultCoeffectsProtocol

    init() {
      self.default = DefaultCoeffects()
    }
  }
}
