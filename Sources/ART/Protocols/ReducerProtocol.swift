// Copyright © Rouven Strauss. MIT license.

/// Protocol to be implemented by objects updating a `State` instance according to a  `Request` 
/// instance determining the update. The state update does not have any side  effects but can 
/// involve coeffects retrieved from a `Coeffects` instance.
///
/// - note For more information about state, requests, or coeffects, refer to the corresponding 
///        protocols.
public protocol ReducerProtocol {
  associatedtype State
  associatedtype Request: RequestProtocol
  associatedtype Coeffects

  /// Reduces the given `State` instance and the given `Request` instance to a new `State` value, 
  /// in-place. The given `Coeffects` instance can be used for retrieval of coeffects.
  var reduce: (inout State, [Request], Coeffects) -> Void { get }
}
