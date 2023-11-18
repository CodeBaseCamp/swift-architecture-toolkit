// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation

class TestCoeffects: CoeffectsProtocol {
  let `default`: DefaultCoeffectsProtocol = DefaultCoeffects(dateClosure: { Date.distantPast },
                                                             uuidClosure: { UUID.zero })
}
