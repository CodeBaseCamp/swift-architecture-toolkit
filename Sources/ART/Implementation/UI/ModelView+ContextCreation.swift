// Copyright © Rouven Strauss. MIT license.

import SwiftUI

public extension ModelView {
  func context<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> ViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation)
  }

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping @autoclosure () -> Event
  ) -> ViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation())
  }

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, Never, Coeffects> {
    return self.context.context(modelTransformation)
  }

  func context<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation)
  }

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping @autoclosure () -> Event
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation())
  }

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(modelTransformation, { $0 })
  }

  func context<OtherModel: Equatable, OtherEvent: Equatable>(
    _ model: OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(model, eventTransformation)
  }

  func context<OtherModel: Equatable>(
    _ model: OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(model)
  }

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return self.context.context(modelTransformation)
  }
}
