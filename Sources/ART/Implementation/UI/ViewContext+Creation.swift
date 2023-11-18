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
    _ event: Event
  ) -> ViewContext<OtherModel, Event, Coeffects> {
    return self.context(modelTransformation) { _ in event }
  }

  // MARK: StaticViewContext

  func staticContext<OtherModel: Equatable>(
    _ model: OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.staticContext({ _ in model }, { $0 })
  }

  func staticContext<OtherModel: Equatable>(
    _ model: OtherModel,
    _ event: Event
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.staticContext({ _ in model }, { _ in event })
  }

  func staticContext<OtherModel: Equatable, OtherEvent: Equatable>(
    _ model: OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.staticContext({ _ in model }, eventTransformation)
  }

  func staticContext<OtherEvent: Equatable>(
    _ event: Event
  ) -> StaticViewContext<Model, OtherEvent, Coeffects> {
    return self.staticContext({ $0 }, { _ in event })
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
