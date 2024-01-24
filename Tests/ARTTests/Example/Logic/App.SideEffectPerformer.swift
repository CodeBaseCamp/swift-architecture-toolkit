// Copyright © Rouven Strauss. MIT license.

import ART

extension App {
  actor SideEffectPerformer: SideEffectPerformerProtocol {
    typealias SideEffect = App.SideEffect
    typealias SideEffectError = App.AppError
    typealias Coeffects = App.Coeffects
    typealias Result<Error: ErrorProtocol> =
      CompletionIndication<CompositeError<SideEffectExecutionError<Error>>>
    typealias SideEffectClosure = (SideEffect, Coeffects) async -> Result<SideEffectError>

    func task(
      performing sideEffect: CompositeSideEffect,
      using coeffects: Coeffects
    ) async -> Task<Result<SideEffectError>, Error> {
      return await self.sideEffectPerformer.task(performing: sideEffect, using: coeffects)
    }

    func perform(
      _ sideEffect: CompositeSideEffect,
      using coeffects: Coeffects
    ) async -> Result<SideEffectError> {
      return await self.sideEffectPerformer.perform(sideEffect, using: coeffects)
    }

    private let sideEffectPerformer: ART.SideEffectPerformer<
      SideEffect,
      SideEffectError,
      Coeffects
    >

    init(sideEffectClosure: @escaping SideEffectClosure) {
      self.sideEffectPerformer = ART.SideEffectPerformer(
        sideEffectClosure: sideEffectClosure
      )
    }
  }
}
