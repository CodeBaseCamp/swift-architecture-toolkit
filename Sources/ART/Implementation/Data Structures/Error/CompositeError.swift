// Copyright © Rouven Strauss. MIT license.

public enum CompositeError<SimpleError: ErrorProtocol>: ErrorProtocol {
  case simpleError(SimpleError)

  indirect case compositeError(Self, underlyingErrors: NonEmptyList<Self>)

  public static func instanceWith(_ error: SimpleError) -> Self {
    .simpleError(error)
  }

  public static func error(_ error: SimpleError?,
                           withUnderlyingError underlyingError: Self) -> Self {
    guard let error = error else {
      return underlyingError
    }

    return .compositeError(.simpleError(error), underlyingErrors: .single(underlyingError))
  }

  public var rootError: SimpleError {
    switch self {
    case let .simpleError(error):
      return error
    case let .compositeError(_, underlyingErrors):
      return underlyingErrors.head.rootError
    }
  }

  public func contains(_ searchedError: SimpleError) -> Bool {
    switch self {
    case let .simpleError(error):
      return error == searchedError
    case let .compositeError(error, underlyingErrors):
      return error.contains(searchedError) ||
        underlyingErrors.contains(where: { $0.contains(searchedError) })
    }
  }

  public func map<Error>(_ closure: (SimpleError) -> Error) -> CompositeError<Error> {
    switch self {
    case let .simpleError(error):
      return .simpleError(closure(error))
    case let .compositeError(compositeError, underlyingErrors):
      return .compositeError(
        compositeError.map(closure),
        underlyingErrors: underlyingErrors.map { $0.map(closure) }
      )
    }
  }
}

extension CompositeError: HumanReadable {
  public var humanReadableDescription: String {
    return self.humanReadableDescription("")
  }

  private func humanReadableDescription(_ inset: String) -> String {
    let nextInset = inset + "  "

    switch self {
    case let .simpleError(error):
      return "\(inset)- root error: \(error.humanReadableDescription)"
    case let .compositeError(error, underlyingErrors):
      return """
      \(inset)- error: \(error.humanReadableDescription)
      \(inset)  - underlying errors:
      \(underlyingErrors.asArray.map {
        """
        \(inset)    - \($0.humanReadableDescription(nextInset))
        """
      })
      """
    }
  }
}
