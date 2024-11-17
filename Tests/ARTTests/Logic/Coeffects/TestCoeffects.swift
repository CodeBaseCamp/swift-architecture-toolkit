// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation

final class TestCoeffects: CoeffectsProtocol {
  let `default`: DefaultCoeffectsProtocol = DefaultCoeffects(dateClosure: { Date.distantPast },
                                                             uuidClosure: { UUID.zero })
}
