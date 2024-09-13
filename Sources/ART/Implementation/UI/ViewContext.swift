// Copyright © Rouven Strauss. MIT license.

import CasePaths
import Combine
import SwiftUI

/// Object responsible for the model and the event sending mechanism of a view conforming to the `ModelView` protocol.
///
/// Inspired by `ViewStore` of `The Composable Architecture`.
public class ViewContext<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol
>: ObservableObject {
  @Published
  fileprivate var wrappingModel: WrappingModel<Model>! {
    didSet {
      self.model = self.wrappingModel.model
    }
  }

  @Published
  public private(set) var model: Model!

  public private(set) var coeffects: Coeffects

  public private(set) var handle: (Event) -> Void

  private var cancellable: AnyCancellable?

  private init(
    coeffects: Coeffects,
    handle: @escaping (Event) -> Void
  ) {
    self.coeffects = coeffects
    self.handle = handle
  }

  private init<P: Publisher<WrappingModel<SuperViewModel>, Never>, SuperViewModel: Equatable>(
    _ publisher: P,
    _ modelTransformation: @escaping (WrappingModel<SuperViewModel>) -> WrappingModel<Model>,
    coeffects: Coeffects,
    handle: @escaping (Event) -> Void
  ) {
    self.coeffects = coeffects
    self.handle = handle
    self.cancellable = publisher
      .map(modelTransformation)
      .removeDuplicates()
      .sink { [weak self] in
        guard let self = self else {
          return
        }

        self.wrappingModel = $0
      }
  }

  fileprivate static func instanceWithObserver(
    coeffects: Coeffects,
    handle: @escaping (Event) -> Void
  ) -> (ViewContext<Model, Event, Coeffects>, SimpleValueObserver<WrappingModel<Model>>) {
    let context = ViewContext(coeffects: coeffects, handle: handle)
    let observer = SimpleValueObserver<WrappingModel<Model>>(
      initiallyObservedValue: {
        context.wrappingModel = requiredLet($0, "Must not be nil")
      },
      change: {
        context.wrappingModel = requiredLet($0.current, "Must not be nil")
      }
    )
    return (context, observer)
  }

  fileprivate static func instanceWithObserver(
    coeffects: Coeffects,
    handle: @escaping (Event) -> Void
  ) -> (ViewContext<Model, Event, Coeffects>,
        SimpleValueObserver<Model>) where Model: ViewModel {
    let context = ViewContext(coeffects: coeffects, handle: handle)
    let observer = SimpleValueObserver<Model>(
      initiallyObservedValue: {
        let model = requiredLet($0, "Must not be nil")
        context.wrappingModel = .init(id: model.id, model: model)
      },
      change: {
        let model = requiredLet($0.current, "Must not be nil")
        context.wrappingModel = .init(id: model.id, model: model)
      }
    )
    return (context, observer)
  }
}

private struct WrappingModel<Model: Equatable>: Equatable {
  /// ID whose change indicates the necessity to update the view described by the `model` of this instance.
  let id: UUID

  /// Description of the view appearance.
  let model: Model

  func withModel<OtherModel: Equatable>(
    transformedBy modelTransformation: (Model) -> OtherModel
  ) -> WrappingModel<OtherModel> {
    return WrappingModel<OtherModel>(id: self.id, model: modelTransformation(self.model))
  }
}

public extension ViewContext where Event == Never {
  func context<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, OtherEvent, Coeffects> {
    return ViewContext<OtherModel, OtherEvent, Coeffects>(
      self.$wrappingModel.map { requiredLet($0, "Must not be nil") },
      { $0.withModel(transformedBy: modelTransformation) },
      coeffects: self.coeffects
    ) { _ in }
  }
}

public extension ViewContext {
  func context<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> ViewContext<OtherModel, OtherEvent, Coeffects> {
    return ViewContext<OtherModel, OtherEvent, Coeffects>(
      self.$wrappingModel.map { requiredLet($0, "Must not be nil") },
      { $0.withModel(transformedBy: modelTransformation) },
      coeffects: self.coeffects
    ) {
      self.handle(eventTransformation($0))
    }
  }

  func eventlessContext<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, Never, Coeffects> {
    return ViewContext<OtherModel, Never, Coeffects>(
      self.$wrappingModel.map { requiredLet($0, "Must not be nil") },
      { $0.withModel(transformedBy: modelTransformation) },
      coeffects: self.coeffects
    ) { _ in }
  }

  func contextIgnoringEvents<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, OtherEvent, Coeffects> {
    return ViewContext<OtherModel, OtherEvent, Coeffects>(
      self.$wrappingModel.map { requiredLet($0, "Must not be nil") },
      { $0.withModel(transformedBy: modelTransformation) },
      coeffects: self.coeffects
    ) { _ in }
  }

  func immutableBinding<T>(_ conversionClosure: @escaping (Model) -> T) -> Binding<T> {
    return Binding {
      return conversionClosure(self.model)
    } set: { _ in }
  }

  func binding(handling event: Event) -> Binding<Model> {
    return Binding {
      return self.model
    } set: { _ in
      self.handle(event)
    }
  }

  func binding(_ eventClosure: @escaping (Model) -> Event) -> Binding<Model> {
    return Binding {
      return self.model
    } set: {
      self.handle(eventClosure($0))
    }
  }

  func binding<T>(
    _ conversionClosure: @escaping (Model) -> T,
    _ eventClosure: @escaping (T) -> Event
  ) -> Binding<T> {
    return Binding {
      return conversionClosure(self.model)
    } set: {
      self.handle(eventClosure($0))
    }
  }

  func binding<T>(
    _ conversionClosure: @escaping (Model) -> T?,
    fallbackValue: T,
    _ eventClosure: @escaping (T) -> Event
  ) -> Binding<T> {
    return Binding {
      return conversionClosure(self.model) ?? fallbackValue
    } set: {
      self.handle(eventClosure($0))
    }
  }
}

public class ModelViewObservers {
  fileprivate let observers: [Any]

  fileprivate init(observers: [Any]) {
    self.observers = observers
  }
}

public extension ModelView where Model: ViewModel {
  /// Returns a new view and an `Observer` instance.
  ///
  /// @important The instances encapsulated by `Observer` are held weakly. Therefore, the `Observer`
  /// must be held strongly by the caller until updates to the returned view should be stopped.
  static func instance<ObservedModel: ModelProtocol>(
    observing propertyPath: PropertyPath<ObservedModel.State, Model.State>,
    of model: ObservedModel,
    using coeffects: Coeffects,
    handlingEventsWith eventClosure: @escaping (Event) -> Void
  ) -> (Self, ModelViewObservers) {
    let (context, observer) = ViewContext<Model, Event, Coeffects>.instanceWithObserver(
      coeffects: coeffects,
      handle: eventClosure
    )
    let lensModel: LensModel<Model, ObservedModel, Model.State> =
      .instance(observing: propertyPath, of: model)
    lensModel.add(observer)
    let view = Self(context: context)
    return (view, ModelViewObservers(observers: [lensModel, observer]))
  }

  /// Returns a new view and a lens model which can be used to update the view.
  ///
  /// @important The returned lens model is held weakly.
  static func instance<ObservedModel: ModelProtocol>(
    observing keyPath: KeyPath<ObservedModel.State, Model.State>,
    of model: ObservedModel,
    using coeffects: Coeffects,
    handlingEventsWith eventClosure: @escaping (Event) -> Void
  ) -> (Self, ModelViewObservers) {
    return instance(observing: PropertyPath(keyPath),
                    of: model,
                    using: coeffects,
                    handlingEventsWith: eventClosure)
  }

  /// Returns a new view and a lens model which can be used to update the view.
  ///
  /// @important The returned lens model is held weakly.
  static func instance<ObservedModel: ModelProtocol>(
    observing casePath: AnyCasePath<ObservedModel.State, Model.State>,
    of model: ObservedModel,
    coeffects: Coeffects,
    handlingEventsWith eventClosure: @escaping (Event) -> Void
  ) -> (Self, ModelViewObservers) {
    return instance(observing: PropertyPath(casePath),
                    of: model,
                    using: coeffects,
                    handlingEventsWith: eventClosure)
  }
}
