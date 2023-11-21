// Copyright © Rouven Strauss. MIT license.

import ART

extension App {
  class Coeffects: CoeffectsProtocol {
    private(set) var `default`: DefaultCoeffectsProtocol

    init() {
      self.default = DefaultCoeffects()
    }
  }
}
