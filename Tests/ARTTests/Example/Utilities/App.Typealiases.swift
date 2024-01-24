// Copyright © Rouven Strauss. MIT license.

import ART

extension App {
  typealias CompositeSideEffect = ART.CompositeSideEffect<SideEffect, AppError>
  typealias LogicModule = ART.LogicModule<
    State,
    Request,
    SideEffectPerformer
  >
  typealias UIEventLogicModule =
    ART.UIEventLogicModule<MainView.Event, State, Request, SideEffectPerformer>
  typealias Model = LogicModule.Model
}
