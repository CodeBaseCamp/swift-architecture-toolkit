// Copyright © Rouven Strauss. MIT license.

import SwiftUI

// MARK: - NonStaticConditionalView

/// View allowing for the conditional display of one of two views of type `NonOptionalContent0` and
/// `NonOptionalContent1`, respectively.
///
/// Inspired by `IfLetStore` of `The Composable Architecture`.
public func ConditionalView<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  NonOptionalContent0,
  NonOptionalContent1
>(
  _ context: ViewContext<Model?, Event, Coeffects>,
  @ViewBuilder then nonOptionalContent0: @escaping (
    ViewContext<Model, Event, Coeffects>
  ) -> NonOptionalContent0,
  @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
) -> NonStaticConditionalView<
  Model,
  Event,
  Coeffects,
  _ConditionalContent<NonOptionalContent0, NonOptionalContent1>
> {
  return NonStaticConditionalView(context, then: nonOptionalContent0, else: nonOptionalContent1)
}

public func ConditionalView<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  NonOptionalContent
>(
  _ context: ViewContext<Model?, Event, Coeffects>,
  @ViewBuilder then nonOptionalContent: @escaping (
    ViewContext<Model, Event, Coeffects>
  ) -> NonOptionalContent
) -> NonStaticConditionalView<
  Model,
  Event,
  Coeffects,
  NonOptionalContent?
> {
  return NonStaticConditionalView(context, then: nonOptionalContent)
}

// MARK: - StaticConditionalView

/// View allowing for the conditional display of one of two views of type `NonOptionalContent0` and
/// `NonOptionalContent1`, respectively.
///
/// Inspired by `IfLetStore` of `The Composable Architecture`.
public func ConditionalView<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  NonOptionalContent0,
  NonOptionalContent1
>(
  _ context: StaticViewContext<Model?, Event, Coeffects>,
  @ViewBuilder then nonOptionalContent0: @escaping (
    StaticViewContext<Model, Event, Coeffects>
  ) -> NonOptionalContent0,
  @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
) -> StaticConditionalView<
  Model,
  Event,
  Coeffects,
  _ConditionalContent<NonOptionalContent0, NonOptionalContent1>
> {
  return StaticConditionalView(context, then: nonOptionalContent0, else: nonOptionalContent1)
}

public func ConditionalView<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  NonOptionalContent
>(
  _ context: StaticViewContext<Model?, Event, Coeffects>,
  @ViewBuilder then nonOptionalContent: @escaping (
    StaticViewContext<Model, Event, Coeffects>
  ) -> NonOptionalContent
) -> StaticConditionalView<
  Model,
  Event,
  Coeffects,
  NonOptionalContent?
> {
  return StaticConditionalView(context, then: nonOptionalContent)
}
