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
  NonOptionalContent0: View,
  NonOptionalContent1: View
>(
  _ context: ViewContext<Model?, Event, Coeffects>,
  @ViewBuilder then nonOptionalContent0: @escaping (
    ViewContext<Model, Event, Coeffects>
  ) -> NonOptionalContent0,
  @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
) -> some View {
  return NonStaticConditionalView(context, then: nonOptionalContent0, else: nonOptionalContent1)
}

public func ConditionalView<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  NonOptionalContent: View
>(
  _ context: ViewContext<Model?, Event, Coeffects>,
  @ViewBuilder then nonOptionalContent: @escaping (
    ViewContext<Model, Event, Coeffects>
  ) -> NonOptionalContent
) -> some View {
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
  NonOptionalContent0: View,
  NonOptionalContent1: View
>(
  _ context: StaticViewContext<Model?, Event, Coeffects>,
  @ViewBuilder then nonOptionalContent0: @escaping (
    StaticViewContext<Model, Event, Coeffects>
  ) -> NonOptionalContent0,
  @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
) -> some View {
  return StaticConditionalView(context, then: nonOptionalContent0, else: nonOptionalContent1)
}

public func ConditionalView<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  NonOptionalContent: View
>(
  _ context: StaticViewContext<Model?, Event, Coeffects>,
  @ViewBuilder then nonOptionalContent: @escaping (
    StaticViewContext<Model, Event, Coeffects>
  ) -> NonOptionalContent
) -> some View {
  return StaticConditionalView(context, then: nonOptionalContent)
}

extension ModelView {
  public func IfLet<
    OtherModel: Equatable,
    OtherEvent: Hashable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    _ eventTransformation: @escaping (OtherEvent) -> Event,
    @ViewBuilder then nonOptionalContent0:
      @escaping (ViewContext<OtherModel, OtherEvent, Coeffects>) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return NonStaticConditionalView(
      self.context(modelTransformation, eventTransformation),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent0:
    @escaping (ViewContext<OtherModel, Event, Coeffects>) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return NonStaticConditionalView(
      self.context(modelTransformation, { $0 }),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent0: @escaping () -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return NonStaticConditionalView(
      self.context(modelTransformation),
      then: { _ in nonOptionalContent0() },
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent0:
    @escaping (ViewContext<OtherModel, Never, Coeffects>) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return NonStaticConditionalView(
      self.context(modelTransformation),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    OtherEvent: Hashable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    _ eventTransformation: @escaping (OtherEvent) -> Event,
    @ViewBuilder then nonOptionalContent:
      @escaping (ViewContext<OtherModel, OtherEvent, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return NonStaticConditionalView(self.context(modelTransformation, eventTransformation), then: nonOptionalContent)
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    _ eventTransformation: @escaping @autoclosure () -> Event,
    @ViewBuilder then nonOptionalContent:
    @escaping (ViewContext<OtherModel, Event, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return NonStaticConditionalView(self.context(modelTransformation, eventTransformation()), then: nonOptionalContent)
  }

  public func IfLet<NonOptionalContent: View>(
    _ modelTransformation: @escaping (Model) -> Bool,
    @ViewBuilder then nonOptionalContent: @escaping () -> NonOptionalContent
  ) -> some View {
    return NonStaticConditionalView(
      self.context(modelTransformation),
      then: {
        if $0.model {
          nonOptionalContent()
        } else {
          EmptyView()
        }
      }
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent: @escaping () -> NonOptionalContent
  ) -> some View {
    return NonStaticConditionalView(self.context(modelTransformation), then: { _ in nonOptionalContent() })
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent:
      @escaping (ViewContext<OtherModel, Never, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return NonStaticConditionalView(
      self.context(modelTransformation),
      then: nonOptionalContent
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    OtherEvent: Hashable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    _ eventTransformation: @escaping (OtherEvent) -> Event,
    @ViewBuilder then nonOptionalContent0: @escaping (
      StaticViewContext<OtherModel, OtherEvent, Coeffects>
    ) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return StaticConditionalView(
      self.context(modelTransformation, eventTransformation),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent0: @escaping (
      StaticViewContext<OtherModel, Event, Coeffects>
    ) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return StaticConditionalView(
      self.context(modelTransformation),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent0: @escaping (
      StaticViewContext<OtherModel, Never, Coeffects>
    ) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return StaticConditionalView(
      self.context(modelTransformation),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    OtherEvent: Hashable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    _ eventTransformation: @escaping (OtherEvent) -> Event,
    @ViewBuilder then nonOptionalContent:
      @escaping (StaticViewContext<OtherModel, OtherEvent, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return StaticConditionalView(self.context(modelTransformation, eventTransformation), then: nonOptionalContent)
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent:
    @escaping (StaticViewContext<OtherModel, Event, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return StaticConditionalView(self.context(modelTransformation), then: nonOptionalContent)
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent:
    @escaping (StaticViewContext<OtherModel, Never, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return StaticConditionalView(self.context(modelTransformation), then: nonOptionalContent)
  }
}

extension StaticModelView {
  public func IfLet<
    OtherModel: Equatable,
    OtherEvent: Hashable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    _ eventTransformation: @escaping (OtherEvent) -> Event,
    @ViewBuilder then nonOptionalContent0:
    @escaping (StaticViewContext<OtherModel, OtherEvent, Coeffects>) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return StaticConditionalView(
      self.context(modelTransformation, eventTransformation),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent0:
    @escaping (StaticViewContext<OtherModel, Event, Coeffects>) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return StaticConditionalView(
      self.context(modelTransformation),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent0: @escaping () -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return StaticConditionalView(
      self.context(modelTransformation),
      then: { _ in nonOptionalContent0() },
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent0: View,
    NonOptionalContent1: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent0:
    @escaping (StaticViewContext<OtherModel, Never, Coeffects>) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) -> some View {
    return StaticConditionalView(
      self.context(modelTransformation),
      then: nonOptionalContent0,
      else: nonOptionalContent1
    )
  }

  public func IfLet<
    OtherModel: Equatable,
    OtherEvent: Hashable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    _ eventTransformation: @escaping (OtherEvent) -> Event,
    @ViewBuilder then nonOptionalContent:
    @escaping (StaticViewContext<OtherModel, OtherEvent, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return StaticConditionalView(self.context(modelTransformation, eventTransformation), then: nonOptionalContent)
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent:
    @escaping (StaticViewContext<OtherModel, Event, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return StaticConditionalView(self.context(modelTransformation), then: nonOptionalContent)
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent: @escaping () -> NonOptionalContent
  ) -> some View {
    return StaticConditionalView(self.context(modelTransformation), then: { _ in nonOptionalContent() })
  }

  public func IfLet<
    OtherModel: Equatable,
    NonOptionalContent: View
  >(
    _ modelTransformation: @escaping (Model) -> OtherModel?,
    @ViewBuilder then nonOptionalContent:
    @escaping (StaticViewContext<OtherModel, Never, Coeffects>) -> NonOptionalContent
  ) -> some View {
    return StaticConditionalView(
      self.context(modelTransformation),
      then: nonOptionalContent
    )
  }
}
