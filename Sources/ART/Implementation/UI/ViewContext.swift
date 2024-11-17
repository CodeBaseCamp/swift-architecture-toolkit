// Copyright © Rouven Strauss. MIT license.

import Combine
import SwiftUI

/// Object responsible for the model and the event sending mechanism of a view conforming to the `ModelView` protocol.
///
/// Inspired by `ViewStore` of `The Composable Architecture`.
public class ViewContext<
  Model: Equatable & Sendable,
  Event: Hashable & Sendable,
  Coeffects: CoeffectsProtocol
>: ObservableObject, @unchecked Sendable {
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
        Task {
          await MainActor.run {
            context.wrappingModel = .init(id: model.id, model: model)
          }
        }
      }
    )
    return (context, observer)
  }
}

private struct WrappingModel<Model: Equatable & Sendable>: Equatable, Sendable {
  /// ID whose change indicates the necessity to update the view described by the `model` of this instance.
  let id: UUID

  /// Description of the view appearance.
  let model: Model

  func withModel<OtherModel: Equatable & Sendable>(
    transformedBy modelTransformation: (Model) -> OtherModel
  ) -> WrappingModel<OtherModel> {
    return WrappingModel<OtherModel>(id: self.id, model: modelTransformation(self.model))
  }
}

public extension ViewContext where Event == Never {
  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
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
  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
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

  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, Never, Coeffects> {
    return ViewContext<OtherModel, Never, Coeffects>(
      self.$wrappingModel.map { requiredLet($0, "Must not be nil") },
      { $0.withModel(transformedBy: modelTransformation) },
      coeffects: self.coeffects
    ) { _ in }
  }

  func contextIgnoringEvents<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, OtherEvent, Coeffects> {
    return ViewContext<OtherModel, OtherEvent, Coeffects>(
      self.$wrappingModel.map { requiredLet($0, "Must not be nil") },
      { $0.withModel(transformedBy: modelTransformation) },
      coeffects: self.coeffects
    ) { _ in }
  }

  func immutableBinding<T>(_ conversionClosure: @escaping @Sendable (Model) -> T) -> Binding<T> {
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

  func binding(_ eventClosure: @escaping @Sendable (Model) -> Event) -> Binding<Model> {
    return Binding {
      return self.model
    } set: {
      self.handle(eventClosure($0))
    }
  }

  func binding<T>(
    _ conversionClosure: @escaping @Sendable (Model) -> T,
    _ eventClosure: @escaping @Sendable (T) -> Event
  ) -> Binding<T> {
    return Binding {
      return conversionClosure(self.model)
    } set: {
      self.handle(eventClosure($0))
    }
  }

  func binding<T>(
    _ conversionClosure: @escaping @Sendable (Model) -> T,
    _ eventClosure: @escaping @Sendable (T) -> Void
  ) -> Binding<T> {
    return Binding {
      return conversionClosure(self.model)
    } set: {
      eventClosure($0)
    }
  }

  func binding<T: Sendable>(
    _ conversionClosure: @escaping @Sendable (Model) -> T?,
    fallbackValue: T,
    _ eventClosure: @escaping @Sendable (T) -> Event
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

public struct ModelViewCreationResult<T: ModelView>: @unchecked Sendable {
  public let view: T
  public let observers: ModelViewObservers
}

public extension ModelView where Model: ViewModel {
  /// Returns a result comprised of the desired view and a `ModelViewObservers` instance.
  ///
  /// @important The instances encapsulated by the `ModelViewObservers` returned as part of the result are held weakly.
  /// Therefore, the `ModelViewObservers` must be held strongly by the caller until updates to the returned view should
  /// be stopped.
  @MainActor
  static func instance<ObservedModel: ModelProtocol>(
    observing propertyPath: PropertyPath<ObservedModel.State, Model.State>,
    of model: ObservedModel,
    using coeffects: Coeffects,
    handlingEventsWith eventClosure: @escaping (Event) -> Void
  ) async -> ModelViewCreationResult<Self> {
    let (context, observer) = ViewContext<Model, Event, Coeffects>.instanceWithObserver(
      coeffects: coeffects,
      handle: eventClosure
    )
    let lensModel: LensModel<Model, ObservedModel, Model.State> =
      .instance(observing: propertyPath, of: model)
    await lensModel.add(observer)
    let view = Self(context: context)
    return ModelViewCreationResult(
      view: view,
      observers: ModelViewObservers(observers: [lensModel, observer])
    )
  }

  /// Returns a result comprised of the desired view and a `ModelViewObservers` instance.
  ///
  /// @important The instances encapsulated by the `ModelViewObservers` returned as part of the result are held weakly.
  /// Therefore, the `ModelViewObservers` must be held strongly by the caller until updates to the returned view should
  /// be stopped.
  @MainActor
  static func instance<ObservedModel: ModelProtocol>(
    observing keyPath: KeyPath<ObservedModel.State, Model.State>,
    of model: ObservedModel,
    using coeffects: Coeffects,
    handlingEventsWith eventClosure: @escaping (Event) -> Void
  ) async -> ModelViewCreationResult<Self> {
    return await instance(
      observing: PropertyPath(keyPath),
      of: model,
      using: coeffects,
      handlingEventsWith: eventClosure
    )
  }
}
