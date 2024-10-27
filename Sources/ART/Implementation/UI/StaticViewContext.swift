// Copyright © Rouven Strauss. MIT license.

import Combine

/// Object responsible for the model and the event sending mechanism of a view conforming to the
/// `StaticModelView` protocol.
///
/// Inspired by `ViewStore` of `The Composable Architecture`.
public struct StaticViewContext<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol
> {
  public let model: Model

  public let coeffects: Coeffects

  public let handle: (Event) -> Void

  public init(
    model: Model,
    coeffects: Coeffects,
    handle: @escaping (Event) -> Void
  ) {
    self.model = model
    self.coeffects = coeffects
    self.handle = handle
  }
}

public extension StaticViewContext {
  func context<OtherModel: Equatable, OtherEvent: Equatable>(
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

  func context<OtherModel: Equatable, OtherEvent: Equatable>(
    _ model: OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return StaticViewContext<OtherModel, OtherEvent, Coeffects>(
      model: model,
      coeffects: self.coeffects
    ) {
      self.handle(eventTransformation($0))
    }
  }

  func context<OtherModel: Equatable>(
    _ model: OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return StaticViewContext<OtherModel, Event, Coeffects>(
      model: model,
      coeffects: self.coeffects
    ) {
      self.handle($0)
    }
  }

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return StaticViewContext<OtherModel, Never, Coeffects>(
      model: modelTransformation(requiredLet(self.model, "Model must exist")),
      coeffects: self.coeffects
    ) { _ in }
  }
}

public extension StaticViewContext where Event == Never {
  func context<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return StaticViewContext<OtherModel, OtherEvent, Coeffects>(
      model: modelTransformation(requiredLet(self.model, "Model must exist")),
      coeffects: self.coeffects
    ) { _ in }
  }
}
