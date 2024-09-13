// Copyright © Rouven Strauss. MIT license.

public extension ViewContext {
  // MARK: ViewContext

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, Event, Coeffects> {
    return self.context(modelTransformation) { $0 }
  }

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventClosure: @escaping @autoclosure () -> Event
  ) -> ViewContext<OtherModel, Event, Coeffects> {
    return self.context(modelTransformation) { _ in eventClosure() }
  }

  // MARK: StaticViewContext

  func staticContext<OtherModel: Equatable>(
    _ modelClosure: @escaping @autoclosure () -> OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.staticContext({ _ in modelClosure() }, { $0 })
  }

  func staticContext<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventClosure: @escaping @autoclosure () -> Event
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.staticContext(modelTransformation, { _ in eventClosure() })
  }

  func staticContext<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelClosure: @escaping @autoclosure () -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.staticContext({ _ in modelClosure() }, eventTransformation)
  }

  func staticContext(
    _ eventClosure: @escaping @autoclosure () -> Event
  ) -> StaticViewContext<Model, Event, Coeffects> {
    return self.staticContext({ $0 }, { _ in eventClosure() })
  }

  func staticContext<OtherEvent: Equatable>(
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<Model, OtherEvent, Coeffects> {
    return self.staticContext({ $0 }, eventTransformation)
  }

  func staticContext<OtherModel: Equatable, OtherEvent: Equatable>(
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

  func staticEventlessContext<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return StaticViewContext<OtherModel, Never, Coeffects>(
      model: modelTransformation(requiredLet(self.model, "Model must exist")),
      coeffects: self.coeffects
    ) { _ in }
  }

  func staticEventlessContext<OtherModel: Equatable>(
    _ model: OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return StaticViewContext<OtherModel, Never, Coeffects>(
      model: model,
      coeffects: self.coeffects
    ) { _ in }
  }
}
