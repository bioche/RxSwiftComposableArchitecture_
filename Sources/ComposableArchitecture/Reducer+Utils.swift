import Foundation

extension Reducer {
  /// Creates a reducer that will transform the specified action (`case`) into another action (`embed`).
  ///
  /// Typically, this will allow for redirection of actions from parent into a child
  ///
  ///     parentReducer
  ///       .resending(ParentAction.fooClient, to: { ParentAction.child1(.fooClient($0)) })
  ///       .resending(ParentAction.fooClient, to: { ParentAction.child2(.fooClient($0)) })
  ///
  ///
  /// - Parameters:
  ///   - case: The original action
  ///   - to: The destination action
  /// - Returns: The modified reducer
  public func resending<Value>(
    _ case: @escaping (Value) -> Action,
    to embed: @escaping (Value) -> Action
  ) -> Self {
    .combine(
      self,
      .init { state, action, _ in
        if let value = CasePath.case(`case`).extract(from: action) {
          return Effect(value: embed(value))
        } else {
          return .none
        }
      }
    )
  }
  
  /// Combines the current reducer with another one according to environment function
  /// Allows for dynamic combining.
  /// For example, we can condition the application of a reducer to a specific configuration
  ///
  ///      let fullReducer = partialReducer
  ///       .combined { $0.includeAnalytics ? analyticsReducer : .empty }
  ///
  /// - Parameter fromEnvironment: A function which may return a reducer to combine with
  /// - Returns: A single reducer.
  public func combined(with fromEnvironment: @escaping (Environment) -> Reducer) -> Reducer {
    Self { value, action, environment in
      self.combined(with: fromEnvironment(environment))(&value, action, environment)
    }
  }
}


