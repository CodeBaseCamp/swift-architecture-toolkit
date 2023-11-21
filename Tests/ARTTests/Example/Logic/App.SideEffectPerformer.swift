// Copyright © Rouven Strauss. MIT license.

import ART

extension App {
  class SideEffectPerformer: SideEffectPerformerProtocol {
    typealias SideEffect = App.SideEffect
    typealias Error = App.Error
    typealias Coeffects = App.Coeffects
    typealias BackgroundDispatchQueueID = App.BackgroundDispatchQueueID

    func perform(
      _ sideEffect: CompositeSideEffect,
      using coeffects: Coeffects,
      completion: @escaping CompletionClosure
    ) {
      self.sideEffectPerformer.perform(sideEffect, using: coeffects, completion: completion)
    }

    private let sideEffectPerformer: ART.SideEffectPerformer<
      SideEffect,
      Error,
      Coeffects,
      BackgroundDispatchQueueID
    >

    init(sideEffectClosure: @escaping SideEffectPerformer.SideEffectClosure) {
      self.sideEffectPerformer = ART.SideEffectPerformer(
        dispatchQueues: [
          .mainThread: .main,
          .backgroundThread: .init(label: "background")
        ],
        sideEffectClosure: sideEffectClosure
      )
    }
  }
}
