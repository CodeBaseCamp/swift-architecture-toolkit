// Copyright © Rouven Strauss. MIT license.

import ART

extension TaskBasedApp {
  typealias State = App.State
  typealias Request = App.Request
  typealias SideEffect = App.SideEffect
  typealias Coeffects = App.Coeffects
  typealias AppError = App.AppError
  typealias MainView = App.MainView
  typealias CompositeSideEffect = TaskBasedCompositeSideEffect<SideEffect, AppError>
  typealias LogicModule = ART.TaskBasedLogicModule<
    State,
    Request,
    SideEffectPerformer
  >
  typealias UIEventLogicModule =
    ART.TaskBasedUIEventLogicModule<MainView.Event, State, Request, SideEffectPerformer>
  typealias Model = LogicModule.Model
}
