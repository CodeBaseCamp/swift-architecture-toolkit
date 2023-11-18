// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol implemented by objects serving as models of corresponding views.
public protocol ViewModel: Equatable {
  /// State from which this instance is created.
  associatedtype State: Equatable

  /// ID whose change indicates the necessity to update the view described by this instance as well
  /// as all its subviews.
  ///
  /// - important Since a value change of this property causes the system to re-render not only the
  ///             view described by this instance but also all its subviews, the property value
  ///             should only be changed if such re-rendering is desired. In the case of
  ///             `SwiftUI.View` instances, this means that a change should be performed if and only
  ///             if the views rely on additional values which are not directly provided via this
  ///             instance or any model derived from it.
  var id: UUID { get }

  /// Returns a new instance of this type from the given `state`.
  static func makeInstance(from state: State?) -> Self

  /// Returns a change of this type for the given `change` and `previousModel` if there is a change,
  /// `nil` otherwise.
  static func makeChange(from change: Change<State?>, previousModel: Self) -> Change<Self>?
}

/// Extension adding a convenience implementation of the `makeChange` method of ``ViewModel``.
public extension ViewModel {
  static func makeChange(from change: Change<State?>, previousModel: Self) -> Change<Self>? {
    return Change.safeInstance(previousModel, makeInstance(from: change.current))
  }
}

public extension LensModel {
  /// Returns a model of `ViewModel` changes by observing the given `propertyPath` of the given
  /// `model`. The given `changeClosure` is used to achieve the conversion of type
  /// `ObservedProperty` to type `ViewModel`.
  static func instance<Model: ViewModel>(
    observing propertyPath: PropertyPath<ObservedModel.State, ObservedProperty>,
    of model: ObservedModel
  ) -> LensModel<
    Model,
    ObservedModel,
    ObservedProperty
  > where ObservedProperty == Model.State {
    return LensModel<Model, ObservedModel, ObservedProperty>.instance(
      observing: propertyPath,
      of: model,
      convertingValueUsing: {
        return Model.makeInstance(from: $0)
      },
      andChangeUsing: { previousViewModel, change in
        return Model.makeChange(from: change, previousModel: previousViewModel)
      }
    )
  }
}
