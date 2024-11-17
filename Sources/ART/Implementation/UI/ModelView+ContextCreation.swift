// Copyright © Rouven Strauss. MIT license.

import SwiftUI

public extension ModelView {
  @MainActor
  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> ViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation)
  }

  @MainActor
  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping @autoclosure () -> Event
  ) -> ViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation())
  }

  @MainActor
  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, Never, Coeffects> {
    return self.context.context(modelTransformation)
  }

  @MainActor
  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation)
  }

  @MainActor
  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping @autoclosure () -> Event
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation())
  }

  @MainActor
  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(modelTransformation, { $0 })
  }

  @MainActor
  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
    _ model: OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(model, eventTransformation)
  }

  @MainActor
  func context<OtherModel: Equatable & Sendable>(
    _ model: OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(model)
  }

  @MainActor
  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return self.context.context(modelTransformation)
  }
}
