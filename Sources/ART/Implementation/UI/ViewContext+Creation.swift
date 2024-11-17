// Copyright © Rouven Strauss. MIT license.

public extension ViewContext {
  // MARK: ViewContext

  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventClosure: @escaping @autoclosure () -> Event
  ) -> ViewContext<OtherModel, Event, Coeffects> {
    return self.context(modelTransformation) { _ in eventClosure() }
  }

  // MARK: StaticViewContext

  func context<OtherModel: Equatable & Sendable>(
    _ modelClosure: @escaping @autoclosure () -> OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context({ _ in modelClosure() }, { $0 })
  }

  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventClosure: @escaping @autoclosure () -> Event
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context(modelTransformation, { _ in eventClosure() })
  }

  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
    _ modelClosure: @escaping @autoclosure () -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context({ _ in modelClosure() }, eventTransformation)
  }

  func context(
    _ eventClosure: @escaping @autoclosure () -> Event
  ) -> StaticViewContext<Model, Event, Coeffects> {
    return self.context({ $0 }, { _ in eventClosure() })
  }

  func context<OtherEvent: Equatable>(
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<Model, OtherEvent, Coeffects> {
    return self.context({ $0 }, eventTransformation)
  }

  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return StaticViewContext<OtherModel, OtherEvent, Coeffects>(
      model: modelTransformation(requiredLet(self.model, "Model must exist")),
      coeffects: self.coeffects
    ) {
      self.handle(eventTransformation($0))
    }
  }

  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return StaticViewContext<OtherModel, Never, Coeffects>(
      model: modelTransformation(requiredLet(self.model, "Model must exist")),
      coeffects: self.coeffects
    ) { _ in }
  }

  func context<OtherModel: Equatable & Sendable>(
    _ model: OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return StaticViewContext<OtherModel, Never, Coeffects>(
      model: model,
      coeffects: self.coeffects
    ) { _ in }
  }
}
